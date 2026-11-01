import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;
import 'razorpay_checkout.dart';

@JS('Razorpay')
extension type _Razorpay._(JSObject _) implements JSObject {
  external _Razorpay(JSObject options);
  external void open();
}

Future<void>? _loading;

// Loaded only when someone pays, so the menu stays as light as possible.
Future<void> _loadScript() => _loading ??= () {
      final done = Completer<void>();
      final script = web.document.createElement('script') as web.HTMLScriptElement
        ..src = razorpayCheckoutUrl
        ..async = true;
      script.onload = ((web.Event _) => done.complete()).toJS;
      script.onerror = ((web.Event _) {
        _loading = null;
        if (!done.isCompleted) done.completeError(StateError('checkout script failed to load'));
      }).toJS;
      web.document.head!.append(script);
      return done.future;
    }();

Future<CheckoutOutcome> openRazorpay(Map<String, dynamic> c, {required String cafeName, required String themeColor}) async {
  try {
    await _loadScript();
  } on StateError {
    return const CheckoutUnavailable();
  }
  final result = Completer<CheckoutOutcome>();
  final options = {
    'key': c['keyId'],
    'amount': c['amountMinor'],
    'currency': c['currency'],
    'order_id': c['orderId'],
    'name': cafeName,
    'description': c['description'],
    'theme': {'color': themeColor},
    if (c['method'] == 'upi' || c['method'] == 'card') 'prefill': {'method': c['method']},
  }.jsify() as JSObject;
  options['handler'] = ((JSObject r) {
    if (result.isCompleted) return;
    result.complete(CheckoutPaid(
      paymentRef: (r['razorpay_payment_id'] as JSString).toDart,
      signature: (r['razorpay_signature'] as JSString).toDart,
    ));
  }).toJS;
  final modal = JSObject();
  modal['ondismiss'] = (() {
    if (!result.isCompleted) result.complete(const CheckoutDismissed());
  }).toJS;
  options['modal'] = modal;
  _Razorpay(options).open();
  return result.future;
}
