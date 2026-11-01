import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'package:shared_localization/shared_localization.dart';
import 'package:shared_network/shared_network.dart';
import '../core/owner_repository.dart';
import '../core/save_stub.dart' if (dart.library.js_interop) '../core/save_web.dart';

OwnerRepository get _r => GetIt.I<OwnerRepository>();
String _s(Object? v) => v?.toString() ?? '';
String _when(BuildContext c, Object? v) => v == null ? '' : c.dates.dateTime(DateTime.parse(v.toString()));
String _iso(DateTime d) => d.toIso8601String().substring(0, 10);
(String, String) _thisMonth() { final n = DateTime.now(); return (_iso(DateTime(n.year, n.month)), _iso(n.add(const Duration(days: 1)))); }

/// Returns the uploaded asset's id. The server re-checks the file's real type and size.
Future<String?> _pickAndUpload(BuildContext c, String kind) async {
  final picked = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
  final file = picked?.files.single;
  final Uint8List? bytes = file?.bytes;
  if (file == null || bytes == null) return null;
  return _r.upload(bytes, file.name, kind);
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (from, to) = _thisMonth();
    return LoadView<Map<String, dynamic>>(
      load: () => _r.analytics(from, to),
      builder: (c, d, reload) {
        final currency = _s(d['currency']);
        String m(Object? v) => c.money.formatAmount(_s(v ?? '0'), currency);
        final top = (d['topProducts'] as List).cast<Map<dynamic, dynamic>>();
        final hours = (d['peakHours'] as List).cast<Map<dynamic, dynamic>>();
        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(padding: const EdgeInsets.all(Space.md), children: [
            StatGrid(children: [
              StatCard(label: l.revenue, value: m(d['revenue']), icon: Icons.payments_outlined),
              StatCard(label: l.ordersCount, value: c.dates.number(d['orders'] as num), icon: Icons.receipt_long),
              StatCard(label: l.averageOrder, value: m(d['averageOrderValue']), icon: Icons.show_chart),
              StatCard(label: l.cancellationRate, value: d['cancellationRate'] == null ? '–' : '${d['cancellationRate']}%', icon: Icons.cancel_outlined),
            ]),
            const SizedBox(height: Space.md),
            BarList(title: l.topProducts, rows: [for (final t in top) (_s(t['name']), double.parse(_s(t['quantity'])), _s(t['quantity']))]),
            const SizedBox(height: Space.md),
            BarList(title: l.peakHours, rows: [for (final h in hours) ('${_s(h['local_hour']).padLeft(2, '0')}:00', double.parse(_s(h['orders'])), _s(h['orders']))]),
          ]),
        );
      },
    );
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  StreamSubscription<RealtimeEvent>? _sub;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    final rt = GetIt.I<RealtimeClient>();
    rt.connect(token: _r.api.tokens.accessToken);
    _sub = rt.events.listen((e) { if (mounted && (e.type.startsWith('order.') || e.type.startsWith('payment.'))) setState(() => _generation++); });
  }

  @override
  void dispose() { _sub?.cancel(); GetIt.I<RealtimeClient>().disconnect(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return CrudPage(
      key: ValueKey(_generation),
      load: () => _r.orders(),
      columns: [
        CrudColumn('#', (r) => _s(r['order_number'])),
        CrudColumn(l.tableNumber, (r) => _s(r['table_number'])),
        CrudColumn(l.status, (r) => l.orderStatus(_s(r['status']))),
        CrudColumn(l.payPaid, (r) => l.paymentStatus(_s(r['payment_status']))),
        CrudColumn(l.total, (r) => context.money.formatAmount(_s(r['total_amount']), _s(r['currency_code']))),
        CrudColumn(l.date, (r) => _when(context, r['placed_at'])),
      ],
      actions: [
        RowAction(l.acceptOrder, Icons.check, (_, r) => _r.orderStatus(r['public_id'] as String, 'accepted'), visible: (r) => r['status'] == 'placed'),
        RowAction(l.markServed, Icons.room_service, (_, r) => _r.orderStatus(r['public_id'] as String, 'served'), visible: (r) => r['status'] == 'ready'),
        RowAction(l.complete, Icons.done_all, (_, r) => _r.orderStatus(r['public_id'] as String, 'completed'), visible: (r) => r['status'] == 'served' && r['payment_status'] == 'paid'),
        RowAction(l.createPaymentLink, Icons.link, (c, r) async {
          final url = await _r.paymentLink(r['public_id'] as String);
          if (!c.mounted) return;
          await showDialog<void>(context: c, builder: (d) => AlertDialog(title: Text(l.paymentLink), content: SelectableText(url), actions: [FilledButton(onPressed: () => Navigator.pop(d), child: Text(l.close))]));
        }, visible: (r) => ['unpaid', 'partially_paid'].contains(r['payment_status']) && r['status'] != 'cancelled'),
        RowAction(l.confirmCash, Icons.payments, (c, r) async {
          final v = await showFormDialog(c, title: l.confirmCash, fields: [CrudField('amount', '${l.amount} (${l.balance})', number: true, required: false, initial: (double.parse(_s(r['total_amount'])) - double.parse(_s(r['paid_amount']))).toStringAsFixed(2))]);
          if (v != null) await _r.confirmCash(r['public_id'] as String, amount: (v['amount'] ?? '').isEmpty ? null : v['amount']);
        }, visible: (r) => ['unpaid', 'partially_paid'].contains(r['payment_status']) && r['status'] != 'cancelled'),
        RowAction(l.refund, Icons.undo, (c, r) async {
          final pays = await _r.payments(orderId: r['public_id'] as String);
          if (pays.isEmpty || !c.mounted) return;
          final v = await showFormDialog(c, title: l.refund, fields: [CrudField('amount', l.amount, number: true), CrudField('reason', l.reason)]);
          if (v == null) return;
          final refundId = await _r.requestRefund((pays.first as Map)['public_id'] as String, v['amount']!, v['reason']!);
          try {
            await _r.approveRefund(refundId);
          } on ApiFailure catch (f) {
            // A cashier may request but not approve: separating the two is the control.
            if (f.status != 403) rethrow;
            if (c.mounted) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(l.refundRequested)));
          }
        }, visible: (r) => ['paid', 'partially_refunded', 'partially_paid'].contains(r['payment_status'])),
        RowAction(l.splitBill, Icons.call_split, (c, r) async {
          final v = await showFormDialog(c, title: l.splitBill, fields: [CrudField('parts', l.numberOfParts, number: true, initial: '2')]);
          if (v == null) return;
          final out = await _r.splitBill(r['public_id'] as String, int.parse(v['parts']!));
          if (!c.mounted) return;
          final bills = (out['bills'] as List).cast<Map<dynamic, dynamic>>();
          await showDialog<void>(context: c, builder: (d) => AlertDialog(title: Text(l.splitBill), content: Column(mainAxisSize: MainAxisSize.min, children: [for (final b in bills) Text(c.money.formatAmount(_s((b['amount'] as Map)['amount']), _s((b['amount'] as Map)['currency'])))]), actions: [FilledButton(onPressed: () => Navigator.pop(d), child: Text(l.close))]));
        }, visible: (r) => ['unpaid', 'partially_paid'].contains(r['payment_status']) && r['status'] != 'cancelled'),
        RowAction(l.transferTable, Icons.swap_horiz, (c, r) async {
          final tables = (await _r.tables()).cast<Map<dynamic, dynamic>>();
          if (!c.mounted) return;
          final v = await showFormDialog(c, title: l.transferTable, fields: [CrudField('tableId', l.tableNumber, options: [for (final t in tables) (_s(t['public_id']), _s(t['table_number']))]), CrudField('reason', l.reason)]);
          if (v != null) await _r.transfer(r['public_id'] as String, v['tableId']!, v['reason']!);
        }, visible: (r) => !['completed', 'cancelled'].contains(r['status'])),
        RowAction(l.cancelOrder, Icons.cancel, (c, r) async {
          final v = await showFormDialog(c, title: l.cancelOrder, fields: [CrudField('reason', l.reason)]);
          if (v != null) await _r.orderStatus(r['public_id'] as String, 'cancelled', reason: v['reason']);
        }, visible: (r) => !['served', 'completed', 'cancelled'].contains(r['status'])),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs(this.tabs);
  final List<(String, Widget)> tabs;
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: tabs.length,
        child: Column(children: [
          TabBar(isScrollable: true, tabs: [for (final t in tabs) Tab(text: t.$1)]),
          Expanded(child: TabBarView(children: [for (final t in tabs) t.$2])),
        ]),
      );
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key, required this.defaultLanguage});
  final String defaultLanguage;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Tabs([
      (l.products, _Products(language: defaultLanguage)),
      (l.categories, CrudPage(
        load: _r.categories,
        columns: [CrudColumn(l.name, (r) => (r['translations'] as List).map((t) => '${t['language']}: ${t['name']}').join(' · ')), CrudColumn(l.status, (r) => r['isActive'] == true ? 'active' : 'inactive', status: true)],
        createFields: [CrudField('name', l.name)],
        createLabel: l.newCategory,
        onCreate: (_, v) => _r.createCategory(defaultLanguage, v['name']!),
        actions: [RowAction(l.delete, Icons.delete_outline, (_, r) => _r.deleteCategory(r['publicId'] as String))],
      )),
      (l.tax, CrudPage(
        load: _r.taxCategories,
        columns: [CrudColumn(l.code, (r) => _s(r['code'])), CrudColumn(l.name, (r) => _s(r['name'])), CrudColumn(l.tax, (r) => (r['rates'] as List).map((x) => '${x['displayName']} ${x['ratePercent']}%').join(', '))],
        createFields: [CrudField('code', l.code), CrudField('name', l.name)],
        onCreate: (_, v) => _r.createTaxCategory(v['code']!, v['name']!),
        actions: [
          RowAction(l.add, Icons.percent, (c, r) async {
            final v = await showFormDialog(c, title: l.tax, fields: [CrudField('componentCode', l.code), CrudField('displayName', l.name), CrudField('ratePercent', l.percent, number: true), CrudField('appliesTo', l.tax, options: const [('always', 'always'), ('intra_region', 'CGST + SGST'), ('inter_region', 'IGST')])]);
            if (v != null) await _r.addTaxRate(r['code'] as String, {...v, 'validFrom': _iso(DateTime.now())});
          }),
        ],
      )),
    ]);
  }
}

