import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'package:shared_localization/shared_localization.dart';
import 'package:shared_network/shared_network.dart';
import '../config.dart';
import '../core/order_flags.dart';
import '../core/owner_repository.dart';
import '../core/save_stub.dart' if (dart.library.js_interop) '../core/save_web.dart';

OwnerRepository get _r => GetIt.I<OwnerRepository>();
bool _can(String permission) => _r.can(permission);
String _s(Object? v) => v?.toString() ?? '';
String _when(BuildContext c, Object? v) => v == null ? '' : c.dates.dateTime(DateTime.parse(v.toString()));
String _iso(DateTime d) => d.toIso8601String().substring(0, 10);
(String, String) _thisMonth() { final n = DateTime.now(); return (_iso(DateTime(n.year, n.month)), _iso(n.add(const Duration(days: 1)))); }

// Screens that follow the server live share one connection. When moving between two of them the new screen opens
// before the old one closes, so the connection is counted and only closed when the last screen using it goes.
int _liveUsers = 0;
RealtimeClient _liveAcquire() {
  final rt = GetIt.I<RealtimeClient>();
  if (_liveUsers++ == 0) rt.connect(token: _r.api.tokens.accessToken);
  return rt;
}

void _liveRelease() {
  if (--_liveUsers == 0) GetIt.I<RealtimeClient>().disconnect();
}

/// Returns the uploaded asset's id. The server re-checks the file's real type and size.
Future<String?> _pickAndUpload(BuildContext c, String kind) async {
  final picked = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
  final file = picked?.files.single;
  final Uint8List? bytes = file?.bytes;
  if (file == null || bytes == null) return null;
  return _r.upload(bytes, file.name, kind);
}

