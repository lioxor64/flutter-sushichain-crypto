import 'package:flutter_test/flutter_test.dart';
import 'package:sushichain/wallet_error.dart';

class TestHelper {
  static void handleError(WalletError error) {
    fail(error.message);
  }
}
