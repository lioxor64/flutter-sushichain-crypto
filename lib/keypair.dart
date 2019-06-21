import 'package:pointycastle/api.dart';
import 'package:pointycastle/ecc/api.dart';

import 'model.dart';

/// This holds an ECDSA keypair
/// * publicKey
/// * privateKey
class KeyPair {
  ECPublicKey publicKey;
  ECPrivateKey privateKey;

  KeyPair(AsymmetricKeyPair<PublicKey, PrivateKey> keyPair) {
    this.publicKey = keyPair.publicKey;
    this.privateKey = keyPair.privateKey;
  }

  /// Returns the publicKey in hex format
  HexPublicKey get hexPublicKey {
    return HexPublicKey('04' +
        publicKey.Q.x.toBigInteger().toRadixString(16) +
        publicKey.Q.y.toBigInteger().toRadixString(16));
  }

  /// Returns the privateKey in hex format
  HexPrivateKey get hexPrivateKey {
    return HexPrivateKey(privateKey.d.toRadixString(16));
  }
}
