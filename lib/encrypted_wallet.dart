import 'model.dart';

/// EncryptedWallet holds the encrupted wallet information which consists of:
/// * source - which app the encrypted wallet came from
/// * cipherText - the encrypted basic wallet json
/// * address - the Base64 encoded address
/// * salt - the salt used to encrypt the wallet
class EncryptedWallet {
  final Source source;
  final CipherText cipherText;
  final Address address;
  final Salt salt;

  EncryptedWallet(this.source, this.cipherText, this.address, this.salt);

  EncryptedWallet.fromJson(Map<String, dynamic> json)
      : source = Source(json['source']),
        cipherText = CipherText(json['ciphertext']),
        address = Address(json['address']),
        salt = Salt(json['salt']);

  Map<String, dynamic> toJson() =>
      {'source': source.value,
        'ciphertext': cipherText.value,
        'address': address.value,
        'salt': salt.value
      };
}
