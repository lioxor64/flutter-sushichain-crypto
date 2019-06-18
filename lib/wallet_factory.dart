library sushichain;

import 'dart:convert';
import "dart:math";
import "dart:typed_data";

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import "package:dartz/dartz.dart";
import "package:pointycastle/api.dart";
import "package:pointycastle/ecc/curves/secp256k1.dart";
import "package:pointycastle/export.dart";
import "package:pointycastle/key_generators/api.dart";
import "package:pointycastle/key_generators/ec_key_generator.dart";
import "package:pointycastle/pointycastle.dart";
import "package:pointycastle/random/fortuna_random.dart";
import 'package:sushichain/full_wallet.dart';
import 'package:sushichain/wallet_error.dart';

import 'basic_wallet.dart';
import 'encrypted_wallet.dart';
import 'keypair.dart';
import 'network.dart';

// https://iryanbell.com/2019-06-01-cryptographic-darts/

class WalletFactory {
  Either<WalletError, KeyPair> generateKeyPair() {
    try {
      var keyParams = ECKeyGeneratorParameters(ECCurve_secp256k1());

      var random = FortunaRandom();
      random.seed(KeyParameter(_seed()));

      var generator = ECKeyGenerator();
      generator.init(ParametersWithRandom(keyParams, random));

      AsymmetricKeyPair<PublicKey, PrivateKey> keyPair =
          generator.generateKeyPair();

      KeyPair kp = KeyPair(keyPair);

      if ((kp.hexPublicKey.length != 130) || kp.hexPrivateKey.length != 64) {
        return generateKeyPair();
      }

      return right(kp);
    } catch (e) {
      return left(WalletError(e.toString()));
    }
  }

  Either<WalletError, BasicWallet> generateNewWallet(Network network) {
    try {
      String networkPrefix = NetworkUtil.networkToString(network);

      Either<WalletError, KeyPair> keyPair = generateKeyPair();

      return keyPair.flatMap((kp) => _toBasicWallet(networkPrefix, kp));
    } catch (e) {
      return left(WalletError(e.toString()));
    }
  }

  Either<WalletError, BasicWallet> _toBasicWallet(
      String networkPrefix, KeyPair keyPair) {
    String hexPublicKey = keyPair.hexPublicKey;
    String hexPrivateKey = keyPair.hexPrivateKey;

    Either<WalletError, String> maybeWif =
        generateWif(hexPrivateKey, networkPrefix);
    Either<WalletError, String> maybeAddress =
        generateAddress(hexPublicKey, networkPrefix);

    return Either.map2(maybeWif, maybeAddress,
        (wif, address) => BasicWallet(hexPublicKey, wif, address));
  }

  Either<WalletError, String> generateWif(
      String hexPrivateKey, String networkPrefix) {
    try {
      String networkKey = networkPrefix + hexPrivateKey;
      String hashedKey = _toSha256(_toSha256(networkKey));
      String checkSum = hashedKey.substring(0, 6);
      return right(_toBase64(networkKey + checkSum));
    } catch (e) {
      return left(WalletError(e.toString()));
    }
  }

  Either<WalletError, String> generateAddress(
      String hexPublicKey, String networkPrefix) {
    try {
      String hashedAddress = _toRipeMd160(_toSha256(hexPublicKey));
      String networkAddress = networkPrefix + hashedAddress;
      String hashedAddressAgain = _toSha256(_toSha256(networkAddress));
      String checksum = hashedAddressAgain.substring(0, 6);
      return right(_toBase64(networkAddress + checksum));
    } catch (e) {
      return left(WalletError(e.toString()));
    }
  }

  Either<WalletError, BasicWallet> getWalletFromWif(String wif) {
    try {
      Either<WalletError, Tuple2<String, String>> maybeNetworkAndPrivateKey =
          getPrivateKeyAndNetworkFromWif(wif);
      if (maybeNetworkAndPrivateKey.isRight()) {
        Tuple2<String, String> privateKeyNetwork =
            maybeNetworkAndPrivateKey.toIterable().first;
        String privateKey = privateKeyNetwork.value1;
        String networkPrefix = privateKeyNetwork.value2;
        Either<WalletError, String> maybePublicKey =
            getPublicKeyFromPrivateKey(privateKey);
        if (maybePublicKey.isRight()) {
          String hexPublicKey = maybePublicKey.toIterable().first;
          Either<WalletError, String> maybeAddress =
              generateAddress(hexPublicKey, networkPrefix);
          if (maybeAddress.isRight()) {
            String address = maybeAddress.toIterable().first;
            return right(BasicWallet(hexPublicKey, wif, address));
          } else {
            throw Exception(maybeAddress.swap().toIterable().first.message);
          }
        } else {
          throw Exception(maybePublicKey.swap().toIterable().first.message);
        }
      } else {
        throw Exception(
            maybeNetworkAndPrivateKey.swap().toIterable().first.message);
      }
    } catch (e) {
      return left(WalletError(e.toString()));
    }
  }

