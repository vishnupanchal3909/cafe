import 'razorpay_checkout.dart';

/// Native apps have no checkout script, so the caller falls back to a hosted payment link.
Future<CheckoutOutcome> openRazorpay(Map<String, dynamic> checkout, {required String cafeName, required String themeColor}) async => const CheckoutUnavailable();