class _Products extends StatelessWidget {
  const _Products({required this.language});
  final String language;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return LoadView<Map<String, dynamic>>(
      load: _r.menu,
      isEmpty: (_) => false,
      builder: (c, menu, reload) {
        final categories = (menu['categories'] as List).cast<Map<dynamic, dynamic>>();
        return CrudPage(
          load: () async => (await _r.menu())['products'] as List<dynamic>,
          columns: [
            CrudColumn(l.name, (r) => _s(r['name'])),
            CrudColumn(l.price, (r) => c.money.formatAmount(_s((r['price'] as Map)['amount']), _s((r['price'] as Map)['currency']))),
            CrudColumn(l.status, (r) => r['isOutOfStock'] == true ? l.outOfStock : l.statusReady),
          ],
          createLabel: l.newProduct,
          createFields: categories.isEmpty ? null : [
            CrudField('name', l.name),
            CrudField('categoryId', l.category, options: [for (final x in categories) (_s(x['publicId']), _s(x['name']))]),
            CrudField('basePrice', l.price, number: true),
            CrudField('dietaryClass', l.veg, options: [('veg', l.veg), ('non_veg', l.nonVeg), ('egg', l.egg), ('vegan', l.vegan), ('not_applicable', l.notAvailable)]),
            CrudField('taxCategoryId', l.tax, required: false),
          ],
          onCreate: (_, v) => _r.createProduct({
            'categoryId': v['categoryId'], 'basePrice': v['basePrice'], 'dietaryClass': v['dietaryClass'], if ((v['taxCategoryId'] ?? '').isNotEmpty) 'taxCategoryId': v['taxCategoryId'],
            'translations': [{'language': language, 'name': v['name']}],
          }),
          actions: [
            RowAction(l.language, Icons.translate, (c, r) async {
              final langs = [for (final loc in supportedAppLocales) (loc.languageCode, loc.languageCode)];
              final v = await showFormDialog(c, title: _s(r['name']), fields: [CrudField('language', l.language, options: langs), CrudField('name', l.name), CrudField('description', l.notes, required: false)]);
              if (v != null) await _r.updateProduct(r['publicId'] as String, {'translations': [{'language': v['language'], 'name': v['name'], if ((v['description'] ?? '').isNotEmpty) 'description': v['description']}]});
            }),
            RowAction(l.addVariant, Icons.straighten, (c, r) async {
              final v = await showFormDialog(c, title: l.addVariant, fields: [CrudField('name', l.optionName), CrudField('price', l.price, number: true)]);
              if (v != null) await _r.addVariant(r['publicId'] as String, language, v['name']!, v['price']!);
            }),
            RowAction(l.addExtras, Icons.add_circle_outline, (c, r) async {
              final v = await showFormDialog(c, title: l.addExtras, fields: [CrudField('group', l.extras, initial: l.extras), CrudField('name', l.optionName), CrudField('price', l.price, number: true)]);
              if (v != null) await _r.addExtras(r['publicId'] as String, language, v['group']!, v['name']!, v['price']!);
            }),
            RowAction(l.uploadImage, Icons.image_outlined, (c, r) async {
              final asset = await _pickAndUpload(c, 'product_image');
              if (asset != null) await _r.addProductImage(r['publicId'] as String, asset);
            }),
            RowAction(l.recipe, Icons.science_outlined, (c, r) async {
              final ingredients = (await _r.stock()).cast<Map<dynamic, dynamic>>();
              if (!c.mounted) return;
              final v = await showFormDialog(c, title: l.recipe, fields: [CrudField('ingredient', l.ingredients, options: [for (final i in ingredients) (_s(i['public_id']), '${i['name']} (${i['unit_code']})')]), CrudField('quantity', l.quantity, number: true)]);
              if (v != null) await _r.addRecipeLine(r['publicId'] as String, v['ingredient']!, v['quantity']!);
            }),
            RowAction(l.routeToStation, Icons.soup_kitchen_outlined, (c, r) async {
              final stations = (await _r.stations()).cast<Map<dynamic, dynamic>>();
              if (!c.mounted) return;
              final v = await showFormDialog(c, title: l.routeToStation, fields: [CrudField('station', l.stations, options: [for (final t in stations) (_s(t['public_id']), _s(t['name']))])]);
              if (v != null) await _r.routeProduct(r['publicId'] as String, v['station']!);
            }),
            RowAction(l.outOfStock, Icons.remove_shopping_cart, (_, r) => _r.updateProduct(r['publicId'] as String, {'isOutOfStock': r['isOutOfStock'] != true})),
            RowAction(l.delete, Icons.delete_outline, (_, r) => _r.deleteProduct(r['publicId'] as String)),
          ],
        );
      },
    );
  }
}

