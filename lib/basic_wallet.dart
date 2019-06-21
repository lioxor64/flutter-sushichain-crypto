import 'package:quiver_hashcode/hashcode.dart';

import 'model.dart';

/// BasicWallet holds the basic wallet information which consists of:
/// * hexPublicKey - the public key in hex format
/// * wif - the Wallet Information Format (contains the private key within)
/// * address - the Base64 encoded address
class BasicWallet {
  HexPublicKey hexPublicKey;
  Wif wif;
  Address address;

  BasicWallet(this.hexPublicKey, this.wif, this.address);

  BasicWallet.fromJson(Map<String, dynamic> json)
      : hexPublicKey = HexPublicKey(json['hexPublicKey']),
        wif = Wif(json['wif']),
        address = Address(json['address']);

  Map<String, dynamic> toJson() =>
      {'hexPublicKey': hexPublicKey.value, 'wif': wif.value, 'address': address.value};

  bool operator ==(o) =>
      o is BasicWallet &&
      o.hexPublicKey.value == hexPublicKey.value &&
      o.wif.value          == wif.value &&
      o.address.value      == address.value;

  int get hashCode => hash3(hexPublicKey.hashCode, wif.hashCode, address.hashCode);
}
