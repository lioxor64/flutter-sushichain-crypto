import 'package:quiver_hashcode/hashcode.dart';

class BasicWallet {
  String hexPublicKey;
  String wif;
  String address;

  BasicWallet(this.hexPublicKey, this.wif, this.address);

  BasicWallet.fromJson(Map<String, dynamic> json)
      : hexPublicKey = json['hexPublicKey'],
        wif = json['wif'],
        address = json['address'];

  Map<String, dynamic> toJson() =>
      {'hexPublicKey': hexPublicKey, 'wif': wif, 'address': address};

  bool operator ==(o) =>
      o is BasicWallet &&
      o.hexPublicKey == hexPublicKey &&
      o.wif == wif &&
      o.address == address;

  int get hashCode => hash3(hexPublicKey.hashCode, wif.hashCode, address.hashCode);
}
