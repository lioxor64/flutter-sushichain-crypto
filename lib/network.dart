enum Network {
  testnet,
  mainnet
}

class NetworkUtil {
  static networkToString(Network network) {
    switch (network) {
      case Network.mainnet:
        return "M0";
      default:
        return "T0";
    }
  }
}
