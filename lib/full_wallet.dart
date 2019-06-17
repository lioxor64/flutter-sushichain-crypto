class FullWallet {
  String hexPublicKey;
  String wif;
  String address;
  String networkPrefix;
  String hexPrivateKey;

  FullWallet(this.hexPublicKey, this.hexPrivateKey, this.wif, this.address,
      this.networkPrefix);
}
