import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushichain/keypair.dart';
import 'package:sushichain/wallet_error.dart';
import 'package:sushichain/wallet_factory.dart';

void main() {
  test('can generate a keypair', () {
    final walletFactory = WalletFactory();
    Either<WalletError, KeyPair> keypair = walletFactory.generateKeyPair();
    String privateKey = keypair
        .map((kp) => kp.hexPrivateKey)
        .getOrElse(() => fail('could not generate private key'));
    String publicKey = keypair
        .map((kp) => kp.hexPublicKey)
        .getOrElse(() => fail('could not generate public key'));
    expect(privateKey.length, 64);
    expect(publicKey.length, 130);
    expect(publicKey.startsWith('04'), true);
  });
}
