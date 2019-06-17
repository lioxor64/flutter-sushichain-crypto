import 'package:pointycastle/api.dart';
import 'package:pointycastle/ecc/api.dart';

class KeyPair {
  ECPublicKey publicKey;
  ECPrivateKey privateKey;

  KeyPair(AsymmetricKeyPair<PublicKey, PrivateKey> keyPair) {
    this.publicKey = keyPair.publicKey;
    this.privateKey = keyPair.privateKey;
  }

  String get hexPublicKey {
    return '04' +
        publicKey.Q.x.toBigInteger().toRadixString(16) +
        publicKey.Q.y.toBigInteger().toRadixString(16);
  }

  String get hexPrivateKey {
    return privateKey.d.toRadixString(16);
  }
}
