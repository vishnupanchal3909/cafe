import 'dart:math';
import 'package:shared_network/shared_network.dart';

String idempotencyKey() {
  final r = Random.secure();
  return List.generate(24, (_) => r.nextInt(16).toRadixString(16)).join();
}

/// Data layer for the owner app. Screens never build URLs; the server enforces every permission named in the docs.
class OwnerRepository {
  OwnerRepository(this.api);
  final ApiClient api;

  /// The cafe's operating currency, from its profile.
  String currency = '';

  Future<void> signIn(String email, String password, {String? cafeId}) async => api.adoptTokens(await api.post<Map<String, dynamic>>('/auth/login', body: {'email': email, 'password': password, 'audience': 'cafe', 'transport': api.transport, if (cafeId != null) 'cafePublicId': cafeId}));
  Future<void> signOut() => api.signOut();
  Future<Map<String, dynamic>> reference() => api.get<Map<String, dynamic>>('/public/reference');
  Future<void> register(Map<String, dynamic> body) => api.post<Map<String, dynamic>>('/public/cafes/register', body: body);
  Future<Map<String, dynamic>> profile() => api.get<Map<String, dynamic>>('/cafe/profile');
  Future<Map<String, dynamic>> analytics(String from, String to) => api.get<Map<String, dynamic>>('/cafe/analytics', query: {'from': from, 'to': to});

  Future<List<dynamic>> orders({String? status}) async => (await api.getPage('/cafe/orders', query: {if (status != null) 'status': status, 'limit': 100})).items;
  Future<Map<String, dynamic>> order(String id) => api.get<Map<String, dynamic>>('/cafe/orders/$id');
  Future<void> orderStatus(String id, String status, {String? reason}) => api.post<Map<String, dynamic>>('/cafe/orders/$id/status', body: {'status': status, if (reason != null) 'reason': reason});
  Future<void> confirmCash(String orderId, {String? amount}) => api.post<Map<String, dynamic>>('/cafe/payments/cash', body: {'orderId': orderId, if (amount != null) 'amount': amount}, idempotencyKey: idempotencyKey());
  Future<List<dynamic>> payments({String? orderId}) => api.get<List<dynamic>>('/cafe/payments', query: {if (orderId != null) 'orderId': orderId});
  Future<String> requestRefund(String paymentId, String amount, String reason) async => (await api.post<Map<String, dynamic>>('/cafe/payments/$paymentId/refunds', body: {'amount': amount, 'reason': reason}, idempotencyKey: idempotencyKey()))['refundId'] as String;
  Future<void> approveRefund(String refundId) => api.post<Map<String, dynamic>>('/cafe/refunds/$refundId/approve');
  Future<List<dynamic>> refunds() => api.get<List<dynamic>>('/cafe/refunds');
  Future<List<dynamic>> settlements() => api.get<List<dynamic>>('/cafe/settlements');
  Future<Map<String, dynamic>> syncSettlements(String from, String to) => api.post<Map<String, dynamic>>('/cafe/settlements/sync', body: {'from': from, 'to': to});
  Future<Map<String, dynamic>> paymentBreakdown(String from, String to) => api.get<Map<String, dynamic>>('/cafe/reports/payments', query: {'from': from, 'to': to});
  Future<String> paymentLink(String orderId) async => (await api.post<Map<String, dynamic>>('/cafe/orders/$orderId/payment-link', idempotencyKey: idempotencyKey()))['shortUrl'] as String;
  Future<void> testGateway(String accountId) => api.post<Map<String, dynamic>>('/cafe/gateway-accounts/$accountId/test');

  Future<Map<String, dynamic>> menu() => api.get<Map<String, dynamic>>('/cafe/menu');
  Future<List<dynamic>> categories() => api.get<List<dynamic>>('/cafe/categories');
  Future<void> createCategory(String language, String name) => api.post<Map<String, dynamic>>('/cafe/categories', body: {'translations': [{'language': language, 'name': name}]});
  Future<void> deleteCategory(String id) => api.delete<Map<String, dynamic>>('/cafe/categories/$id');
  Future<void> createProduct(Map<String, dynamic> body) => api.post<Map<String, dynamic>>('/cafe/products', body: body);
  Future<void> updateProduct(String id, Map<String, dynamic> body) => api.patch<Map<String, dynamic>>('/cafe/products/$id', body: body);
  Future<void> deleteProduct(String id) => api.delete<Map<String, dynamic>>('/cafe/products/$id');
  Future<List<dynamic>> taxCategories() => api.get<List<dynamic>>('/cafe/tax-categories');
  Future<void> createTaxCategory(String code, String name) => api.post<Map<String, dynamic>>('/cafe/tax-categories', body: {'code': code, 'name': name});
  Future<void> addTaxRate(String code, Map<String, dynamic> body) => api.post<Map<String, dynamic>>('/cafe/tax-categories/$code/rates', body: body);

