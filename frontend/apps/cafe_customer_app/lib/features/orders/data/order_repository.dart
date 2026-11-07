import 'dart:math';
import 'package:shared_models/shared_models.dart';
import 'package:shared_network/shared_network.dart';
import '../../cart/domain/cart.dart';

abstract class OrderRepository {
  Future<CafeOrder> place(Cart cart, {String? notes, String? coupon, required String language, required String idempotencyKey});
  Future<CafeOrder> get(String publicId);
  Future<List<CafeOrder>> forSession();
  Future<Map<String, dynamic>> paymentOptions();
  Future<Map<String, dynamic>> startPayment(String orderId, String method, {String? amount, bool link = false});
  Future<Map<String, dynamic>> verifyPayment(String paymentId, String paymentRef, String signature);
  Future<void> abandonPayment(String paymentId);
  Future<Map<String, dynamic>> paymentStatus(String paymentId);
  Future<void> serviceRequest(String type);

  /// Checks the PIN staff gave the guest. Afterwards this device may order at the table.
  Future<void> enterTablePin(String pin);
  Future<void> review(String orderId, int rating, String? comment);
}

String newIdempotencyKey() {
  final r = Random.secure();
  return List.generate(24, (_) => r.nextInt(16).toRadixString(16)).join();
}

class ApiOrderRepository implements OrderRepository {
  ApiOrderRepository(this._api);
  final ApiClient _api;

  @override
  Future<void> enterTablePin(String pin) async => _api.tablePin = (await _api.post<Map<String, dynamic>>('/customer/table-pin', body: {'pin': pin}))['proof'] as String;

  @override
  Future<CafeOrder> place(Cart cart, {String? notes, String? coupon, required String language, required String idempotencyKey}) async => CafeOrder.fromJson(await _api.post<Map<String, dynamic>>('/customer/orders', idempotencyKey: idempotencyKey, body: {
        'language': language,
        'items': [for (final l in cart.lines) l.toRequest()],
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (coupon != null && coupon.isNotEmpty) 'couponCode': coupon,
      }));
  @override
  Future<CafeOrder> get(String publicId) async => CafeOrder.fromJson(await _api.get<Map<String, dynamic>>('/customer/orders/$publicId'));
  @override
  Future<List<CafeOrder>> forSession() async => [for (final o in await _api.get<List<dynamic>>('/customer/orders')) CafeOrder.fromJson(o as Map<String, dynamic>)];
  @override
  Future<Map<String, dynamic>> paymentOptions() => _api.get<Map<String, dynamic>>('/customer/payment-options');
  @override
  Future<Map<String, dynamic>> startPayment(String orderId, String method, {String? amount, bool link = false}) => _api.post<Map<String, dynamic>>('/customer/orders/$orderId/payments', body: {'methodCode': link ? 'payment_link' : method, if (amount != null) 'amount': amount, if (link) 'flow': 'link'}, idempotencyKey: newIdempotencyKey());
  @override
  Future<Map<String, dynamic>> verifyPayment(String paymentId, String paymentRef, String signature) => _api.post<Map<String, dynamic>>('/customer/payments/$paymentId/verify', body: {'providerPaymentRef': paymentRef, 'signature': signature});
  @override
  Future<void> abandonPayment(String paymentId) => _api.post<Map<String, dynamic>>('/customer/payments/$paymentId/abandon');
  @override
  Future<Map<String, dynamic>> paymentStatus(String paymentId) => _api.get<Map<String, dynamic>>('/customer/payments/$paymentId');
  @override
  Future<void> serviceRequest(String type) => _api.post<Map<String, dynamic>>('/customer/service-requests', body: {'type': type});
  @override
  Future<void> review(String orderId, int rating, String? comment) => _api.post<Map<String, dynamic>>('/customer/orders/$orderId/review', body: {'rating': rating, if (comment != null && comment.isNotEmpty) 'comment': comment});
}
