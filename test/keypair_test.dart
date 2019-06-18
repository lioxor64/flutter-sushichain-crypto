import 'package:flutter_test/flutter_test.dart';
import 'package:sushichain/wallet_factory.dart';

import 'test_helper.dart';

void main() {
  test('can generate a keypair', () {
    WalletFactory().generateKeyPair().fold(TestHelper.handleError, (kp){
      String hexPublicKey  = kp.hexPublicKey;
      String hexPrivateKey = kp.hexPrivateKey;

      expect(hexPrivateKey.length, 64);
      expect(hexPublicKey.length, 130);
      expect(hexPublicKey.startsWith('04'), true);
    });
  });
}