  Future<List<dynamic>> tables() => api.get<List<dynamic>>('/cafe/tables');
  Future<void> createTable(String number, int capacity) => api.post<Map<String, dynamic>>('/cafe/tables', body: {'tableNumber': number, 'capacity': capacity});
  Future<void> deleteTable(String id) => api.delete<Map<String, dynamic>>('/cafe/tables/$id');
  Future<Map<String, dynamic>> qr(String id) => api.get<Map<String, dynamic>>('/cafe/tables/$id/qr');
  Future<Map<String, dynamic>> regenerateQr(String id) => api.post<Map<String, dynamic>>('/cafe/tables/$id/qr/regenerate');
  Future<List<dynamic>> serviceRequests() => api.get<List<dynamic>>('/cafe/service-requests');
  Future<void> resolveRequest(String id) => api.patch<Map<String, dynamic>>('/cafe/service-requests/$id', body: {'status': 'resolved'});
  Future<List<dynamic>> reservations() => api.get<List<dynamic>>('/cafe/reservations');
  Future<void> createReservation(Map<String, dynamic> body) => api.post<Map<String, dynamic>>('/cafe/reservations', body: body);

  Future<List<dynamic>> staff() => api.get<List<dynamic>>('/cafe/staff');
  Future<Map<String, dynamic>> invite(Map<String, dynamic> body) => api.post<Map<String, dynamic>>('/cafe/staff', body: body);
  Future<void> setStaffStatus(String id, String status) => api.patch<Map<String, dynamic>>('/cafe/staff/$id', body: {'status': status});

  Future<List<dynamic>> stock() => api.get<List<dynamic>>('/cafe/stock');
  Future<void> createIngredient(String name, String unit) => api.post<Map<String, dynamic>>('/cafe/ingredients', body: {'name': name, 'unitCode': unit});
  Future<void> stockMove(Map<String, dynamic> body) => api.post<Map<String, dynamic>>('/cafe/stock/movements', body: body);
  Future<List<dynamic>> suppliers() => api.get<List<dynamic>>('/cafe/suppliers');
  Future<void> createSupplier(String name, String? phone) => api.post<Map<String, dynamic>>('/cafe/suppliers', body: {'name': name, if (phone != null && phone.isNotEmpty) 'phone': phone});

  Future<Map<String, dynamic>> sales(String from, String to) => api.get<Map<String, dynamic>>('/cafe/reports/sales', query: {'from': from, 'to': to});
  Future<Map<String, dynamic>> pnl(String from, String to) => api.get<Map<String, dynamic>>('/cafe/reports/pnl', query: {'from': from, 'to': to});
  Future<List<int>> export(String type, String format, String from, String to) => api.download('/cafe/reports/$type/export', query: {'format': format, 'from': from, 'to': to});
  Future<List<dynamic>> expenses() => api.get<List<dynamic>>('/cafe/expenses');
  Future<List<dynamic>> expenseCategories() => api.get<List<dynamic>>('/cafe/expense-categories');
  Future<void> createExpenseCategory(String name) => api.post<Map<String, dynamic>>('/cafe/expense-categories', body: {'name': name});
  Future<void> createExpense(Map<String, dynamic> body) => api.post<Map<String, dynamic>>('/cafe/expenses', body: body);
  Future<List<dynamic>> invoices() => api.get<List<dynamic>>('/cafe/invoices');

  Future<List<dynamic>> coupons() => api.get<List<dynamic>>('/cafe/coupons');
  Future<void> createCoupon(Map<String, dynamic> body) => api.post<Map<String, dynamic>>('/cafe/coupons', body: body);
  Future<List<dynamic>> reviews() => api.get<List<dynamic>>('/cafe/reviews');
  Future<List<dynamic>> customers() async => (await api.getPage('/cafe/customers', query: {'limit': 100})).items;