class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  Future<void> _showQr(BuildContext c, Map<String, dynamic> q, String id) async {
    final l = c.l10n;
    final png = base64Decode((q['png'] as String).split(',').last);
    await showDialog<void>(context: c, builder: (d) => AlertDialog(
      title: Text(l.welcomeTable(_s(q['tableNumber']))),
      content: Column(mainAxisSize: MainAxisSize.min, children: [Image.memory(png, width: 280, height: 280), SelectableText(_s(q['url']))]),
      actions: [
        TextButton(onPressed: () => saveBytes(png, 'table-${q['tableNumber']}.png', 'image/png'), child: Text(l.qrCode)),
        TextButton(onPressed: () async { Navigator.pop(d); final fresh = await _r.regenerateQr(id); if (c.mounted) await _showQr(c, fresh, id); }, child: Text(l.regenerateQr)),
        FilledButton(onPressed: () => Navigator.pop(d), child: Text(l.close)),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Tabs([
      (l.tables, CrudPage(
        load: _r.tables,
        columns: [CrudColumn(l.tableNumber, (r) => _s(r['table_number'])), CrudColumn(l.capacity, (r) => _s(r['capacity'])), CrudColumn(l.status, (r) => _s(r['status']), status: true)],
        createFields: [CrudField('number', l.tableNumber), CrudField('capacity', l.capacity, number: true, initial: '4')],
        onCreate: (_, v) => _r.createTable(v['number']!, int.parse(v['capacity']!)),
        actions: [
          RowAction(l.qrCode, Icons.qr_code_2, (c, r) async { final id = r['public_id'] as String; final q = await _r.qr(id); if (c.mounted) await _showQr(c, q, id); }),
          RowAction(l.delete, Icons.delete_outline, (_, r) => _r.deleteTable(r['public_id'] as String)),
        ],
      )),
      (l.callStaff, CrudPage(
        load: _r.serviceRequests,
        columns: [CrudColumn(l.tableNumber, (r) => _s(r['table_number'])), CrudColumn(l.action, (r) => _s(r['request_type'])), CrudColumn(l.date, (r) => _when(context, r['created_at']))],
        actions: [RowAction(l.complete, Icons.check, (_, r) => _r.resolveRequest(r['public_id'] as String))],
      )),
      (l.stations, CrudPage(
        load: _r.stations,
        columns: [CrudColumn(l.name, (r) => _s(r['name'])), CrudColumn(l.status, (r) => r['is_active'] == 1 ? 'active' : 'inactive', status: true)],
        createFields: [CrudField('name', l.name)],
        onCreate: (_, v) => _r.createStation(v['name']!),
      )),
      (l.reservations, CrudPage(
        load: _r.reservations,
        columns: [CrudColumn(l.name, (r) => _s(r['guest_name'])), CrudColumn(l.partySize, (r) => _s(r['party_size'])), CrudColumn(l.date, (r) => _when(context, r['starts_at'])), CrudColumn(l.status, (r) => _s(r['status']), status: true)],
        createFields: [CrudField('guestName', l.name), CrudField('partySize', l.partySize, number: true), CrudField('hours', l.date, number: true, initial: '24')],
        onCreate: (_, v) { final start = DateTime.now().toUtc().add(Duration(hours: int.parse(v['hours']!))); return _r.createReservation({'guestName': v['guestName'], 'partySize': int.parse(v['partySize']!), 'startsAt': start.toIso8601String(), 'endsAt': start.add(const Duration(hours: 2)).toIso8601String()}); },
      )),
    ]);
  }
}

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Tabs([(l.staff, _staffList(context)), (l.attendance, CrudPage(
      load: _r.attendance,
      header: Wrap(spacing: Space.sm, children: [
        Builder(builder: (c) => FilledButton(onPressed: () => _act(c, _r.clockIn), child: Text(l.clockIn))),
        Builder(builder: (c) => OutlinedButton(onPressed: () => _act(c, _r.clockOut), child: Text(l.clockOut))),
      ]),
      columns: [CrudColumn(l.name, (r) => _s(r['full_name'])), CrudColumn(l.clockIn, (r) => _when(context, r['clock_in_at'])), CrudColumn(l.clockOut, (r) => _when(context, r['clock_out_at']))],
    ))]);
  }