/// Extras on the dashboard. If one fails or is not permitted, the figures above it still show.
Future<T> _optional<T>(Future<T> Function() load, T fallback) async {
  try {
    return await load();
  } on ApiFailure {
    return fallback;
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (from, to) = _thisMonth();
    return LoadView<(Map<String, dynamic>, List<dynamic>, List<dynamic>)>(
      load: () async {
        final analytics = _r.analytics(from, to);
        final menu = _optional(() async => (await _r.menu())['products'] as List<dynamic>, const <dynamic>[]);
        final orders = _optional(_r.orders, const <dynamic>[]);
        return (await analytics, await menu, await orders);
      },
      builder: (c, data, reload) {
        final (d, products, orders) = data;
        final currency = _s(d['currency']);
        String m(Object? v) => c.money.formatAmount(_s(v ?? '0'), currency);
        final top = (d['topProducts'] as List).cast<Map<dynamic, dynamic>>();
        final hours = (d['peakHours'] as List).cast<Map<dynamic, dynamic>>();
        final trend = {for (final t in ((d['revenueTrend'] as List?) ?? const []).cast<Map<dynamic, dynamic>>()) _s(t['date']): double.parse(_s(t['revenue']))};
        // Every day so far this month, so a quiet day shows as quiet rather than disappearing.
        final today = DateTime.now();
        final days = [for (var i = 1; i <= today.day; i++) DateTime(today.year, today.month, i)];
        final photos = {for (final p in products.cast<Map<dynamic, dynamic>>()) if ((p['imageUrls'] as List).isNotEmpty) _s(p['name']): '$apiBaseUrl${(p['imageUrls'] as List).first}'};
        final topCard = top.isEmpty
            ? BarList(title: l.topProducts, icon: Icons.local_fire_department_outlined, rows: const [])
            : SectionCard(title: l.topProducts, icon: Icons.local_fire_department_outlined, child: Column(children: [
                for (final (i, t) in top.take(5).indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: depthShadows(Theme.of(c).colorScheme, lift: 0.6)), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox.square(dimension: 50, child: NetworkPhoto(url: photos[_s(t['name'])])))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_s(t['name']), overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                      Text('×${c.dates.number(double.parse(_s(t['quantity'])))}', style: TextStyle(color: i == 0 ? Theme.of(c).colorScheme.secondary : null, fontWeight: FontWeight.w700)),
                    ]),
                  ),
              ]));
        final peak = BarList(title: l.peakHours, icon: Icons.schedule, rows: [for (final h in hours) ('${_s(h['local_hour']).padLeft(2, '0')}:00', double.parse(_s(h['orders'])), _s(h['orders']))]);
        Widget pair(Widget a, Widget b) => LayoutBuilder(builder: (_, box) => box.maxWidth < Breakpoints.medium
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, const SizedBox(height: Space.md), b])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: Space.md), Expanded(child: b)]));
        return RefreshIndicator(
          onRefresh: reload,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Space.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _Welcome(photos: photos.values.take(3).toList()),
              const SizedBox(height: Space.md),
              StatGrid(children: [
                StatCard(label: l.revenue, value: m(d['revenue']), icon: Icons.payments_outlined, color: Colors.green.shade700),
                StatCard(label: l.ordersCount, value: c.dates.number(d['orders'] as num), icon: Icons.receipt_long, color: Colors.blue.shade700),
                StatCard(label: l.averageOrder, value: m(d['averageOrderValue']), icon: Icons.show_chart, color: Colors.deepOrange.shade700),
                StatCard(label: l.cancellationRate, value: d['cancellationRate'] == null ? '–' : '${d['cancellationRate']}%', icon: Icons.cancel_outlined, color: Colors.red.shade700),
              ]),
              const SizedBox(height: Space.md),
              if (trend.isNotEmpty) ...[
                SectionCard(title: l.revenueTrend, icon: Icons.bar_chart, child: TrendBars(bars: [for (final day in days) ('${day.day}', trend[_iso(day)] ?? 0, '${_iso(day)}: ${m(trend[_iso(day)] ?? 0)}')])),
                const SizedBox(height: Space.md),
              ],
              pair(topCard, peak),
              if (orders.isNotEmpty) ...[
                const SizedBox(height: Space.md),
                SectionCard(
                  title: l.recentOrders,
                  icon: Icons.receipt_long,
                  action: TextButton(onPressed: () => c.go('/orders'), child: Text(l.orders)),
                  child: Column(children: [
                    for (final o in orders.take(5).cast<Map<dynamic, dynamic>>())
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          Container(width: 4, height: 34, decoration: BoxDecoration(color: statusColor(_s(o['status'])), borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 12),
                          Expanded(child: Text('#${_s(o['order_number'])}${o['table_number'] == null ? '' : ' · ${_s(o['table_number'])}'}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                          StatusChip(label: l.orderStatus(_s(o['status'])), status: _s(o['status'])),
                          const SizedBox(width: 12),
                          Text(c.money.formatAmount(_s(o['total_amount']), _s(o['currency_code'])), style: const TextStyle(fontWeight: FontWeight.w700)),
                        ]),
                      ),
                  ]),
                ),
              ],
            ]),
          ),
        );
      },
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.photos});
  final List<String> photos;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final deep = toneOf(scheme.primary, 0.14);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: brandGradient(scheme),
        boxShadow: [BoxShadow(color: deep.withValues(alpha: 0.45), blurRadius: 34, offset: const Offset(0, 18), spreadRadius: -10)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(children: [
          // Light pooling in from the corners.
          Positioned(top: -90, right: 120, child: IgnorePointer(child: Container(width: 260, height: 260, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [toneOf(scheme.secondary, 0.55).withValues(alpha: 0.45), Colors.transparent]))))),
          Positioned(bottom: -120, left: -60, child: IgnorePointer(child: Container(width: 280, height: 280, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Colors.white.withValues(alpha: 0.10), Colors.transparent]))))),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.welcomeBack, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                const SizedBox(height: Space.xs),
                Text(_r.cafeName, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                const SizedBox(height: Space.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.calendar_month, size: 16, color: Colors.white), const SizedBox(width: 6), Text(l.thisMonth, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))]),
                ),
              ])),
              if (photos.isNotEmpty && !Breakpoints.isCompact(context)) _PhotoStack(photos: photos),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// The cafe's own product photos, as tilted cards fanned out in space.