  // Menu detail
  Future<void> addVariant(String productId, String language, String name, String price) => api.post<Map<String, dynamic>>('/cafe/products/$productId/variants', body: {'price': price, 'translations': [{'language': language, 'name': name}]});
  Future<void> addExtras(String productId, String language, String groupName, String addonName, String price) async {
    final g = await api.post<Map<String, dynamic>>('/cafe/addon-groups', body: {'translations': [{'language': language, 'name': groupName}], 'addons': [{'price': price, 'translations': [{'language': language, 'name': addonName}]}]});
    await api.put<Map<String, dynamic>>('/cafe/products/$productId/addon-groups', body: {'ids': [g['publicId']]});
  }
  Future<void> addProductImage(String productId, String assetId) => api.post<Map<String, dynamic>>('/cafe/products/$productId/images', body: {'assetId': assetId});
  Future<String> upload(List<int> bytes, String filename, String kind) async => (await api.upload('/cafe/media', bytes, filename, query: {'kind': kind}))['publicId'] as String;
  Future<List<dynamic>> recipe(String productId) => api.get<List<dynamic>>('/cafe/products/$productId/recipe');
  Future<void> addRecipeLine(String productId, String ingredientId, String quantity) async {
    final current = (await recipe(productId)).cast<Map<dynamic, dynamic>>().where((x) => x['variant_id'] == null && x['ingredient_id'] != ingredientId);
    await api.put<Map<String, dynamic>>('/cafe/products/$productId/recipe', body: {'items': [for (final x in current) {'ingredientId': x['ingredient_id'], 'quantity': x['quantity'].toString()}, {'ingredientId': ingredientId, 'quantity': quantity}]});
  }
  Future<List<dynamic>> stations() => api.get<List<dynamic>>('/kitchen/stations');
  Future<void> createStation(String name) => api.post<Map<String, dynamic>>('/cafe/kitchen/stations', body: {'name': name});
  Future<void> routeProduct(String productId, String stationId) => api.put<Map<String, dynamic>>('/cafe/kitchen/products/$productId/station', body: {'stationId': stationId});
  Future<void> createBanner(String assetId, String language, String title) => api.post<Map<String, dynamic>>('/cafe/banners', body: {'assetId': assetId, 'translations': [{'language': language, 'title': title}]});

  // Orders
  Future<Map<String, dynamic>> splitBill(String orderId, int parts) => api.post<Map<String, dynamic>>('/cafe/bills/split', body: {'orderId': orderId, 'equalParts': parts});
  Future<void> transfer(String orderId, String tableId, String reason) => api.post<Map<String, dynamic>>('/cafe/orders/$orderId/transfer', body: {'tableId': tableId, 'reason': reason});

  // Business setup
  Future<List<dynamic>> branches() => api.get<List<dynamic>>('/cafe/branches');
  Future<void> createBranch(Map<String, dynamic> body) => api.post<Map<String, dynamic>>('/cafe/branches', body: body);
  Future<List<dynamic>> hours(String branchId) => api.get<List<dynamic>>('/cafe/branches/$branchId/hours');
  Future<void> setHours(String branchId, List<Map<String, dynamic>> hours) => api.put<Map<String, dynamic>>('/cafe/branches/$branchId/hours', body: {'hours': hours});
  Future<void> setLanguages(List<String> codes) => api.put<Map<String, dynamic>>('/cafe/languages', body: {'languages': codes});
  Future<List<dynamic>> gatewayAccounts() => api.get<List<dynamic>>('/cafe/gateway-accounts');
  Future<Map<String, dynamic>> saveGateway(Map<String, dynamic> body) => api.put<Map<String, dynamic>>('/cafe/gateway-accounts', body: body);
  Future<List<dynamic>> paymentMethods() => api.get<List<dynamic>>('/cafe/payment-methods');
  Future<void> setPaymentMethods(List<String> codes) => api.put<Map<String, dynamic>>('/cafe/payment-methods', body: {'methods': codes});
  Future<Map<String, dynamic>?> subscription() => api.get<Map<String, dynamic>?>('/cafe/subscription');
  Future<List<dynamic>> plans() => api.get<List<dynamic>>('/cafe/subscription/plans');
  Future<void> subscribe(String code, String interval) => api.post<Map<String, dynamic>>('/cafe/subscription', body: {'planCode': code, 'interval': interval});
  Future<void> cancelSubscription() => api.post<Map<String, dynamic>>('/cafe/subscription/cancel');

  // Purchasing
  Future<List<dynamic>> purchaseOrders() => api.get<List<dynamic>>('/cafe/purchase-orders');
  Future<void> createPurchaseOrder(String supplierId, String ingredientId, String quantity, String unitCost) => api.post<Map<String, dynamic>>('/cafe/purchase-orders', body: {'supplierId': supplierId, 'items': [{'ingredientId': ingredientId, 'quantity': quantity, 'unitCost': unitCost}]});
  Future<void> receiveAll(String id) async {
    final po = await api.get<Map<String, dynamic>>('/cafe/purchase-orders/$id');
    final open = (po['items'] as List).cast<Map<dynamic, dynamic>>().map((i) => {'ingredientId': i['ingredient_id'], 'quantity': (double.parse('${i['ordered_quantity']}') - double.parse('${i['received_quantity']}')).toStringAsFixed(4)}).where((l) => double.parse(l['quantity'] as String) > 0).toList();
    await api.post<Map<String, dynamic>>('/cafe/purchase-orders/$id/receive', body: {'lines': open});
  }
  Future<List<dynamic>> supplierInvoices() => api.get<List<dynamic>>('/cafe/supplier-invoices');
  Future<void> createSupplierInvoice(Map<String, dynamic> body) => api.post<Map<String, dynamic>>('/cafe/supplier-invoices', body: body);
  Future<void> paySupplierInvoice(String id, Map<String, dynamic> body) => api.post<Map<String, dynamic>>('/cafe/supplier-invoices/$id/payments', body: body);
  Future<List<dynamic>> expiring() => api.get<List<dynamic>>('/cafe/stock/expiring', query: {'days': 14});

