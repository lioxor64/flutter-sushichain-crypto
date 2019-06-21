import 'model.dart';

/// FullWallet holds the full wallet information which consists of:
/// * hexPublicKey - the public key in hex format
/// * hexPrivateKey - the private key in hex format
/// * wif - the Wallet Information Format (contains the private key within)
/// * address - the Base64 encoded address
/// * networkPrefix - the network e.g. mainnet 'M0' or testnet 'T0'
class FullWallet {
  HexPublicKey hexPublicKey;
  Wif wif;
  Address address;
  NetworkPrefix networkPrefix;
  HexPrivateKey hexPrivateKey;

  FullWallet(this.hexPublicKey, this.hexPrivateKey, this.wif, this.address,
      this.networkPrefix);
}
