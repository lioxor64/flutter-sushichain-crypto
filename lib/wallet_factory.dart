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
import 'model.dart';
import 'network.dart';

// https://iryanbell.com/2019-06-01-cryptographic-darts/

/// WalletFactory has several functions that assist with SushiChain based
/// crypto such as wallet generation, signing, verifying etc
class WalletFactory {

  /// Generates an ECDSA SECP256k1 key pair
  ///
  /// Either<WalletError, KeyPair> maybeKeyPair = new WalletFactory().generateKeyPair();
  /// maybeKeyPair.fold(handleError, handleSuccess);
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

      if ((kp.hexPublicKey.value.length != 130) || kp.hexPrivateKey.value.length != 64) {
        return generateKeyPair();
      }

      return right(kp);
    } catch (e) {
      return left(WalletError(e.toString()));
    }
  }

  /// Generates a new wallet for the network provided
  ///
  /// Either<WalletError, BasicWallet> maybeWallet = new WalletFactory().generateNewWallet(Network.testnet);
  /// maybeWallet.fold(handleError, handleSuccess);
  Either<WalletError, BasicWallet> generateNewWallet(Network network) {
    try {
      NetworkPrefix networkPrefix          = NetworkUtil.networkPrefix(network);
      Either<WalletError, KeyPair> keyPair = generateKeyPair();

      return keyPair.flatMap((kp) => _toBasicWallet(networkPrefix, kp));
    } catch (e) {
      return left(WalletError(e.toString()));
    }
  }

  /// Generates a new encrypted wallet for the specified network with the supplied password
  ///
  /// Either<WalletError, EncryptedWallet> maybeEncrypted = new WalletFactory().generateNewEncryptedWallet(Network.testnet, 'password');
  /// maybeEncrypted.fold(handleError, handleSuccess);
  Either<WalletError, EncryptedWallet> generateNewEncryptedWallet(Network network, String password) {
    try {
      return generateNewWallet(network).flatMap((bw) => encryptWallet(bw, password));
    } catch (e) {
      return left(WalletError(e.toString()));
    }
  }

  Either<WalletError, BasicWallet> _toBasicWallet(
      NetworkPrefix networkPrefix, KeyPair keyPair) {
    HexPublicKey hexPublicKey = keyPair.hexPublicKey;
    HexPrivateKey hexPrivateKey = keyPair.hexPrivateKey;

    Either<WalletError, Wif> maybeWif =
        generateWif(hexPrivateKey, networkPrefix);
    Either<WalletError, Address> maybeAddress =
        generateAddress(hexPublicKey, networkPrefix);

    return Either.map2(maybeWif, maybeAddress,
        (wif, address) => BasicWallet(hexPublicKey, wif, address));
  }

  /// Generates a WIF given a hexPrivateKey and target network
  ///
  /// Either<WalletError, String> maybeWif = new WalletFactory().generateWif(hexPrivateKey, Network.testnet);
  /// maybeWif.fold(handleError, handleSuccess);
  Either<WalletError, Wif> generateWif(
      HexPrivateKey hexPrivateKey, NetworkPrefix networkPrefix) {
    try {
      String networkKey = networkPrefix.value + hexPrivateKey.value;
      String hashedKey = _toSha256(_toSha256(networkKey));
      String checkSum = hashedKey.substring(0, 6);
      return right(Wif(_toBase64(networkKey + checkSum)));
    } catch (e) {
      return left(WalletError(e.toString()));
    }
  }

  /// Generates an address given a hexPublicKey and target network
  ///
  /// Either<WalletError, Address> maybeAddress = new WalletFactory().generateAddress(hexPublicKey, Network.testnet);
  /// maybeAddress.fold(handleError, handleSuccess);
  Either<WalletError, Address> generateAddress(
      HexPublicKey hexPublicKey, NetworkPrefix networkPrefix) {
    try {
      String hashedAddress = _toRipeMd160(_toSha256(hexPublicKey.value));
      String networkAddress = networkPrefix.value + hashedAddress;
      String hashedAddressAgain = _toSha256(_toSha256(networkAddress));
      String checksum = hashedAddressAgain.substring(0, 6);
      return right(Address(_toBase64(networkAddress + checksum)));
    } catch (e) {
      return left(WalletError(e.toString()));
    }
  }

  /// Gets a wallet from the supplied wif
  ///
  /// Either<WalletError, BasicWallet> maybeWallet = new WalletFactory().getWalletFromWif(wif);
  /// maybeWallet.fold(handleError, handleSuccess);
  Either<WalletError, BasicWallet> getWalletFromWif(Wif wif) {
    try {
      return getPrivateKeyAndNetworkFromWif(wif).flatMap((nwpk){
        HexPrivateKey hexPrivateKey = nwpk.value1;
        NetworkPrefix networkPrefix = nwpk.value2;

        return getPublicKeyFromPrivateKey(hexPrivateKey).flatMap( (hexPublicKey) {
          return generateAddress(hexPublicKey, networkPrefix).map((address) =>
              BasicWallet(hexPublicKey, wif, address));
        });
      });
    } catch (e) {
      return left(WalletError(e.toString()));
    }
  }

  /// Gets a full wallet from the supplied wif
  ///
  /// Either<WalletError, FullWallet> maybeWallet = new WalletFactory().getFullWalletFromWif(wif);
  /// maybeWallet.fold(handleError, handleSuccess);
  Either<WalletError, FullWallet> getFullWalletFromWif(Wif wif) {
    try {
      return getPrivateKeyAndNetworkFromWif(wif).flatMap((nwpk){
        HexPrivateKey hexPrivateKey = nwpk.value1;
        NetworkPrefix networkPrefix = nwpk.value2;

        return getPublicKeyFromPrivateKey(hexPrivateKey).flatMap( (hexPublicKey) {
          return generateAddress(hexPublicKey, networkPrefix).map((address) =>
              FullWallet(hexPublicKey, hexPrivateKey, wif, address, networkPrefix));
        });
      });
    } catch (e) {
      return left(WalletError(e.toString()));
    }
  }

  /// Encrypts a wallet
  ///
  /// Either<WalletError, EncryptedWallet> maybeEncrypted = new WalletFactory().encryptWallet(wallet, password);
  /// maybeEncrypted.fold(handleError, handleSuccess);
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
          Source("flutter"), CipherText(cipherText), wallet.address, Salt(hex.encode(iv))));
    } catch (e) {
      return left(WalletError(e.toString()));
    }
  }

  /// Decrypts a wallet
  ///
  /// Either<WalletError, BasicWallet> maybeWallet = new WalletFactory().decryptWallet(encryptedWallet, password);
  /// maybeWallet.fold(handleError, handleSuccess);
  Either<WalletError, BasicWallet> decryptWallet(
      EncryptedWallet wallet, String password) {
    try {
      var key = _toSha256I(password);
      var iv = hex.decode(wallet.salt.value);
      var message = hex.decode(wallet.cipherText.value);

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

  /// Gets the hexPrivateKey and the network from a wif
  ///
  /// Either<WalletError, Tuple2<String, String>> maybeResult = new WalletFactory().getPrivateKeyAndNetworkFromWif(wif);
  /// maybeResult.fold(handleError, handleSuccess);
  Either<WalletError, Tuple2<HexPrivateKey, NetworkPrefix>> getPrivateKeyAndNetworkFromWif(
      Wif wif) {
    try {
      String decodedWif           = _fromBase64(wif.value);
      NetworkPrefix networkPrefix = NetworkPrefix(decodedWif.substring(0, 2));
      HexPrivateKey hexPrivateKey = HexPrivateKey(decodedWif.substring(2, decodedWif.length - 6));
      return right(Tuple2(hexPrivateKey, networkPrefix));
    } catch (e) {
      return left(WalletError(e.toString()));
    }
  }

  /// Gets the hexPublicKey from the hexPrivateKey
  ///
  /// Either<WalletError, HexPublicKey> maybeKey = new WalletFactory().getPublicKeyFromPrivateKey(hexPrivateKey);
  /// maybeKey.fold(handleError, handleSuccess);
  Either<WalletError, HexPublicKey> getPublicKeyFromPrivateKey(HexPrivateKey hexPrivateKey) {
    try {
      ECKeyGeneratorParameters keyParams =
          ECKeyGeneratorParameters(ECCurve_secp256k1());
      BigInt privateKey = BigInt.parse(hexPrivateKey.value, radix: 16);
      ECPoint point = keyParams.domainParameters.G * privateKey;
      Uint8List encodedPoint = point.getEncoded(false);
      return right(HexPublicKey(hex.encode(encodedPoint)));
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