  // Books
  Future<List<dynamic>> trialBalance(String from, String to) => api.get<List<dynamic>>('/cafe/reports/trial-balance', query: {'from': from, 'to': to});
  Future<Map<String, dynamic>> balanceSheet(String asOf) => api.get<Map<String, dynamic>>('/cafe/reports/balance-sheet', query: {'asOf': asOf});
  Future<List<dynamic>> journal() => api.get<List<dynamic>>('/cafe/journal-entries');
  Future<void> reverseEntry(int id, String reason) => api.post<Map<String, dynamic>>('/cafe/journal-entries/$id/reverse', body: {'reason': reason});
  Future<List<dynamic>> periods() => api.get<List<dynamic>>('/cafe/financial-periods');
  Future<void> closePeriod(int id) => api.post<Map<String, dynamic>>('/cafe/financial-periods/$id/close');
  Future<List<dynamic>> registers() => api.get<List<dynamic>>('/cafe/cash-registers');
  Future<void> createRegister(String name) => api.post<Map<String, dynamic>>('/cafe/cash-registers', body: {'name': name});
  Future<void> openRegister(String id, String float) => api.post<Map<String, dynamic>>('/cafe/cash-registers/$id/open', body: {'floatAmount': float});
  Future<Map<String, dynamic>> closeRegister(String sessionId, String counted) => api.post<Map<String, dynamic>>('/cafe/cash-register-sessions/$sessionId/close', body: {'counted': counted});
  Future<List<dynamic>> payroll() => api.get<List<dynamic>>('/cafe/payroll');
  Future<void> createPayroll(Map<String, dynamic> body) => api.post<Map<String, dynamic>>('/cafe/payroll', body: body);
  Future<void> payPayroll(String id, String method, String paidOn) => api.post<Map<String, dynamic>>('/cafe/payroll/$id/pay', body: {'paidOn': paidOn, 'method': method});

  // People and marketing
  Future<List<dynamic>> attendance() => api.get<List<dynamic>>('/cafe/attendance');
  Future<void> clockIn() => api.post<Map<String, dynamic>>('/cafe/attendance/clock-in');
  Future<void> clockOut() => api.post<Map<String, dynamic>>('/cafe/attendance/clock-out');
  Future<List<dynamic>> promotions() => api.get<List<dynamic>>('/cafe/promotions');
  Future<void> createPromotion(Map<String, dynamic> body) => api.post<Map<String, dynamic>>('/cafe/promotions', body: body);
  Future<Map<String, dynamic>?> loyalty() => api.get<Map<String, dynamic>?>('/cafe/loyalty-program');
  Future<void> saveLoyalty(Map<String, dynamic> body) => api.put<Map<String, dynamic>>('/cafe/loyalty-program', body: body);
  Future<void> replyReview(String id, String text) => api.post<Map<String, dynamic>>('/cafe/reviews/$id/reply', body: {'text': text});
  Future<List<dynamic>> notifications() => api.get<List<dynamic>>('/notifications');
  Future<void> markNotificationRead(String id) => api.post<Map<String, dynamic>>('/notifications/$id/read');

  Future<Map<String, dynamic>> theme() => api.get<Map<String, dynamic>>('/cafe/theme');
  Future<void> saveTheme(Map<String, dynamic> body) => api.put<Map<String, dynamic>>('/cafe/theme', body: body);
  Future<Map<String, dynamic>> settings() => api.get<Map<String, dynamic>>('/cafe/settings');
  Future<void> saveSettings(Map<String, dynamic> body) => api.patch<Map<String, dynamic>>('/cafe/settings', body: body);
  Future<List<dynamic>> tickets() => api.get<List<dynamic>>('/cafe/support-tickets');
  Future<void> createTicket(String subject, String body) => api.post<Map<String, dynamic>>('/cafe/support-tickets', body: {'subject': subject, 'body': body});
}
