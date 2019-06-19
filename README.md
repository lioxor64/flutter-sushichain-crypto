# SushiChain Crypto

A Flutter plugin for iOS and Android providing the base crypto functions for the [SushiChain](https://sushichain.io) blockchain platform.

## Features

* generateKeyPair
* generateNewWallet
* generateWif
* generateAddress
* getWalletFromWif
* getFullWalletFromWif
* encryptWallet
* decryptWallet

## Installation

Add the dependency to your `pubspec.yaml`

```yaml
dependencies:
  sushichain: ^1.0.0
```

## Example

```dart
import 'package:dartz/dartz.dart';
import 'package:sushichain/network.dart';
import 'package:sushichain/wallet_factory.dart';

walletFactory.generateNewWallet(Network.testnet).fold(handleErrorHere,(basicWallet){
  // Do something with the basicWallet here
});
```