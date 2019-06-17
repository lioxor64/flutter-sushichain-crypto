class EncryptedWallet {
  final String source;
  final String cipherText;
  final String address;
  final String salt;

  EncryptedWallet(this.source, this.cipherText, this.address, this.salt);

  EncryptedWallet.fromJson(Map<String, dynamic> json)
      : source = json['source'],
        cipherText = json['ciphertext'],
        address = json['address'],
        salt = json['salt'];

  Map<String, dynamic> toJson() =>
      {'source': source,
        'ciphertext': cipherText,
        'address': address,
        'salt': salt
      };
}
