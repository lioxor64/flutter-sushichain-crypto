import 'package:flutter_test/flutter_test.dart';
import 'package:sushichain/model.dart';
import 'package:sushichain/wallet_factory.dart';

import 'test_helper.dart';

void main() {
  test('can generate a keypair', () {
    WalletFactory().generateKeyPair().fold(TestHelper.handleError, (kp){
      HexPublicKey hexPublicKey  = kp.hexPublicKey;
      HexPrivateKey hexPrivateKey = kp.hexPrivateKey;

      expect(hexPrivateKey.value.length, 64);
      expect(hexPublicKey.value.length, 130);
      expect(hexPublicKey.value.startsWith('04'), true);
    });
  });
}
