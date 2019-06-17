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
}