  Either<WalletError, FullWallet> getFullWalletFromWif(String wif) {
    try {
      Either<WalletError, Tuple2<String, String>> maybeNetworkAndPrivateKey =
          getPrivateKeyAndNetworkFromWif(wif);
      if (maybeNetworkAndPrivateKey.isRight()) {
        Tuple2<String, String> privateKeyNetwork =
            maybeNetworkAndPrivateKey.toIterable().first;
        String privateKey = privateKeyNetwork.value1;
        String networkPrefix = privateKeyNetwork.value2;
        Either<WalletError, String> maybePublicKey =
            getPublicKeyFromPrivateKey(privateKey);
        if (maybePublicKey.isRight()) {
          String hexPublicKey = maybePublicKey.toIterable().first;
          Either<WalletError, String> maybeAddress =
              generateAddress(hexPublicKey, networkPrefix);
          if (maybeAddress.isRight()) {
            String address = maybeAddress.toIterable().first;
            return right(FullWallet(
                hexPublicKey, privateKey, wif, address, networkPrefix));
          } else {
            throw Exception(maybeAddress.swap().toIterable().first.message);
          }
        } else {
          throw Exception(maybePublicKey.swap().toIterable().first.message);
        }
      } else {
        throw Exception(
            maybeNetworkAndPrivateKey.swap().toIterable().first.message);
      }
    } catch (e) {
      return left(WalletError(e.toString()));
    }
  }

  Either<WalletError, EncryptedWallet> encryptWallet(
      BasicWallet wallet, String password) {
    try {
      String walletJson = json.encode(wallet);

      var key = _toSha256I(password);
      var iv = _toSha256I(walletJson).sublist(0, 16);
      CipherParameters params = new PaddedBlockCipherParameters(
          new ParametersWithIV(new KeyParameter(key), iv), null);

      BlockCipher encryptionCipher = new PaddedBlockCipher("AES/CBC/PKCS7");
      encryptionCipher.init(true, params);
      Uint8List encrypted = encryptionCipher.process(utf8.encode(walletJson));
      String cipherText = hex.encode(encrypted);

      return right(EncryptedWallet(
          "flutter", cipherText, wallet.address, hex.encode(iv)));
    } catch (e) {
      return left(WalletError(e.toString()));
    }
  }

  Either<WalletError, BasicWallet> decryptWallet(
      EncryptedWallet wallet, String password) {
    try {
      var key = _toSha256I(password);
      var iv = hex.decode(wallet.salt);
      var message = hex.decode(wallet.cipherText);

      CipherParameters params = new PaddedBlockCipherParameters(
          new ParametersWithIV(new KeyParameter(key), iv), null);

      BlockCipher decryptionCipher = new PaddedBlockCipher("AES/CBC/PKCS7");
      decryptionCipher.init(false, params);
      String decrypted = utf8.decode(decryptionCipher.process(message));
      Map map = jsonDecode(decrypted);
      BasicWallet basicWallet = BasicWallet.fromJson(map);
      return right(basicWallet);
    } catch (e) {
      return left(WalletError(e.toString()));
    }
  }

  Either<WalletError, Tuple2<String, String>> getPrivateKeyAndNetworkFromWif(
      String wif) {
    try {
      String decodedWif = _fromBase64(wif);
      String networkPrefix = decodedWif.substring(0, 2);
      String hexPrivateKey = decodedWif.substring(2, decodedWif.length - 6);
      return right(Tuple2(hexPrivateKey, networkPrefix));
    } catch (e) {
      return left(WalletError(e.toString()));
    }
  }

  Either<WalletError, String> getPublicKeyFromPrivateKey(String hexPrivateKey) {
    try {
      ECKeyGeneratorParameters keyParams =
          ECKeyGeneratorParameters(ECCurve_secp256k1());
      BigInt privateKey = BigInt.parse(hexPrivateKey, radix: 16);
      ECPoint point = keyParams.domainParameters.G * privateKey;
      Uint8List encodedPoint = point.getEncoded(false);
      return right(hex.encode(encodedPoint));
    } catch (e) {
      return left(WalletError(e.toString()));
    }
  }

  String _toSha256(String message) {
    List<int> bytes = utf8.encode(message);
    return sha256.convert(bytes).toString();
  }

  List<int> _toSha256I(String message) {
    List<int> bytes = utf8.encode(message);
    return sha256.convert(bytes).bytes;
  }

  String _toBase64(String message) {
    List<int> bytes = utf8.encode(message);
    return base64.encode(bytes);
  }

  String _fromBase64(String message) {
    return utf8.decode(base64.decode(message));
  }

  String _toRipeMd160(String message) {
    List<int> bytes = utf8.encode(message);
    return _ripemd160Digest(bytes);
  }

  String _ripemd160Digest(Uint8List input) {
    RIPEMD160Digest digest = new RIPEMD160Digest();
    digest.update(input, 0, input.length);
    Uint8List result = new Uint8List(20);
    digest.doFinal(result, 0);
    return hex.encode(result);
  }

  Uint8List _seed() {
    var random = Random.secure();
    var seed = List<int>.generate(32, (_) => random.nextInt(256));
    return Uint8List.fromList(seed);
  }
}