  Future<void> _act(BuildContext c, Future<void> Function() run) async {
    final l = c.l10n;
    try {
      await run();
      if (c.mounted) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(l.clockedIn)));
    } catch (e) {
      if (c.mounted) showFailure(c, e);
    }
  }

  Widget _staffList(BuildContext context) {
    final l = context.l10n;
    return CrudPage(
      load: _r.staff,
      columns: [
        CrudColumn(l.name, (r) => _s(r['full_name'])),
        CrudColumn(l.email, (r) => _s(r['email'])),
        CrudColumn(l.role, (r) => (r['roles'] as List).map((x) => x['name']).join(', ')),
        CrudColumn(l.status, (r) => _s(r['status']), status: true),
      ],
      createLabel: l.inviteStaff,
      createFields: [CrudField('fullName', l.name), CrudField('email', l.email), CrudField('roleCode', l.role, options: [('manager', l.roleManager), ('cashier', l.roleCashier), ('waiter', l.roleWaiter), ('kitchen_staff', l.roleKitchen)])],
      onCreate: (c, v) async {
        final r = await _r.invite(v);
        final token = r['invitationToken'];
        if (token != null && c.mounted) {
          await showDialog<void>(context: c, builder: (d) => AlertDialog(title: Text(l.invitationLink), content: SelectableText('$token'), actions: [FilledButton(onPressed: () => Navigator.pop(d), child: Text(l.close))]));
        }
      },
      actions: [RowAction(l.suspend, Icons.person_off, (_, r) => _r.setStaffStatus(r['public_id'] as String, 'inactive'), visible: (r) => r['status'] == 'active' && !(r['roles'] as List).any((x) => x['code'] == 'owner'))],
    );
  }
}

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Tabs([
      (l.stock, CrudPage(
        load: _r.stock,
        columns: [CrudColumn(l.name, (r) => _s(r['name'])), CrudColumn(l.quantity, (r) => '${_s(r['on_hand_quantity'] ?? '0')} ${_s(r['unit_code'])}'), CrudColumn(l.unitCost, (r) => _s(r['average_unit_cost'] ?? '0'))],
        createFields: [CrudField('name', l.ingredients), CrudField('unit', l.unit, options: const [('g', 'g'), ('kg', 'kg'), ('ml', 'ml'), ('l', 'l'), ('pc', 'pc')])],
        onCreate: (_, v) => _r.createIngredient(v['name']!, v['unit']!),
        actions: [
          RowAction(l.stockIn, Icons.add_box_outlined, (c, r) async {
            final v = await showFormDialog(c, title: l.stockIn, fields: [CrudField('quantity', l.quantity, number: true), CrudField('unitCost', l.unitCost, number: true)]);
            if (v != null) await _r.stockMove({'ingredientId': r['public_id'], 'type': 'stock_in', ...v});
          }),
          RowAction(l.delete, Icons.remove_circle_outline, (c, r) async {
            final v = await showFormDialog(c, title: l.stock, fields: [CrudField('quantity', l.quantity, number: true), CrudField('reason', l.reason)]);
            if (v != null) await _r.stockMove({'ingredientId': r['public_id'], 'type': 'wastage', ...v});
          }),
        ],
      )),
      (l.purchaseOrders, CrudPage(
        load: _r.purchaseOrders,
        columns: [CrudColumn(l.code, (r) => _s(r['po_number'])), CrudColumn(l.suppliers, (r) => _s(r['supplier'])), CrudColumn(l.total, (r) => context.money.formatAmount(_s(r['total_amount']), _s(r['currency_code']))), CrudColumn(l.status, (r) => _s(r['status']), status: true)],
        createLabel: l.newPurchaseOrder,
        createFields: const [],
        onCreate: (c, _) async {
          final suppliers = (await _r.suppliers()).cast<Map<dynamic, dynamic>>();
          final ingredients = (await _r.stock()).cast<Map<dynamic, dynamic>>();
          if (!c.mounted) return;
          final v = await showFormDialog(c, title: l.newPurchaseOrder, fields: [
            CrudField('supplier', l.suppliers, options: [for (final x in suppliers) (_s(x['public_id']), _s(x['name']))]),
            CrudField('ingredient', l.ingredients, options: [for (final x in ingredients) (_s(x['public_id']), _s(x['name']))]),
            CrudField('quantity', l.quantity, number: true), CrudField('unitCost', l.unitCost, number: true),
          ]);
          if (v != null) await _r.createPurchaseOrder(v['supplier']!, v['ingredient']!, v['quantity']!, v['unitCost']!);
        },
        actions: [RowAction(l.receiveGoods, Icons.move_to_inbox, (_, r) => _r.receiveAll(r['public_id'] as String), visible: (r) => ['sent', 'partially_received'].contains(r['status']))],
      )),
      (l.supplierInvoices, CrudPage(
        load: _r.supplierInvoices,
        columns: [CrudColumn(l.invoiceNumber, (r) => _s(r['supplier_invoice_number'])), CrudColumn(l.suppliers, (r) => _s(r['supplier'])), CrudColumn(l.total, (r) => context.money.formatAmount(_s(r['total_amount']), _s(r['currency_code']))), CrudColumn(l.payPaid, (r) => context.money.formatAmount(_s(r['paid_amount']), _s(r['currency_code'])))],
        createFields: const [],
        onCreate: (c, _) async {
          final suppliers = (await _r.suppliers()).cast<Map<dynamic, dynamic>>();
          if (!c.mounted) return;
          final v = await showFormDialog(c, title: l.supplierInvoices, fields: [CrudField('supplierId', l.suppliers, options: [for (final x in suppliers) (_s(x['public_id']), _s(x['name']))]), CrudField('number', l.invoiceNumber), CrudField('subtotal', l.subtotal, number: true), CrudField('tax', l.tax, number: true, required: false)]);
          if (v != null) await _r.createSupplierInvoice({'supplierId': v['supplierId'], 'number': v['number'], 'subtotal': v['subtotal'], if ((v['tax'] ?? '').isNotEmpty) 'tax': v['tax'], 'invoiceDate': _iso(DateTime.now())});
        },
        actions: [RowAction(l.recordPayment, Icons.payments, (c, r) async {
          final v = await showFormDialog(c, title: l.recordPayment, fields: [CrudField('amount', l.amount, number: true), CrudField('method', l.paymentMethods, options: const [('cash', 'cash'), ('card', 'card'), ('upi', 'upi')])]);
          if (v != null) await _r.paySupplierInvoice(r['public_id'] as String, {'amount': v['amount'], 'methodCode': v['method'], 'paidOn': _iso(DateTime.now())});
        }, visible: (r) => r['status'] != 'paid')],
      )),
      (l.expiringStock, CrudPage(load: _r.expiring, columns: [CrudColumn(l.name, (r) => _s(r['name'])), CrudColumn(l.quantity, (r) => _s(r['remaining_quantity'])), CrudColumn(l.date, (r) => _s(r['expires_on']).split('T').first)])),
      (l.suppliers, CrudPage(
        load: _r.suppliers,
        columns: [CrudColumn(l.name, (r) => _s(r['name'])), CrudColumn(l.email, (r) => _s(r['email'])), CrudColumn(l.phone, (r) => _s(r['phone']))],
        createFields: [CrudField('name', l.name), CrudField('phone', l.phone, required: false)],
        onCreate: (_, v) => _r.createSupplier(v['name']!, v['phone']),
      )),
    ]);
  }
}

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (from, to) = _thisMonth();
    Future<void> export(BuildContext c, String type, String format) async {
      try {
        saveBytes(await _r.export(type, format, from, to), '$type-$from-$to.$format', format == 'pdf' ? 'application/pdf' : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      } catch (e) {
        if (c.mounted) showFailure(c, e);
      }
    }
    return _Tabs([
      (l.sales, LoadView<Map<String, dynamic>>(
        load: () => _r.sales(from, to),
        isEmpty: (d) => (d['rows'] as List).isEmpty,
        empty: EmptyState(message: l.noDataYet),
        builder: (c, d, _) {
          final cur = _s(d['currency']);
          final rows = (d['rows'] as List).cast<Map<dynamic, dynamic>>();
          return ListView(padding: const EdgeInsets.all(Space.md), children: [
            Wrap(spacing: Space.sm, children: [OutlinedButton(onPressed: () => export(c, 'sales', 'xlsx'), child: Text(l.exportExcel)), OutlinedButton(onPressed: () => export(c, 'sales', 'pdf'), child: Text(l.exportPdf))]),
            const SizedBox(height: Space.md),
            Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
              columns: [DataColumn(label: Text(l.date)), DataColumn(label: Text(l.ordersCount)), DataColumn(label: Text(l.subtotal)), DataColumn(label: Text(l.discount)), DataColumn(label: Text(l.tax)), DataColumn(label: Text(l.refund)), DataColumn(label: Text(l.total))],
              rows: [for (final x in rows) DataRow(cells: [DataCell(Text(_s(x['period']))), DataCell(Text(_s(x['orders']))), for (final k in ['gross_sales', 'discounts', 'tax_collected', 'refunds', 'net_sales']) DataCell(Text(c.money.formatAmount(_s(x[k]), cur)))])],
            ))),
          ]);
        },
      )),
      (l.profitLoss, LoadView<Map<String, dynamic>>(
        load: () => _r.pnl(from, to),
        isEmpty: (_) => false,
        builder: (c, d, _) {
          final cur = _r.currency;
          String m(Object? v) => c.money.formatAmount(_s(v), cur);
          Widget section(String title, List<dynamic> rows, Object? total) => Card(child: Padding(padding: const EdgeInsets.all(Space.md), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(title, style: Theme.of(c).textTheme.titleMedium),
                for (final r in rows.cast<Map<dynamic, dynamic>>()) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Flexible(child: Text(_s(r['name']))), Text(m(r['amount']))]),
                const Divider(),
                Align(alignment: AlignmentDirectional.centerEnd, child: Text(m(total), style: const TextStyle(fontWeight: FontWeight.w700))),
              ])));
          return ListView(padding: const EdgeInsets.all(Space.md), children: [
            Wrap(spacing: Space.sm, children: [OutlinedButton(onPressed: () => export(c, 'pnl', 'xlsx'), child: Text(l.exportExcel)), OutlinedButton(onPressed: () => export(c, 'pnl', 'pdf'), child: Text(l.exportPdf))]),
            const SizedBox(height: Space.md),
            section(l.totalRevenue, d['revenue'] as List, d['totalRevenue']),
            const SizedBox(height: Space.md),
            section(l.totalExpenses, d['expenses'] as List, d['totalExpenses']),
            const SizedBox(height: Space.md),
            StatCard(label: l.netProfit, value: m(d['netProfit'])),
          ]);
        },
      )),
      (l.expenses, LoadView<List<dynamic>>(
        load: _r.expenseCategories,
        isEmpty: (_) => false,
        builder: (c, cats, reload) => CrudPage(
          load: _r.expenses,
          columns: [CrudColumn(l.category, (r) => _s(r['category'])), CrudColumn(l.amount, (r) => c.money.formatAmount(_s(r['amount']), _s(r['currency_code']))), CrudColumn(l.date, (r) => _s(r['expense_date']).split('T').first), CrudColumn(l.notes, (r) => _s(r['description']))],
          createFields: cats.isEmpty ? [CrudField('newCategory', l.category)] : [CrudField('categoryId', l.category, options: [for (final x in cats.cast<Map<dynamic, dynamic>>()) (_s(x['id']), _s(x['name']))]), CrudField('amount', l.amount, number: true), CrudField('description', l.notes, required: false)],
          onCreate: (_, v) async {
            if (v['newCategory'] != null) { await _r.createExpenseCategory(v['newCategory']!); await reload(); return; }
            await _r.createExpense({'categoryId': int.parse(v['categoryId']!), 'amount': v['amount'], 'date': _iso(DateTime.now()), if ((v['description'] ?? '').isNotEmpty) 'description': v['description']});
          },
        ),
      )),
      (l.trialBalance, CrudPage(
        load: () => _r.trialBalance('2000-01-01', to),
        columns: [CrudColumn(l.code, (r) => _s(r['code'])), CrudColumn(l.name, (r) => _s(r['name'])), CrudColumn(l.debit, (r) => context.money.formatAmount(_s(r['debit']), _r.currency)), CrudColumn(l.credit, (r) => context.money.formatAmount(_s(r['credit']), _r.currency))],
      )),
      (l.balanceSheet, LoadView<Map<String, dynamic>>(
        load: () => _r.balanceSheet(to),
        isEmpty: (_) => false,
        builder: (c, d, _) {
          String m(Object? v) => c.money.formatAmount(_s(v), _r.currency);
          Widget section(String title, List<dynamic> rows, Object? total) => Card(child: Padding(padding: const EdgeInsets.all(Space.md), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(title, style: Theme.of(c).textTheme.titleMedium),
                for (final r in rows.cast<Map<dynamic, dynamic>>()) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Flexible(child: Text(_s(r['name']))), Text(m(r['amount']))]),
                const Divider(),
                Align(alignment: AlignmentDirectional.centerEnd, child: Text(m(total), style: const TextStyle(fontWeight: FontWeight.w700))),
              ])));
          return ListView(padding: const EdgeInsets.all(Space.md), children: [section(l.assets, d['assets'] as List, d['totalAssets']), const SizedBox(height: Space.md), section(l.liabilities, d['liabilities'] as List, d['totalLiabilities']), const SizedBox(height: Space.md), section(l.equity, d['equity'] as List, d['totalEquity'])]);
        },
      )),
      (l.journal, CrudPage(
        load: _r.journal,
        columns: [CrudColumn(l.date, (r) => _s(r['entry_date']).split('T').first), CrudColumn(l.notes, (r) => _s(r['memo'])), CrudColumn(l.amount, (r) => (r['lines'] as List).map((x) => '${x['code']} ${x['debit_amount']}/${x['credit_amount']}').join(', '))],
        actions: [RowAction(l.reverse, Icons.undo, (c, r) async {
          final v = await showFormDialog(c, title: l.reverse, fields: [CrudField('reason', l.reason)]);
          if (v != null) await _r.reverseEntry(r['id'] as int, v['reason']!);
        }, visible: (r) => r['reversal_of_entry_id'] == null)],
      )),
      (l.periods, CrudPage(
        load: _r.periods,
        columns: [CrudColumn(l.name, (r) => _s(r['name'])), CrudColumn(l.status, (r) => _s(r['status']), status: true)],
        actions: [RowAction(l.closePeriod, Icons.lock_outline, (_, r) => _r.closePeriod(r['id'] as int), visible: (r) => r['status'] == 'open')],
      )),
      (l.cashRegisters, CrudPage(
        load: _r.registers,
        columns: [CrudColumn(l.name, (r) => _s(r['name'])), CrudColumn(l.status, (r) => r['openSession'] == null ? 'closed' : 'open', status: true)],
        createFields: [CrudField('name', l.name)],
        onCreate: (_, v) => _r.createRegister(v['name']!),
        actions: [
          RowAction(l.openRegister, Icons.lock_open, (c, r) async {
            final v = await showFormDialog(c, title: l.openRegister, fields: [CrudField('float', l.openingFloat, number: true)]);
            if (v != null) await _r.openRegister(r['public_id'] as String, v['float']!);
          }, visible: (r) => r['openSession'] == null),
          RowAction(l.closeRegister, Icons.lock, (c, r) async {
            final v = await showFormDialog(c, title: l.closeRegister, fields: [CrudField('counted', l.countedCash, number: true)]);
            if (v == null) return;
            final out = await _r.closeRegister((r['openSession'] as Map)['public_id'] as String, v['counted']!);
            if (!c.mounted) return;
            await showDialog<void>(context: c, builder: (d) => AlertDialog(title: Text(l.closeRegister), content: Text('${l.expectedCash}: ${c.money.formatAmount(_s(out['expected']), _r.currency)}\n${l.variance}: ${c.money.formatAmount(_s(out['variance']), _r.currency)}'), actions: [FilledButton(onPressed: () => Navigator.pop(d), child: Text(l.close))]));
          }, visible: (r) => r['openSession'] != null),
        ],
      )),
      (l.payroll, CrudPage(
        load: _r.payroll,
        columns: [CrudColumn(l.name, (r) => _s(r['full_name'])), CrudColumn(l.grossPay, (r) => context.money.formatAmount(_s(r['gross_amount']), _s(r['currency_code']))), CrudColumn(l.total, (r) => context.money.formatAmount(_s(r['net_amount']), _s(r['currency_code']))), CrudColumn(l.status, (r) => _s(r['status']), status: true)],
        createFields: const [],
        onCreate: (c, _) async {
          final staff = (await _r.staff()).cast<Map<dynamic, dynamic>>();
          if (!c.mounted) return;
          final v = await showFormDialog(c, title: l.payroll, fields: [CrudField('staffId', l.staff, options: [for (final x in staff) (_s(x['public_id']), _s(x['full_name']))]), CrudField('gross', l.grossPay, number: true), CrudField('deductions', l.deductions, number: true, required: false)]);
          if (v != null) await _r.createPayroll({'staffId': v['staffId'], 'gross': v['gross'], if ((v['deductions'] ?? '').isNotEmpty) 'deductions': v['deductions'], 'periodStart': from, 'periodEnd': to});
        },
        actions: [RowAction(l.markPaid, Icons.check, (c, r) async {
          final v = await showFormDialog(c, title: l.markPaid, fields: [CrudField('method', l.paymentMethods, options: const [('bank', 'bank'), ('cash', 'cash')])]);
          if (v != null) await _r.payPayroll(r['public_id'] as String, v['method']!, _iso(DateTime.now()));
        }, visible: (r) => r['status'] != 'paid')],
      )),
      (l.receipt, CrudPage(load: _r.invoices, columns: [CrudColumn(l.code, (r) => _s(r['invoice_number'])), CrudColumn(l.status, (r) => _s(r['document_type'])), CrudColumn(l.total, (r) => context.money.formatAmount(_s(r['total_amount']), _s(r['currency_code']))), CrudColumn(l.date, (r) => _when(context, r['issued_at']))])),
    ]);
  }
}

