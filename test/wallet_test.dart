import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushichain/network.dart';
import 'package:sushichain/wallet_error.dart';
import 'package:sushichain/wallet_factory.dart';

void main() {

  void handleError(WalletError error){
    fail(error.message);
  }

  test('can generate a new wallet', () {
    final walletFactory = WalletFactory();
    walletFactory.generateNewWallet(Network.testnet).fold(handleError,(basicWallet){
      expect(basicWallet.hexPublicKey.length, 130);
      expect(basicWallet.wif.length,           96);
      expect(basicWallet.address.length,       64);
    });
  });

  test('can generate correct WIF', () {
    final walletFactory  = WalletFactory();
    String hexPrivateKey = 'f92913f355539a6ec6129b744a9e1dcb4d3c8df29cccb8066d57c454cead6fe4';
    String networkPrefix = 'M0';
    String expectedWif   = 'TTBmOTI5MTNmMzU1NTM5YTZlYzYxMjliNzQ0YTllMWRjYjRkM2M4ZGYyOWNjY2I4MDY2ZDU3YzQ1NGNlYWQ2ZmU0MjdlYzNl';

    walletFactory.generateWif(hexPrivateKey, networkPrefix).fold(handleError, (wif){
      expect(wif,expectedWif);
    });
  });

  test('can generate correct Address', () {
    final walletFactory    = WalletFactory();
    String hexPublicKey    = '049ec703e3eab6beba4b1ea5745da006ecce8a556144cfb7d8bbbe0f31896c08f9aac3aee3410b38fe61b6cfc5afd447faa1ca051f1e0adf1d466addf55fc77d50';
    String networkPrefix   = 'M0';
    String expectedAddress = 'TTAzZGQxYzhmMDMyYmFhM2VmZDBmNTI5YTRmNTY0MjVhOWI3NjljOGYwODgyNDlk';

    walletFactory.generateAddress(hexPublicKey, networkPrefix).fold(handleError, (address){
      expect(address, expectedAddress);
    });
  });

  test('can get privatekey and network from wif', () {
    final walletFactory       = WalletFactory();
    String wif                = 'TTBmOTI5MTNmMzU1NTM5YTZlYzYxMjliNzQ0YTllMWRjYjRkM2M4ZGYyOWNjY2I4MDY2ZDU3YzQ1NGNlYWQ2ZmU0MjdlYzNl';
    String expectedPrivateKey = 'f92913f355539a6ec6129b744a9e1dcb4d3c8df29cccb8066d57c454cead6fe4';
    String expectedNetwork    = 'M0';

    walletFactory.getPrivateKeyAndNetworkFromWif(wif).fold(handleError, (nwpk){
      expect(nwpk.value1, expectedPrivateKey);
      expect(nwpk.value2, expectedNetwork);
    });
  });

  test('can get publickey from privatekey', () {
    final walletFactory            = WalletFactory();
    walletFactory.generateKeyPair().fold(handleError, (kp){
      String expectedHexPublicKey  = kp.hexPublicKey;
      String hexPrivateKey         = kp.hexPrivateKey;
      walletFactory.getPublicKeyFromPrivateKey(hexPrivateKey).fold(handleError, (hexPublicKey){
        expect(hexPublicKey, expectedHexPublicKey);
      });
    });
  });

  test('can get basic wallet from wif', () {
    final walletFactory = WalletFactory();

    walletFactory.generateKeyPair().fold(handleError, (kp) {
      String hexPublicKey = kp.hexPublicKey;
      String hexPrivateKey = kp.hexPrivateKey;

      Either.map2(walletFactory.generateWif(hexPrivateKey, 'M0'),
          walletFactory.generateAddress(hexPublicKey, 'M0'),
              (wif, address) => Tuple2(wif, address))
          .fold(handleError, (wa) {
        String wif = wa.value1;
        String address = wa.value2;

        walletFactory.getWalletFromWif(wif).fold(handleError, (basicWallet) {
          expect(basicWallet.hexPublicKey, hexPublicKey);
          expect(basicWallet.wif, wif);
          expect(basicWallet.address, address);
        });
      });
    });
  });

  test('can get full wallet from wif', () {
    final walletFactory    = WalletFactory();

    walletFactory.generateKeyPair().fold(handleError, (kp){
      String hexPublicKey  = kp.hexPublicKey;
      String hexPrivateKey = kp.hexPrivateKey;

      Either.map2(walletFactory.generateWif(hexPrivateKey, 'M0'),
          walletFactory.generateAddress(hexPublicKey, 'M0'),
              (wif, address) => Tuple2(wif,address))
          .fold(handleError, (wa){
        String wif     = wa.value1;
        String address = wa.value2;

        walletFactory.getFullWalletFromWif(wif).fold(handleError, (basicWallet){
          expect(basicWallet.hexPrivateKey, hexPrivateKey);
          expect(basicWallet.hexPublicKey,  hexPublicKey);
          expect(basicWallet.wif,           wif);
          expect(basicWallet.address,       address);
        });
      });
    });
  });

  test('can encrypt a wallet', () {
    final walletFactory = WalletFactory();
    walletFactory.generateNewWallet(Network.testnet).fold(handleError,(basicWallet){
      walletFactory.encryptWallet(basicWallet, "Passw0rd99").fold(handleError,(ew){
        expect(ew.address, basicWallet.address);
      });
    });
  });

//  test('can decrypt a wallet', () {
//    final walletFactory = WalletFactory();
//    Either<WalletError, BasicWallet> maybeBasicWallet =
//    walletFactory.generateNewWallet(Network.testnet);
//
//    if (maybeBasicWallet.isRight()) {
//      BasicWallet basicWallet = maybeBasicWallet.toIterable().first;
//
//      Either<WalletError, EncryptedWallet> maybeEnc = walletFactory.encryptWallet(basicWallet, "Passw0rd99");
//
//      if(maybeEnc.isRight()){
//        EncryptedWallet wallet = maybeEnc.toIterable().first;
//        print(wallet.toJson());
//      } else {
//        fail('Error: ' + maybeEnc.swap().toIterable().first.message);
//      }
//
//    } else {
//      fail('Error: ' + maybeBasicWallet.swap().toIterable().first.message);
//    }
//  });

}
