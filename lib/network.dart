import 'model.dart';

/// The network
/// * mainnet
/// * testnet
enum Network {
  testnet,
  mainnet
}

/// Given a Network enum it returns the prefix
/// e.g. 'M0' or 'T0'
class NetworkUtil {
  static networkPrefix(Network network) {
    switch (network) {
      case Network.mainnet:
        return NetworkPrefix("M0");
      default:
        return NetworkPrefix("T0");
    }
  }
}