class _PhotoStack extends StatelessWidget {
  const _PhotoStack({required this.photos});
  final List<String> photos;
  @override
  Widget build(BuildContext context) {
    const tile = 96.0;
    return ExcludeSemantics(
      child: SizedBox(
        width: tile + (photos.length - 1) * 62 + 20,
        height: tile + 30,
        child: Stack(clipBehavior: Clip.none, children: [
          for (final (i, url) in photos.indexed)
            Positioned(
              left: i * 62.0,
              top: i.isEven ? 18 : 0,
              child: FloatIn(
                delay: Duration(milliseconds: 90 * i),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..setEntry(3, 2, 0.0015)..rotateY(-0.35)..rotateZ((i - 1) * 0.06),
                  child: Container(
                    width: tile,
                    height: tile,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(10, 16), spreadRadius: -4)],
                    ),
                    child: ClipRRect(borderRadius: BorderRadius.circular(19), child: NetworkPhoto(url: url)),
                  ),
                ),
              ),
            ),
        ]),
      ),
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
  // Re-reads once a minute, so an order crossing the unpaid alert time is flagged without anyone reloading.
  Timer? _tick;
  int _generation = 0;
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    final rt = _liveAcquire();
    _sub = rt.events.listen((e) { if (mounted && (e.type.startsWith('order.') || e.type.startsWith('payment.'))) setState(() => _generation++); });
    _tick = Timer.periodic(const Duration(minutes: 1), (_) { if (mounted) setState(() => _generation++); });
  }

  @override
  void dispose() { _sub?.cancel(); _tick?.cancel(); _liveRelease(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return CrudPage(
      key: ValueKey(_generation),
      load: () => _r.orders(),
      initialFilter: _filter,
      onFilterChanged: (i) => _filter = i,
      filters: [
        CrudFilter(l.filterAll, (_) => true),
        for (final status in const ['placed', 'preparing', 'ready', 'completed', 'cancelled']) CrudFilter(l.orderStatus(status), (r) => r['status'] == status),
        CrudFilter(l.paymentStatus('unpaid'), _owes),
      ],
      searchText: (r) => '${_s(r['order_number'])} ${_s(r['table_number'])}',
      cardWidth: 400,
      cardHeight: 196,
      cardBuilder: (c, r, visible, run) {
        final primary = visible.where((a) => a.label == l.acceptOrder || a.label == l.markServed || a.label == l.complete || a.label == l.confirmCash).firstOrNull;
        final rest = [for (final a in visible) if (a != primary) a];
        final status = _s(r['status']);
        final late = _lateMinutes(r);
        final tone = late != null ? Colors.red : statusColor(status);
        return Raised(
          tilt: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(height: 6, decoration: BoxDecoration(gradient: LinearGradient(colors: [toneOf(tone, 0.62), toneOf(tone, 0.42)]))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.md, 10, Space.xs, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    GlossyIcon(icon: Icons.receipt_long, color: tone, size: 36),
                    const SizedBox(width: 10),
                    Text('#${_s(r['order_number'])}', style: Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    if (r['table_number'] != null) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.table_restaurant, size: 16, color: Theme.of(c).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(_s(r['table_number']), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                    const Spacer(),
                    if (rest.isNotEmpty) RowActionsMenu(actions: rest, run: run),
                  ]),
                  // Numbers restart each business day, so the day is shown with the number: two "#1"s are never confused.
                  Text(_placedLine(c, r), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(c).textTheme.bodySmall),
                  const SizedBox(height: Space.sm),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    StatusChip(label: l.orderStatus(status), status: status),
                    StatusChip(label: l.paymentStatus(_s(r['payment_status'])), status: _s(r['payment_status'])),
                    if (late != null) StatusChip(label: l.unpaidForMinutes(late), status: 'failed'),
                  ]),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Space.sm),
                    child: Row(children: [
                      Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(c.money.formatAmount(_s(r['total_amount']), _s(r['currency_code'])), style: Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)))),
                      if (primary != null) FilledButton.icon(style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), minimumSize: const Size(0, 38)), icon: Icon(primary.icon, size: 18), label: Text(primary.label), onPressed: () => run(primary)),
                    ]),
                  ),
                ]),
              ),
            ),
          ]),
        );
      },
      columns: [
        CrudColumn('#', (r) => _s(r['order_number'])),
        CrudColumn(l.tableNumber, (r) => _s(r['table_number'])),
        CrudColumn(l.status, (r) => l.orderStatus(_s(r['status']))),
        CrudColumn(l.payPaid, (r) => l.paymentStatus(_s(r['payment_status']))),
        CrudColumn(l.total, (r) => context.money.formatAmount(_s(r['total_amount']), _s(r['currency_code']))),
        CrudColumn(l.date, (r) => _when(context, r['placed_at'])),
      ],
      actions: [
        RowAction(l.acceptOrder, Icons.check, (_, r) => _r.orderStatus(r['public_id'] as String, 'accepted'), visible: (r) => _can('orders.update') && r['status'] == 'placed'),
        RowAction(l.markServed, Icons.room_service, (_, r) => _r.orderStatus(r['public_id'] as String, 'served'), visible: (r) => _can('orders.update') && r['status'] == 'ready'),
        RowAction(l.complete, Icons.done_all, (_, r) => _r.orderStatus(r['public_id'] as String, 'completed'), visible: (r) => _can('orders.update') && r['status'] == 'served' && r['payment_status'] == 'paid'),
        RowAction(l.createPaymentLink, Icons.link, (c, r) async {
          final url = await _r.paymentLink(r['public_id'] as String);
          if (!c.mounted) return;
          await showDialog<void>(context: c, builder: (d) => AlertDialog(title: Text(l.paymentLink), content: SelectableText(url), actions: [FilledButton(onPressed: () => Navigator.pop(d), child: Text(l.close))]));
        }, visible: (r) => _can('payments.cash_confirm') && _owes(r)),
        RowAction(l.confirmCash, Icons.payments, (c, r) async {
          final v = await showFormDialog(c, title: l.confirmCash, fields: [CrudField('amount', '${l.amount} (${l.balance})', number: true, required: false, initial: (double.parse(_s(r['total_amount'])) - double.parse(_s(r['paid_amount']))).toStringAsFixed(2))]);
          if (v != null) await _r.confirmCash(r['public_id'] as String, amount: (v['amount'] ?? '').isEmpty ? null : v['amount']);
        }, visible: (r) => _can('payments.cash_confirm') && _owes(r)),
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
        }, visible: (r) => _can('refunds.request') && ['paid', 'partially_refunded', 'partially_paid'].contains(r['payment_status'])),
        RowAction(l.splitBill, Icons.call_split, (c, r) async {
          final v = await showFormDialog(c, title: l.splitBill, fields: [CrudField('parts', l.numberOfParts, number: true, initial: '2')]);
          if (v == null) return;
          final out = await _r.splitBill(r['public_id'] as String, int.parse(v['parts']!));
          if (!c.mounted) return;
          final bills = (out['bills'] as List).cast<Map<dynamic, dynamic>>();
          await showDialog<void>(context: c, builder: (d) => AlertDialog(title: Text(l.splitBill), content: Column(mainAxisSize: MainAxisSize.min, children: [for (final b in bills) Text(c.money.formatAmount(_s((b['amount'] as Map)['amount']), _s((b['amount'] as Map)['currency'])))]), actions: [FilledButton(onPressed: () => Navigator.pop(d), child: Text(l.close))]));
        }, visible: (r) => _can('orders.update') && _owes(r)),
        RowAction(l.transferTable, Icons.swap_horiz, (c, r) async {
          final tables = (await _r.tables()).cast<Map<dynamic, dynamic>>();
          if (!c.mounted) return;
          final v = await showFormDialog(c, title: l.transferTable, fields: [CrudField('tableId', l.tableNumber, options: [for (final t in tables) (_s(t['public_id']), _s(t['table_number']))]), CrudField('reason', l.reason)]);
          if (v != null) await _r.transfer(r['public_id'] as String, v['tableId']!, v['reason']!);
        }, visible: (r) => _can('tables.transfer') && !['completed', 'cancelled'].contains(r['status'])),
        RowAction(l.cancelOrder, Icons.cancel, (c, r) async {
          final v = await showFormDialog(c, title: l.cancelOrder, fields: [CrudField('reason', l.reason)]);
          if (v != null) await _r.orderStatus(r['public_id'] as String, 'cancelled', reason: v['reason']);
        }, visible: (r) => _can('orders.cancel') && !['served', 'completed', 'cancelled'].contains(r['status'])),
      ],
    );
  }
}