class MarketingScreen extends StatelessWidget {
  const MarketingScreen({super.key, required this.language});
  final String language;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Tabs([
      (l.coupons, CrudPage(
        load: _r.coupons,
        columns: [CrudColumn(l.code, (r) => _s(r['code'])), CrudColumn(l.percent, (r) => _s(r['percent_value'] ?? r['fixed_amount'])), CrudColumn(l.quantity, (r) => _s(r['redemption_count']))],
        createFields: [CrudField('code', l.code), CrudField('percentValue', l.percent, number: true)],
        onCreate: (_, v) => _r.createCoupon({'code': v['code'], 'discountType': 'percent', 'percentValue': v['percentValue']}),
      )),
      (l.customers, CrudPage(load: _r.customers, columns: [CrudColumn(l.name, (r) => _s(r['full_name'])), CrudColumn(l.email, (r) => _s(r['email'])), CrudColumn(l.ordersCount, (r) => _s(r['total_orders']))])),
      (l.rateUs, CrudPage(load: _r.reviews, columns: [CrudColumn('#', (r) => _s(r['order_number'])), CrudColumn('★', (r) => _s(r['rating'])), CrudColumn(l.notes, (r) => _s(r['comment'])), CrudColumn(l.reply, (r) => _s(r['reply_text']))], actions: [
        RowAction(l.reply, Icons.reply, (c, r) async {
          final v = await showFormDialog(c, title: l.reply, fields: [CrudField('text', l.message)]);
          if (v != null) await _r.replyReview(r['public_id'] as String, v['text']!);
        }),
      ])),
      (l.promotions, CrudPage(
        load: _r.promotions,
        columns: [CrudColumn(l.name, (r) => _s(r['title'])), CrudColumn(l.percent, (r) => _s(r['percentValue'] ?? r['fixedAmount'])), CrudColumn(l.status, (r) => r['isActive'] == true ? 'active' : 'inactive', status: true)],
        createFields: const [],
        onCreate: (c, _) async {
          final menu = await _r.menu();
          if (!c.mounted) return;
          final categories = (menu['categories'] as List).cast<Map<dynamic, dynamic>>();
          final v = await showFormDialog(c, title: l.promotions, fields: [CrudField('title', l.name), CrudField('percentValue', l.percent, number: true), CrudField('category', l.category, options: [for (final x in categories) (_s(x['publicId']), _s(x['name']))])]);
          if (v != null) await _r.createPromotion({'discountType': 'percent', 'percentValue': v['percentValue'], 'categoryIds': [v['category']], 'translations': [{'language': language, 'title': v['title']}]});
        },
      )),
      (l.loyalty, LoadView<Map<String, dynamic>?>(
        load: _r.loyalty,
        isEmpty: (_) => false,
        builder: (c, d, reload) => ListView(padding: const EdgeInsets.all(Space.md), children: [
          ListTile(title: Text(l.pointsPerUnit), trailing: Text(_s(d?['points_per_currency_unit']))),
          ListTile(title: Text(l.valuePerPoint), trailing: Text(_s(d?['currency_value_per_point']))),
          ListTile(title: Text(l.status), trailing: StatusChip(label: l.statusLabel(d?['is_active'] == 1 ? 'active' : 'inactive'), status: d?['is_active'] == 1 ? 'active' : 'inactive')),
          const SizedBox(height: Space.md),
          FilledButton(onPressed: () async {
            final v = await showFormDialog(c, title: l.loyalty, fields: [CrudField('pointsPerCurrencyUnit', l.pointsPerUnit, number: true), CrudField('currencyValuePerPoint', l.valuePerPoint, number: true), CrudField('active', l.status, options: [('true', l.stActive), ('false', l.stInactive)])]);
            if (v == null) return;
            try { await _r.saveLoyalty({'isActive': v['active'] == 'true', 'pointsPerCurrencyUnit': v['pointsPerCurrencyUnit'], 'currencyValuePerPoint': v['currencyValuePerPoint']}); await reload(); } catch (e) { if (c.mounted) showFailure(c, e); }
          }, child: Text(l.edit)),
        ]),
      )),
    ]);
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.language});
  final String language;

  Future<void> _brandUpload(BuildContext c, String kind, String field, Future<void> Function() reload) async {
    try {
      final asset = await _pickAndUpload(c, kind);
      if (asset != null) { await _r.saveTheme({field: asset}); await reload(); }
    } catch (e) {
      if (c.mounted) showFailure(c, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Tabs([
      (l.branding, LoadView<Map<String, dynamic>>(
        load: _r.theme,
        builder: (c, t, reload) => ListView(padding: const EdgeInsets.all(Space.md), children: [
          ListTile(leading: CircleAvatar(backgroundColor: hexColor(_s(t['primary_color']))), title: Text(l.primaryColor), subtitle: Text(_s(t['primary_color'])), trailing: IconButton(tooltip: l.edit, icon: const Icon(Icons.edit), onPressed: () async {
            final v = await showFormDialog(c, title: l.primaryColor, fields: [CrudField('primaryColor', '#RRGGBB', initial: _s(t['primary_color']))]);
            if (v == null) return;
            try { await _r.saveTheme(v); await reload(); } catch (e) { if (c.mounted) showFailure(c, e); }
          })),
          Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
            OutlinedButton.icon(icon: const Icon(Icons.image), label: Text(l.uploadLogo), onPressed: () => _brandUpload(c, 'logo', 'logoAssetId', reload)),
            OutlinedButton.icon(icon: const Icon(Icons.panorama), label: Text(l.uploadCover), onPressed: () => _brandUpload(c, 'cover', 'coverAssetId', reload)),
            OutlinedButton.icon(icon: const Icon(Icons.campaign), label: Text(l.banners), onPressed: () async {
              final v = await showFormDialog(c, title: l.banners, fields: [CrudField('title', l.bannerTitle)]);
              if (v == null || !c.mounted) return;
              try {
                final asset = await _pickAndUpload(c, 'banner');
                if (asset != null) await _r.createBanner(asset, language, v['title']!);
              } catch (e) {
                if (c.mounted) showFailure(c, e);
              }
            }),
          ]),
          ListTile(leading: const Icon(Icons.dashboard_customize), title: Text(l.menu), trailing: DropdownButton<String>(
            value: _s(t['menu_layout']),
            items: [DropdownMenuItem(value: 'list', child: Text(l.layoutList)), DropdownMenuItem(value: 'grid', child: Text(l.layoutGrid)), DropdownMenuItem(value: 'compact', child: Text(l.layoutCompact))],
            onChanged: (v) async { if (v != null) { await _r.saveTheme({'menuLayout': v}); await reload(); } },
          )),
        ]),
      )),
      (l.settings, LoadView<Map<String, dynamic>>(
        load: _r.settings,
        builder: (c, s, reload) => ListView(padding: const EdgeInsets.all(Space.md), children: [
          for (final (k, label) in [('pricesIncludeTax', l.setPricesIncludeTax), ('requireStaffAcceptance', l.setRequireAcceptance), ('guestOrderingEnabled', l.setGuestOrdering), ('stockDeductionEnabled', l.setStockDeduction)])
            SwitchListTile(title: Text(label), value: s[k] == true, onChanged: (v) async { await _r.saveSettings({k: v}); await reload(); }),
          ListTile(title: Text(l.setPaymentPolicy), trailing: DropdownButton<String>(
            value: _s(s['paymentPolicy']),
            items: [DropdownMenuItem(value: 'postpay', child: Text(l.policyPostpay)), DropdownMenuItem(value: 'prepay', child: Text(l.policyPrepay))],
            onChanged: (v) async { if (v != null) { await _r.saveSettings({'paymentPolicy': v}); await reload(); } },
          )),
        ]),
      )),
      (l.branches, CrudPage(
        load: _r.branches,
        columns: [CrudColumn(l.branchCode, (r) => _s(r['code'])), CrudColumn(l.name, (r) => _s(r['name'])), CrudColumn(l.city, (r) => _s(r['city'])), CrudColumn(l.status, (r) => _s(r['status']), status: true)],
        createFields: [CrudField('code', l.branchCode), CrudField('name', l.name), CrudField('addressLine1', l.address), CrudField('city', l.city)],
        onCreate: (_, v) => _r.createBranch(v),
        actions: [RowAction(l.businessHours, Icons.schedule, (c, r) async {
          final v = await showFormDialog(c, title: l.businessHours, fields: [CrudField('opens', '${l.opensAt} (HH:MM)', initial: '08:00'), CrudField('closes', '${l.closesAt} (HH:MM)', initial: '22:00')]);
          if (v != null) await _r.setHours(r['public_id'] as String, [for (var d = 0; d < 7; d++) {'weekday': d, 'opensAt': v['opens'], 'closesAt': v['closes']}]);
        })],
      )),
      (l.supportedLanguages, CrudPage(
        load: () async => (await _r.profile())['languages'] as List<dynamic>,
        columns: [CrudColumn(l.code, (r) => _s(r['code'])), CrudColumn(l.name, (r) => _s(r['native_name']))],
        createFields: [CrudField('code', l.language, options: [for (final loc in supportedAppLocales) (loc.languageCode, loc.languageCode)])],
        onCreate: (_, v) async {
          final current = ((await _r.profile())['languages'] as List).cast<Map<dynamic, dynamic>>().map((x) => _s(x['code'])).toList();
          await _r.setLanguages([...current, v['code']!]);
        },
      )),
      (l.gatewaySetup, CrudPage(
        load: _r.gatewayAccounts,
        columns: [CrudColumn(l.provider, (r) => _s(r['provider_code'])), CrudColumn(l.environment, (r) => _s(r['environment'])), CrudColumn(l.status, (r) => _s(r['status']), status: true)],
        createFields: [
          CrudField('providerCode', l.provider, options: const [('razorpay', 'Razorpay')], initial: 'razorpay'),
          CrudField('environment', l.environment, options: const [('sandbox', 'sandbox'), ('live', 'live')], initial: 'sandbox'),
          CrudField('keyId', l.apiKeyId, required: false), CrudField('keySecret', l.apiKeySecret, obscure: true), CrudField('webhookSecret', l.webhookSecret, obscure: true, required: false),
        ],
        onCreate: (c, v) async {
          final out = await _r.saveGateway({...v}..removeWhere((_, x) => x.isEmpty));
          await _r.setPaymentMethods(['cash', 'upi', 'card', 'payment_link']);
          if (c.mounted) await showDialog<void>(context: c, builder: (d) => AlertDialog(title: Text(l.webhookUrl), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [SelectableText(_s(out['webhookUrl'])), const SizedBox(height: Space.md), Text(l.pendingKeys)]), actions: [FilledButton(onPressed: () => Navigator.pop(d), child: Text(l.close))]));
        },
        actions: [RowAction(l.testConnection, Icons.wifi_tethering, (c, r) async {
          await _r.testGateway(r['public_id'] as String);
          if (c.mounted) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(l.connectionOk)));
        })],
      )),
      (l.subscription, LoadView<List<dynamic>>(
        load: () async => [await _r.subscription(), ...await _r.plans()],
        isEmpty: (_) => false,
        builder: (c, d, reload) {
          final current = d.first as Map?;
          final plans = d.skip(1).cast<Map<dynamic, dynamic>>();
          return ListView(padding: const EdgeInsets.all(Space.md), children: [
            if (current != null) ListTile(title: Text(_s(current['plan_name'])), subtitle: Text(_when(c, current['current_period_end'])), trailing: StatusChip(label: l.statusLabel(_s(current['status'])), status: _s(current['status']))),
            if (current != null) OutlinedButton(onPressed: () async { try { await _r.cancelSubscription(); await reload(); } catch (e) { if (c.mounted) showFailure(c, e); } }, child: Text(l.cancelSubscription)),
            if (plans.isEmpty && current == null) EmptyState(message: l.choosePlan),
            for (final p in plans) ListTile(
              title: Text(_s(p['name'])),
              subtitle: Text((p['prices'] as List).map((x) => '${x['interval']}: ${c.money.formatAmount(_s(x['amount']), _s(x['currency']))}').join(' · ')),
              trailing: current != null ? null : FilledButton(onPressed: () async { try { await _r.subscribe(_s(p['code']), 'monthly'); await reload(); } catch (e) { if (c.mounted) showFailure(c, e); } }, child: Text(l.choosePlan)),
            ),
          ]);
        },
      )),
      (l.support, CrudPage(
        load: _r.tickets,
        columns: [CrudColumn(l.subject, (r) => _s(r['subject'])), CrudColumn(l.status, (r) => _s(r['status']), status: true), CrudColumn(l.date, (r) => _when(context, r['created_at']))],
        createFields: [CrudField('subject', l.subject), CrudField('body', l.message)],
        onCreate: (_, v) => _r.createTicket(v['subject']!, v['body']!),
      )),
    ]);
  }
}

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (from, to) = _thisMonth();
    String m(Object? v, Object? c) => context.money.formatAmount(_s(v), _s(c));
    return _Tabs([
      (l.payments, CrudPage(
        load: () => _r.payments(),
        columns: [
          CrudColumn(l.date, (r) => _when(context, r['created_at'])),
          CrudColumn('#', (r) => _s(r['order_number'])),
          CrudColumn(l.paymentMethods, (r) => _s(r['method_code'])),
          CrudColumn(l.amount, (r) => m(r['amount'], r['currency_code'])),
          CrudColumn(l.refund, (r) => m(r['refunded_amount'], r['currency_code'])),
          CrudColumn(l.gatewayFee, (r) => r['gateway_fee_amount'] == null ? '' : m(r['gateway_fee_amount'], r['currency_code'])),
          CrudColumn(l.status, (r) => _s(r['status']), status: true),
        ],
      )),
      (l.refunds, CrudPage(
        load: _r.refunds,
        columns: [
          CrudColumn(l.date, (r) => _when(context, r['created_at'])),
          CrudColumn(l.amount, (r) => m(r['amount'], r['currency_code'])),
          CrudColumn(l.reason, (r) => _s(r['reason'])),
          CrudColumn(l.status, (r) => _s(r['status']), status: true),
        ],
        actions: [RowAction(l.approveRefund, Icons.check, (_, r) => _r.approveRefund(r['public_id'] as String), visible: (r) => r['status'] == 'requested')],
      )),
      (l.settlements, CrudPage(
        load: _r.settlements,
        header: Builder(builder: (c) => Align(alignment: AlignmentDirectional.centerStart, child: OutlinedButton.icon(icon: const Icon(Icons.sync), label: Text(l.syncSettlements), onPressed: () async {
          try {
            final now = DateTime.now().toUtc();
            await _r.syncSettlements(now.subtract(const Duration(days: 30)).toIso8601String(), now.toIso8601String());
            if (c.mounted) await c.read<LoadCubit<List<dynamic>>>().load(silent: true);
          } catch (e) {
            if (c.mounted) showFailure(c, e);
          }
        }))),
        columns: [
          CrudColumn(l.referenceLabel, (r) => _s(r['provider_settlement_ref'])),
          CrudColumn(l.date, (r) => _when(context, r['settled_at'])),
          CrudColumn(l.subtotal, (r) => m(r['gross_amount'], r['currency_code'])),
          CrudColumn(l.gatewayFee, (r) => m(r['fee_amount'], r['currency_code'])),
          CrudColumn(l.total, (r) => m(r['net_amount'], r['currency_code'])),
          CrudColumn(l.status, (r) => switch (r['status']) { 'reconciled' => l.reconciled, 'mismatch' => l.needsReview, _ => _s(r['status']) }),
        ],
      )),
      (l.paymentBreakdown, CrudPage(
        load: () async => (await _r.paymentBreakdown(from, to))['rows'] as List<dynamic>,
        columns: [
          CrudColumn(l.paymentMethods, (r) => _s(r['method_code'])),
          CrudColumn(l.provider, (r) => _s(r['provider_code'])),
          CrudColumn(l.quantity, (r) => _s(r['n'])),
          CrudColumn(l.amount, (r) => m(r['amount'], _r.currency)),
          CrudColumn(l.refund, (r) => m(r['refunded'], _r.currency)),
          CrudColumn(l.gatewayFee, (r) => m(r['fees'], _r.currency)),
        ],
      )),
    ]);
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return CrudPage(
      load: _r.notifications,
      columns: [CrudColumn(l.subject, (r) => _s(r['title'])), CrudColumn(l.message, (r) => _s(r['body'])), CrudColumn(l.date, (r) => _when(context, r['created_at']))],
      actions: [RowAction(l.confirm, Icons.done, (_, r) => _r.markNotificationRead(r['public_id'] as String), visible: (r) => r['read_at'] == null)],
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _v = <String, String>{};
  String? _country;
  bool _busy = false;
  late final Future<Map<String, dynamic>> _ref = _r.reference();

  Widget _f(String key, String label, {bool obscure = false, String? Function(String)? check}) => Padding(
        padding: const EdgeInsets.only(bottom: Space.md),
        child: TextFormField(decoration: InputDecoration(labelText: label), obscureText: obscure, onSaved: (x) => _v[key] = x?.trim() ?? '', validator: (x) => (x == null || x.trim().isEmpty) ? context.l10n.requiredField : check?.call(x)),
      );

  Future<void> _submit(List<Map<dynamic, dynamic>> countries) async {
    if (!_form.currentState!.validate() || _country == null) return;
    _form.currentState!.save();
    final c = countries.firstWhere((x) => x['code'] == _country);
    setState(() => _busy = true);
    try {
      await _r.register({
        'owner': {'email': _v['email'], 'password': _v['password'], 'fullName': _v['owner']},
        'cafe': {'name': _v['name'], 'legalName': _v['legal'], 'countryCode': _country, 'currencyCode': c['default_currency_code'], 'defaultLanguage': c['default_language_code'], 'timezone': c['default_timezone'], 'supportedLanguages': <String>[]},
        'branch': {'name': _v['name'], 'addressLine1': _v['address'], 'city': _v['city']},
      });
      await _r.signIn(_v['email']!, _v['password']!);
      widget.onDone();
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.registerCafe)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _ref,
        builder: (c, s) {
          if (s.hasError) return ErrorState(failure: s.error as dynamic);
          if (!s.hasData) return const SkeletonList();
          final countries = (s.data!['countries'] as List).cast<Map<dynamic, dynamic>>();
          return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Form(key: _form, child: ListView(padding: const EdgeInsets.all(Space.lg), children: [
            _f('name', l.cafeName), _f('legal', l.legalName),
            Padding(padding: const EdgeInsets.only(bottom: Space.md), child: DropdownButtonFormField<String>(decoration: InputDecoration(labelText: l.country), items: [for (final x in countries) DropdownMenuItem(value: _s(x['code']), child: Text(_s(x['name'])))], onChanged: (v) => _country = v, validator: (v) => v == null ? l.requiredField : null)),
            _f('address', l.address), _f('city', l.city), _f('owner', l.ownerName), _f('email', l.email),
            _f('password', l.password, obscure: true, check: (x) => x.length < 10 ? l.invalidValue : null),
            FilledButton(onPressed: _busy ? null : () => _submit(countries), child: Text(l.registerCafe)),
          ]))));
        },
      ),
    );
  }
}
