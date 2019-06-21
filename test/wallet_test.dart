import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushichain/basic_wallet.dart';
import 'package:sushichain/encrypted_wallet.dart';
import 'package:sushichain/model.dart';
import 'package:sushichain/network.dart';
import 'package:sushichain/wallet_factory.dart';

import 'test_helper.dart';

void main() {

  final walletFactory = WalletFactory();

  test('can generate a new wallet', () {
    walletFactory.generateNewWallet(Network.testnet).fold(TestHelper.handleError,(basicWallet){
      expect(basicWallet,                           isA<BasicWallet>());
      expect(basicWallet.hexPublicKey.value.length, 130);
      expect(basicWallet.wif.value.length,          96);
      expect(basicWallet.address.value.length,      64);
    });
  });

  test('can generate a new encrypted wallet', () {
    walletFactory.generateNewEncryptedWallet(Network.testnet, 'Passw0rd99').fold(TestHelper.handleError,(ew){
      expect(ew, isA<EncryptedWallet>());
    });
  });

  test('can generate correct WIF', () {
    HexPrivateKey hexPrivateKey = HexPrivateKey('f92913f355539a6ec6129b744a9e1dcb4d3c8df29cccb8066d57c454cead6fe4');
    NetworkPrefix networkPrefix = NetworkPrefix('M0');
    Wif expectedWif             = Wif('TTBmOTI5MTNmMzU1NTM5YTZlYzYxMjliNzQ0YTllMWRjYjRkM2M4ZGYyOWNjY2I4MDY2ZDU3YzQ1NGNlYWQ2ZmU0MjdlYzNl');

    walletFactory.generateWif(hexPrivateKey, networkPrefix).fold(TestHelper.handleError, (wif){
      expect(wif,expectedWif);
    });
  });

  test('can generate correct Address', () {
    HexPublicKey hexPublicKey   = HexPublicKey('049ec703e3eab6beba4b1ea5745da006ecce8a556144cfb7d8bbbe0f31896c08f9aac3aee3410b38fe61b6cfc5afd447faa1ca051f1e0adf1d466addf55fc77d50');
    NetworkPrefix networkPrefix = NetworkPrefix('M0');
    Address expectedAddress     = Address('TTAzZGQxYzhmMDMyYmFhM2VmZDBmNTI5YTRmNTY0MjVhOWI3NjljOGYwODgyNDlk');

    walletFactory.generateAddress(hexPublicKey, networkPrefix).fold(TestHelper.handleError, (address){
      expect(address, expectedAddress);
    });
  });

  test('can get privatekey and network from wif', () {
    Wif wif                          = Wif('TTBmOTI5MTNmMzU1NTM5YTZlYzYxMjliNzQ0YTllMWRjYjRkM2M4ZGYyOWNjY2I4MDY2ZDU3YzQ1NGNlYWQ2ZmU0MjdlYzNl');
    HexPrivateKey expectedPrivateKey = HexPrivateKey('f92913f355539a6ec6129b744a9e1dcb4d3c8df29cccb8066d57c454cead6fe4');
    NetworkPrefix expectedNetwork    = NetworkPrefix('M0');

    walletFactory.getPrivateKeyAndNetworkFromWif(wif).fold(TestHelper.handleError, (nwpk){
      expect(nwpk.value1, expectedPrivateKey);
      expect(nwpk.value2, expectedNetwork);
    });
  });

  test('can get publickey from privatekey', () {
    walletFactory.generateKeyPair().fold(TestHelper.handleError, (kp){
      HexPublicKey expectedHexPublicKey = kp.hexPublicKey;
      HexPrivateKey hexPrivateKey       = kp.hexPrivateKey;
      walletFactory.getPublicKeyFromPrivateKey(hexPrivateKey).fold(TestHelper.handleError, (hexPublicKey){
        expect(hexPublicKey, expectedHexPublicKey);
      });
    });
  });

  test('can get basic wallet from wif', () {
    walletFactory.generateKeyPair().fold(TestHelper.handleError, (kp) {
      HexPublicKey hexPublicKey   = kp.hexPublicKey;
      HexPrivateKey hexPrivateKey = kp.hexPrivateKey;
      NetworkPrefix networkPrefix = NetworkPrefix('M0');

      Either.map2(walletFactory.generateWif(hexPrivateKey, networkPrefix),
          walletFactory.generateAddress(hexPublicKey, networkPrefix), (wif, address) {
            walletFactory.getWalletFromWif(wif).fold(
                TestHelper.handleError, (basicWallet) {
              expect(basicWallet.hexPublicKey, hexPublicKey);
              expect(basicWallet.wif,          wif);
              expect(basicWallet.address,      address);
            });
          });
    });
  });

  test('can get full wallet from wif', () {
    walletFactory.generateKeyPair().fold(TestHelper.handleError, (kp) {
      HexPublicKey hexPublicKey   = kp.hexPublicKey;
      HexPrivateKey hexPrivateKey = kp.hexPrivateKey;
      NetworkPrefix networkPrefix = NetworkPrefix('M0');

      Either.map2(walletFactory.generateWif(hexPrivateKey, networkPrefix),
          walletFactory.generateAddress(hexPublicKey, networkPrefix),
              (wif, address) {
            walletFactory.getFullWalletFromWif(wif).fold(
                TestHelper.handleError, (basicWallet) {
              expect(basicWallet.hexPrivateKey, hexPrivateKey);
              expect(basicWallet.hexPublicKey,  hexPublicKey);
              expect(basicWallet.wif,           wif);
              expect(basicWallet.address,       address);
            });
          });
    });
  });

  test('can encrypt a wallet', () {
    walletFactory.generateNewWallet(Network.testnet).fold(TestHelper.handleError,(basicWallet){
      walletFactory.encryptWallet(basicWallet, "Passw0rd99").fold(TestHelper.handleError,(ew){
        expect(ew,         isA<EncryptedWallet>());
        expect(ew.address, basicWallet.address);
      });
    });
  });

  test('can decrypt a wallet', () {
    String password = "Passw0rd99";
    walletFactory.generateNewWallet(Network.testnet).fold(TestHelper.handleError,(basicWallet){
      walletFactory.encryptWallet(basicWallet, password).fold(TestHelper.handleError,(ew){
        walletFactory.decryptWallet(ew, password).fold(TestHelper.handleError, (bw){
          expect(bw, basicWallet);
        });
      });
    });
  });

}