bool _owes(Map<String, dynamic> r) => owes(r);
int? _lateMinutes(Map<String, dynamic> r) => unpaidMinutes(r, alertMinutes: _r.unpaidAlertMinutes);

/// When the order was placed, plus its business day when that differs: a day runs past midnight to the cafe's cut-off,
/// so an order at 12:30 AM can belong to the day before.
String _placedLine(BuildContext c, Map<String, dynamic> r) {
  final placed = _when(c, r['placed_at']);
  final d = _s(r['business_date']);
  if (d.length < 10 || r['placed_at'] == null) return placed;
  final day = DateTime.parse(d.substring(0, 10));
  final at = DateTime.parse(_s(r['placed_at'])).toLocal();
  return day.year == at.year && day.month == at.month && day.day == at.day ? placed : '$placed · ${c.l10n.countsForDay(c.dates.date(day))}';
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
        createFields: _can('menu.manage') ? [CrudField('name', l.name)] : null,
        createLabel: l.newCategory,
        onCreate: (_, v) => _r.createCategory(defaultLanguage, v['name']!),
        actions: [if (_can('menu.manage')) RowAction(l.delete, Icons.delete_outline, (_, r) => _r.deleteCategory(r['publicId'] as String))],
      )),
      (l.tax, CrudPage(
        load: _r.taxCategories,
        columns: [CrudColumn(l.code, (r) => _s(r['code'])), CrudColumn(l.name, (r) => _s(r['name'])), CrudColumn(l.tax, (r) => (r['rates'] as List).map((x) => '${x['displayName']} ${x['ratePercent']}%').join(', '))],
        createFields: _can('tax.manage') ? [CrudField('code', l.code), CrudField('name', l.name)] : null,
        onCreate: (_, v) => _r.createTaxCategory(v['code']!, v['name']!),
        actions: [
          if (_can('tax.manage')) RowAction(l.add, Icons.percent, (c, r) async {
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
        Future<void> pickPhoto(BuildContext c, Map<String, dynamic> r) async {
          final asset = await _pickAndUpload(c, 'product_image');
          if (asset != null) await _r.setProductImage(r['publicId'] as String, asset);
        }
        return CrudPage(
          load: () async => (await _r.menu())['products'] as List<dynamic>,
          columns: [
            CrudColumn(l.name, (r) => _s(r['name'])),
            CrudColumn(l.price, (r) => c.money.formatAmount(_s((r['price'] as Map)['amount']), _s((r['price'] as Map)['currency']))),
          ],
          filters: [
            CrudFilter(l.filterAll, (_) => true),
            for (final x in categories) CrudFilter(_s(x['name']), (r) => r['categoryId'] == x['publicId']),
          ],
          searchText: (r) => _s(r['name']),
          cardWidth: 250,
          cardHeight: 296,
          cardBuilder: (c, r, visible, run) => _ProductCard(row: r, actions: visible, run: run, onPhoto: _can('menu.manage') ? RowAction(l.addPhoto, Icons.add_a_photo_outlined, pickPhoto) : null),
          createLabel: l.newProduct,
          createFields: categories.isEmpty || !_can('menu.manage') ? null : [
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
            if (_can('menu.manage')) RowAction(l.language, Icons.translate, (c, r) async {
              final langs = [for (final loc in supportedAppLocales) (loc.languageCode, loc.languageCode)];
              final v = await showFormDialog(c, title: _s(r['name']), fields: [CrudField('language', l.language, options: langs), CrudField('name', l.name), CrudField('description', l.notes, required: false)]);
              if (v != null) await _r.updateProduct(r['publicId'] as String, {'translations': [{'language': v['language'], 'name': v['name'], if ((v['description'] ?? '').isNotEmpty) 'description': v['description']}]});
            }),
            if (_can('menu.manage')) RowAction(l.addVariant, Icons.straighten, (c, r) async {
              final v = await showFormDialog(c, title: l.addVariant, fields: [CrudField('name', l.optionName), CrudField('price', l.price, number: true)]);
              if (v != null) await _r.addVariant(r['publicId'] as String, language, v['name']!, v['price']!);
            }),
            if (_can('menu.manage')) RowAction(l.addExtras, Icons.add_circle_outline, (c, r) async {
              final v = await showFormDialog(c, title: l.addExtras, fields: [CrudField('group', l.extras, initial: l.extras), CrudField('name', l.optionName), CrudField('price', l.price, number: true)]);
              if (v != null) await _r.addExtras(r['publicId'] as String, language, v['group']!, v['name']!, v['price']!);
            }),
            if (_can('menu.manage')) RowAction(l.changePhoto, Icons.add_a_photo_outlined, pickPhoto, visible: (r) => (r['imageUrls'] as List).isNotEmpty),
            if (_can('menu.manage')) RowAction(l.removePhoto, Icons.hide_image_outlined, (_, r) => _r.removeProductImage(r['publicId'] as String), visible: (r) => (r['imageUrls'] as List).isNotEmpty),
            if (_can('inventory.manage')) RowAction(l.recipe, Icons.science_outlined, (c, r) async {
              final ingredients = (await _r.stock()).cast<Map<dynamic, dynamic>>();
              if (!c.mounted) return;
              final v = await showFormDialog(c, title: l.recipe, fields: [CrudField('ingredient', l.ingredients, options: [for (final i in ingredients) (_s(i['public_id']), '${i['name']} (${i['unit_code']})')]), CrudField('quantity', l.quantity, number: true)]);
              if (v != null) await _r.addRecipeLine(r['publicId'] as String, v['ingredient']!, v['quantity']!);
            }),
            if (_can('kitchen.configure')) RowAction(l.routeToStation, Icons.soup_kitchen_outlined, (c, r) async {
              final stations = (await _r.stations()).cast<Map<dynamic, dynamic>>();
              if (!c.mounted) return;
              final v = await showFormDialog(c, title: l.routeToStation, fields: [CrudField('station', l.stations, options: [for (final t in stations) (_s(t['public_id']), _s(t['name']))])]);
              if (v != null) await _r.routeProduct(r['publicId'] as String, v['station']!);
            }),
            if (_can('menu.manage')) RowAction(l.delete, Icons.delete_outline, (_, r) => _r.deleteProduct(r['publicId'] as String)),
          ],
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.row, required this.actions, required this.run, required this.onPhoto});
  final Map<String, dynamic> row;
  final List<RowAction> actions;
  final RunRowAction run;

  /// Null for someone who may look at the menu but not change it.
  final RowAction? onPhoto;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final images = row['imageUrls'] as List;
    final price = row['price'] as Map;
    final outOfStock = row['isOutOfStock'] == true;
    final (dietColor, dietLabel) = switch (row['dietaryClass']) {
      'veg' || 'vegan' => (Colors.green.shade700, row['dietaryClass'] == 'veg' ? l.veg : l.vegan),
      'non_veg' => (Colors.red.shade700, l.nonVeg),
      'egg' => (Colors.amber.shade800, l.egg),
      _ => (null, ''),
    };
    return Raised(
      tilt: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: Stack(fit: StackFit.expand, children: [
            if (onPhoto == null)
              images.isEmpty ? NetworkPhoto(url: null, fallback: GlossyIcon(icon: Icons.restaurant, size: 48)) : NetworkPhoto(url: '$apiBaseUrl${images.first}')
            else
              Semantics(
                button: true,
                label: images.isEmpty ? l.addPhoto : l.changePhoto,
                child: InkWell(
                  onTap: () => run(onPhoto!),
                  child: images.isEmpty
                      ? DecoratedBox(
                          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [scheme.surfaceContainerHigh, scheme.surfaceContainerLow])),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            GlossyIcon(icon: Icons.add_a_photo_outlined, size: 48),
                            const SizedBox(height: Space.xs),
                            Text(l.addPhoto, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
                          ]),
                        )
                      : NetworkPhoto(url: '$apiBaseUrl${images.first}'),
                ),
              ),
            // A soft shade at the foot of the photo, so it sits into the card.
            if (images.isNotEmpty) const Positioned(left: 0, right: 0, bottom: 0, height: 56, child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0x40000000)]))))),
            if (outOfStock)
              IgnorePointer(child: ColoredBox(color: Colors.black54, child: Center(child: Text(l.outOfStock, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))))),
            if (dietColor != null)
              PositionedDirectional(
                start: Space.sm,
                top: Space.sm,
                child: Tooltip(
                  message: dietLabel,
                  excludeFromSemantics: true,
                  child: Semantics(
                    label: dietLabel,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: dietColor, width: 1.5), borderRadius: BorderRadius.circular(4)),
                      child: Icon(row['dietaryClass'] == 'non_veg' ? Icons.change_history : Icons.circle, size: 10, color: dietColor),
                    ),
                  ),
                ),
              ),
            if (actions.isNotEmpty)
            PositionedDirectional(
              end: Space.xs,
              top: Space.xs,
              child: Material(color: Colors.white.withValues(alpha: 0.92), shape: const CircleBorder(), clipBehavior: Clip.antiAlias, child: IconTheme(data: const IconThemeData(color: Colors.black87), child: RowActionsMenu(actions: actions, run: run))),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_s(row['name']), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Row(children: [
              Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(context.money.formatAmount(_s(price['amount']), _s(price['currency'])), style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800, fontSize: 16)))),
              Tooltip(
                message: outOfStock ? l.outOfStock : l.available,
                excludeFromSemantics: true,
                child: Semantics(
                  label: '${_s(row['name'])}: ${outOfStock ? l.outOfStock : l.available}',
                  child: Switch(value: !outOfStock, onChanged: _can('menu.manage') ? (v) => run(RowAction(l.available, Icons.check, (_, r) => _r.updateProduct(r['publicId'] as String, {'isOutOfStock': !v}))) : null),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});
  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  StreamSubscription<RealtimeEvent>? _sub;
  int _generation = 0;

  // A table turns free the moment its guests pay, so the cards follow the server live.
  @override
  void initState() {
    super.initState();
    final rt = _liveAcquire();
    _sub = rt.events.listen((e) { if (mounted && (e.type.startsWith('table.') || e.type.startsWith('payment.'))) setState(() => _generation++); });
  }

  @override
  void dispose() { _sub?.cancel(); _liveRelease(); super.dispose(); }

  Future<void> _showQr(BuildContext c, Map<String, dynamic> q, String id) async {
    final l = c.l10n;
    final png = base64Decode((q['png'] as String).split(',').last);
    await showDialog<void>(context: c, builder: (d) => AlertDialog(
      title: Text(l.welcomeTable(_s(q['tableNumber']))),
      content: Column(mainAxisSize: MainAxisSize.min, children: [Image.memory(png, width: 280, height: 280), SelectableText(_s(q['url']))]),
      actions: [
        TextButton(onPressed: () => saveBytes(png, 'table-${q['tableNumber']}.png', 'image/png'), child: Text(l.qrCode)),
        if (_can('tables.manage')) TextButton(onPressed: () async { Navigator.pop(d); final fresh = await _r.regenerateQr(id); if (c.mounted) await _showQr(c, fresh, id); }, child: Text(l.regenerateQr)),
        FilledButton(onPressed: () => Navigator.pop(d), child: Text(l.close)),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Tabs([
      (l.tables, CrudPage(
        key: ValueKey(_generation),
        load: _r.tables,
        columns: [CrudColumn(l.tableNumber, (r) => _s(r['table_number']))],
        cardWidth: 250,
        cardHeight: 232,
        cardBuilder: (c, r, visible, run) {
          final scheme = Theme.of(c).colorScheme;
          // An occupied table offers freeing it first; otherwise its QR code.
          final primary = visible.firstWhere((a) => a.label == l.markAvailable, orElse: () => visible.first);
          final rest = [for (final a in visible) if (a != primary) a];
          return Raised(
            tilt: true,
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  GlossyIcon(icon: Icons.table_restaurant, size: 46),
                  const Spacer(),
                  RowActionsMenu(actions: rest, run: run),
                ]),
                const SizedBox(height: 10),
                Text(_s(r['table_number']), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: Space.xs),
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: Space.sm, children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.people_outline, size: 16, color: scheme.onSurfaceVariant), const SizedBox(width: 4), Text(_s(r['capacity']))]),
                  StatusChip(label: l.statusLabel(_s(r['status'])), status: _s(r['status'])),
                  // The PIN staff read out to the guests, when the cafe asks for one. A free table's old PIN is never shown,
                  // so it cannot be given to the next party: their scan makes a new one.
                  if (r['pin'] != null && r['status'] == 'occupied') Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.pin_outlined, size: 14, color: scheme.onPrimaryContainer), const SizedBox(width: 4), Text(l.tablePin(_s(r['pin'])), style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w800, letterSpacing: 1))]),
                  ),
                ]),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: primary.label == l.markAvailable
                      ? FilledButton.icon(style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), backgroundColor: Colors.green.shade700, foregroundColor: Colors.white), icon: Icon(primary.icon), label: Text(primary.label), onPressed: () => run(primary))
                      : FilledButton.tonalIcon(style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)), icon: Icon(primary.icon), label: Text(primary.label), onPressed: () => run(primary)),
                ),
              ]),
            ),
          );
        },
        createFields: _can('tables.manage') ? [CrudField('number', l.tableNumber), CrudField('capacity', l.capacity, number: true, initial: '4')] : null,
        onCreate: (_, v) => _r.createTable(v['number']!, int.parse(v['capacity']!)),
        actions: [
          RowAction(l.markAvailable, Icons.event_seat, (c, r) async {
            await _r.releaseTable(r['public_id'] as String);
            if (c.mounted) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(l.tableReleased)));
          }, visible: (r) => _can('orders.update') && r['status'] == 'occupied'),
          RowAction(l.qrCode, Icons.qr_code_2, (c, r) async { final id = r['public_id'] as String; final q = await _r.qr(id); if (c.mounted) await _showQr(c, q, id); }),
          if (_can('tables.manage')) RowAction(l.delete, Icons.delete_outline, (_, r) => _r.deleteTable(r['public_id'] as String)),
        ],
      )),
      if (_can('service_requests.manage')) (l.callStaff, CrudPage(
        load: _r.serviceRequests,
        columns: [CrudColumn(l.tableNumber, (r) => _s(r['table_number'])), CrudColumn(l.action, (r) => _s(r['request_type'])), CrudColumn(l.date, (r) => _when(context, r['created_at']))],
        actions: [RowAction(l.complete, Icons.check, (_, r) => _r.resolveRequest(r['public_id'] as String))],
      )),
      if (_can('kitchen.read')) (l.stations, CrudPage(
        load: _r.stations,
        columns: [CrudColumn(l.name, (r) => _s(r['name'])), CrudColumn(l.status, (r) => r['is_active'] == 1 ? 'active' : 'inactive', status: true)],
        createFields: _can('kitchen.configure') ? [CrudField('name', l.name)] : null,
        onCreate: (_, v) => _r.createStation(v['name']!),
      )),
      if (_can('reservations.manage')) (l.reservations, CrudPage(
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
        CrudColumn(l.name, (r) => _s(r['full_name']), avatar: true),
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
          SwitchListTile(title: Text(l.setTablePin), value: s['tablePinRequired'] == true, onChanged: (v) async { await _r.saveSettings({'tablePinRequired': v}); await reload(); }),
          for (final (k, label, choices) in [('sessionEndAfterPaymentMinutes', l.setSessionEndAfterPayment, const [0, 15, 30, 60, 120]), ('unpaidAlertMinutes', l.setUnpaidAlert, const [15, 30, 45, 60, 90, 120])])
            ListTile(title: Text(label), trailing: DropdownButton<int>(
              value: choices.contains(s[k]) ? s[k] as int : null,
              hint: Text('${s[k]} ${l.minutesUnit}'),
              items: [for (final m in choices) DropdownMenuItem(value: m, child: Text('$m ${l.minutesUnit}'))],
              onChanged: (v) async { if (v != null) { await _r.saveSettings({k: v}); await reload(); } },
            )),
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
        actions: [RowAction(l.approveRefund, Icons.check, (_, r) => _r.approveRefund(r['public_id'] as String), visible: (r) => _can('refunds.approve') && r['status'] == 'requested')],
      )),
      (l.settlements, CrudPage(
        load: _r.settlements,
        header: !_can('payments.gateway_manage') ? null : Builder(builder: (c) => Align(alignment: AlignmentDirectional.centerStart, child: OutlinedButton.icon(icon: const Icon(Icons.sync), label: Text(l.syncSettlements), onPressed: () async {
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
