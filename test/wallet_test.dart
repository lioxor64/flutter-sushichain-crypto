import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushichain/basic_wallet.dart';
import 'package:sushichain/encrypted_wallet.dart';
import 'package:sushichain/full_wallet.dart';
import 'package:sushichain/keypair.dart';
import 'package:sushichain/network.dart';
import 'package:sushichain/wallet_error.dart';
import 'package:sushichain/wallet_factory.dart';

void main() {
  test('can generate a new wallet', () {
    final walletFactory = WalletFactory();
    Either<WalletError, BasicWallet> maybeBasicWallet =
        walletFactory.generateNewWallet(Network.testnet);

    if (maybeBasicWallet.isRight()) {
      BasicWallet basicWallet = maybeBasicWallet.toIterable().first;
      expect(basicWallet.hexPublicKey.length, 130);
      expect(basicWallet.wif.length, 96);
      expect(basicWallet.address.length, 64);
    } else {
      fail('Error: ' + maybeBasicWallet.swap().toIterable().first.message);
    }
  });

  test('can generate correct WIF', () {
    final walletFactory = WalletFactory();
    String hexPrivateKey =
        'f92913f355539a6ec6129b744a9e1dcb4d3c8df29cccb8066d57c454cead6fe4';
    String networkPrefix = 'M0';
    Either<WalletError, String> maybeWif =
        walletFactory.generateWif(hexPrivateKey, networkPrefix);

    if (maybeWif.isRight()) {
      String wif = maybeWif.toIterable().first;
      expect(wif,
          'TTBmOTI5MTNmMzU1NTM5YTZlYzYxMjliNzQ0YTllMWRjYjRkM2M4ZGYyOWNjY2I4MDY2ZDU3YzQ1NGNlYWQ2ZmU0MjdlYzNl');
    } else {
      fail('Error: ' + maybeWif.swap().toIterable().first.message);
    }
  });

  test('can generate correct Address', () {
    final walletFactory = WalletFactory();
    String hexPublicKey =
        '049ec703e3eab6beba4b1ea5745da006ecce8a556144cfb7d8bbbe0f31896c08f9aac3aee3410b38fe61b6cfc5afd447faa1ca051f1e0adf1d466addf55fc77d50';

    String networkPrefix = 'M0';
    Either<WalletError, String> maybeAddress =
        walletFactory.generateAddress(hexPublicKey, networkPrefix);

    if (maybeAddress.isRight()) {
      String address = maybeAddress.toIterable().first;
      expect(address,
          'TTAzZGQxYzhmMDMyYmFhM2VmZDBmNTI5YTRmNTY0MjVhOWI3NjljOGYwODgyNDlk');
    } else {
      fail('Error: ' + maybeAddress.swap().toIterable().first.message);
    }
  });

  test('can get privatekey and network from wif', () {
    final walletFactory = WalletFactory();
    String wif =
        'TTBmOTI5MTNmMzU1NTM5YTZlYzYxMjliNzQ0YTllMWRjYjRkM2M4ZGYyOWNjY2I4MDY2ZDU3YzQ1NGNlYWQ2ZmU0MjdlYzNl';

    Either<WalletError, Tuple2<String, String>> maybeResult =
        walletFactory.getPrivateKeyAndNetworkFromWif(wif);

    if (maybeResult.isRight()) {
      Tuple2<String, String> data = maybeResult.toIterable().first;
      expect(data.value1,
          'f92913f355539a6ec6129b744a9e1dcb4d3c8df29cccb8066d57c454cead6fe4');
      expect(data.value2, 'M0');
    } else {
      fail('Error: ' + maybeResult.swap().toIterable().first.message);
    }
  });

  test('can get publickey from privatekey', () {
    final walletFactory = WalletFactory();
    Either<WalletError, KeyPair> keyPair = walletFactory.generateKeyPair();
    String hexPublicKey =
        keyPair.map((kp) => kp.hexPublicKey).toIterable().first;
    String hexPrivateKey =
        keyPair.map((kp) => kp.hexPrivateKey).toIterable().first;

    Either<WalletError, String> maybePublicKey =
        walletFactory.getPublicKeyFromPrivateKey(hexPrivateKey);

    if (maybePublicKey.isRight()) {
      String key = maybePublicKey.toIterable().first;
      expect(key, hexPublicKey);
    } else {
      fail('Error: ' + maybePublicKey.swap().toIterable().first.message);
    }
  });

  test('can get basic wallet from wif', () {
    final walletFactory = WalletFactory();
    Either<WalletError, KeyPair> keyPair = walletFactory.generateKeyPair();
    String hexPublicKey =
        keyPair.map((kp) => kp.hexPublicKey).toIterable().first;
    String hexPrivateKey =
        keyPair.map((kp) => kp.hexPrivateKey).toIterable().first;
    String wif =
        walletFactory.generateWif(hexPrivateKey, 'M0').toIterable().first;
    String address =
        walletFactory.generateAddress(hexPublicKey, 'M0').toIterable().first;

    Either<WalletError, BasicWallet> maybeBasicWallet =
        walletFactory.getWalletFromWif(wif);

    if (maybeBasicWallet.isRight()) {
      BasicWallet basicWallet = maybeBasicWallet.toIterable().first;
      expect(basicWallet.hexPublicKey, hexPublicKey);
      expect(basicWallet.wif, wif);
      expect(basicWallet.address, address);
    } else {
      fail('Error: ' + maybeBasicWallet.swap().toIterable().first.message);
    }
  });

  test('can get full wallet from wif', () {
    final walletFactory = WalletFactory();
    Either<WalletError, KeyPair> keyPair = walletFactory.generateKeyPair();
    String hexPublicKey =
        keyPair.map((kp) => kp.hexPublicKey).toIterable().first;
    String hexPrivateKey =
        keyPair.map((kp) => kp.hexPrivateKey).toIterable().first;
    String networkPrefix = 'M0';
    String wif = walletFactory
        .generateWif(hexPrivateKey, networkPrefix)
        .toIterable()
        .first;
    String address = walletFactory
        .generateAddress(hexPublicKey, networkPrefix)
        .toIterable()
        .first;

    Either<WalletError, FullWallet> maybeFullWallet =
        walletFactory.getFullWalletFromWif(wif);

    if (maybeFullWallet.isRight()) {
      FullWallet fullWallet = maybeFullWallet.toIterable().first;
      expect(fullWallet.hexPublicKey, hexPublicKey);
      expect(fullWallet.hexPrivateKey, hexPrivateKey);
      expect(fullWallet.wif, wif);
      expect(fullWallet.address, address);
      expect(fullWallet.networkPrefix, networkPrefix);
    } else {
      fail('Error: ' + maybeFullWallet.swap().toIterable().first.message);
    }
  });

  test('can encrypt a wallet', () async {
    final walletFactory = WalletFactory();
    Either<WalletError, BasicWallet> maybeBasicWallet =
    walletFactory.generateNewWallet(Network.testnet);

    if (maybeBasicWallet.isRight()) {
      BasicWallet basicWallet = maybeBasicWallet.toIterable().first;

      Future<Either<WalletError, EncryptedWallet>> future = walletFactory.encryptWallet(basicWallet, "Passw0rd99");
      Either<WalletError, EncryptedWallet> maybeEnc = await future;

      if(maybeEnc.isRight()){
        EncryptedWallet wallet = maybeEnc.toIterable().first;
        print(wallet);
      } else {
        fail('Error: ' + maybeEnc.swap().toIterable().first.message);
      }


    } else {
      fail('Error: ' + maybeBasicWallet.swap().toIterable().first.message);
    }
  });

}
