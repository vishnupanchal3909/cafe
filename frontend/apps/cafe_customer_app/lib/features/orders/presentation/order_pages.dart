import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'package:shared_localization/shared_localization.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_network/shared_network.dart';
import '../../session/presentation/session_cubit.dart';
import '../data/order_repository.dart';
import 'external_open_stub.dart' if (dart.library.js_interop) 'external_open_web.dart';
import 'razorpay_checkout.dart';
import 'razorpay_stub.dart' if (dart.library.js_interop) 'razorpay_web.dart';

const _progress = ['placed', 'accepted', 'preparing', 'ready', 'served', 'completed'];

/// Live tracking. The socket only says "something changed"; the order itself is always re-read from the server.
class OrderTrackPage extends StatefulWidget {
  const OrderTrackPage({super.key, required this.orderId});
  final String orderId;
  @override
  State<OrderTrackPage> createState() => _OrderTrackPageState();
}

class _OrderTrackPageState extends State<OrderTrackPage> {
  late final LoadCubit<CafeOrder> _cubit = LoadCubit<CafeOrder>(() => GetIt.I<OrderRepository>().get(widget.orderId))..load();
  StreamSubscription<RealtimeEvent>? _sub;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    final rt = GetIt.I<RealtimeClient>();
    final token = context.read<SessionCubit>().state.context?.sessionToken;
    if (token != null) rt.connect(tableSession: token);
    _sub = rt.events.listen((e) { if (e.payload['orderId'] == widget.orderId) _cubit.load(silent: true); });
    // A safety net for networks that block websockets, which is common on cafe guest Wi-Fi.
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _cubit.load(silent: true));
  }

  @override
  void dispose() { _sub?.cancel(); _poll?.cancel(); _cubit.close(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.trackOrder), leading: IconButton(tooltip: l.menu, icon: const Icon(Icons.restaurant_menu), onPressed: () => context.go('/menu'))),
      body: BlocBuilder<LoadCubit<CafeOrder>, ViewState<CafeOrder>>(
        bloc: _cubit,
        builder: (c, s) => AsyncView<CafeOrder>(state: s, onRetry: _cubit.load, builder: (o) => _OrderBody(order: o, onChanged: () => _cubit.load(silent: true))),
      ),
    );
  }
}

class _OrderBody extends StatelessWidget {
  const _OrderBody({required this.order, required this.onChanged});
  final CafeOrder order;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final step = _progress.indexOf(order.status);
    final due = order.total - order.paid;
    return ListView(padding: const EdgeInsets.all(Space.md), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l.orderNumber(order.orderNumber), style: Theme.of(context).textTheme.titleLarge),
        StatusChip(label: l.orderStatus(order.status), status: order.status),
      ]),
      if (order.status != 'cancelled' && step >= 0) ...[
        const SizedBox(height: Space.md),
        Semantics(label: l.orderStatus(order.status), child: LinearProgressIndicator(value: (step + 1) / _progress.length, minHeight: 8, borderRadius: BorderRadius.circular(4))),
      ],
      const SizedBox(height: Space.md),
      Card(child: Padding(padding: const EdgeInsets.all(Space.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final i in order.items.where((x) => x.status == 'active'))
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${i.quantity} × '),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(i.name), if (i.variant != null) Text(i.variant!, style: Theme.of(context).textTheme.bodySmall), for (final a in i.addons) Text('+ ${a.name}', style: Theme.of(context).textTheme.bodySmall)])),
              MoneyText(i.lineTotal),
            ]),
          ),
        const Divider(),
        AmountRow(label: l.subtotal, value: order.subtotal),
        if (!order.discount.isZero) AmountRow(label: l.discount, value: order.discount),
        AmountRow(label: l.tax, value: order.tax),
        if (!order.serviceCharge.isZero) AmountRow(label: l.serviceCharge, value: order.serviceCharge),
        AmountRow(label: l.total, value: order.total, bold: true),
        if (!order.paid.isZero) AmountRow(label: l.payPaid, value: order.paid),
      ]))),
      const SizedBox(height: Space.md),
      Row(children: [Text('${l.status}: '), StatusChip(label: l.paymentStatus(order.paymentStatus), status: order.paymentStatus)]),
      if (!due.isZero && due.amount.signum > 0 && order.status != 'cancelled') ...[const SizedBox(height: Space.md), _PaySection(order: order, due: due, onChanged: onChanged)],
      if (['ready', 'served', 'completed'].contains(order.status)) ...[const SizedBox(height: Space.md), _ReviewCard(orderId: order.publicId)],
    ]);
  }
}

class _PaySection extends StatefulWidget {
  const _PaySection({required this.order, required this.due, required this.onChanged});
  final CafeOrder order;
  final Money due;
  final VoidCallback onChanged;
  @override
  State<_PaySection> createState() => _PaySectionState();
}

class _PaySectionState extends State<_PaySection> {
  late final Future<Map<String, dynamic>> _options = GetIt.I<OrderRepository>().paymentOptions();
  bool _waiting = false;
  bool _busy = false;

  void _say(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // Only the server's answer changes what the guest sees: never the browser's own "success".
  Future<void> _waitForServer(String paymentId) async {
    final repo = GetIt.I<OrderRepository>();
    setState(() => _waiting = true);
    for (var i = 0; i < 40 && mounted; i++) {
      final status = await repo.paymentStatus(paymentId);
      if (status['status'] != 'pending') {
        if (status['status'] == 'succeeded' && mounted) _say(context.l10n.paymentSuccessful);
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }

  Future<void> _payOnline(String method, {String? amount}) async {
    final l = context.l10n;
    final repo = GetIt.I<OrderRepository>();
    final config = context.read<SessionCubit>().state.context!.config;
    setState(() => _busy = true);
    try {
      final r = await repo.startPayment(widget.order.publicId, method, amount: amount);
      final paymentId = r['paymentId'] as String;
      final checkout = (r['checkout'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      if (checkout['redirectUrl'] is String) {
        openExternal(checkout['redirectUrl'] as String);
        await _waitForServer(paymentId);
      } else {
        final outcome = await openRazorpay(checkout, cafeName: config.cafe.name, themeColor: config.theme.primaryColor);
        switch (outcome) {
          case CheckoutPaid(paymentRef: final ref, signature: final sig):
            setState(() => _waiting = true);
            final v = await repo.verifyPayment(paymentId, ref, sig);
            if (v['status'] == 'succeeded') {
              _say(l.paymentSuccessful);
            } else {
              await _waitForServer(paymentId);
            }
          case CheckoutDismissed():
            await repo.abandonPayment(paymentId);
            _say(l.paymentNotCompleted);
          case CheckoutUnavailable():
            // No script available here (native app or blocked network): a hosted link does the same job.
            await repo.abandonPayment(paymentId);
            final link = await repo.startPayment(widget.order.publicId, method, amount: amount, link: true);
            openExternal(link['shortUrl'] as String);
            await _waitForServer(link['paymentId'] as String);
        }
      }
      widget.onChanged();
    } on ApiFailure catch (f) {
      if (mounted) showFailure(context, f);
    } finally {
      if (mounted) setState(() { _busy = false; _waiting = false; });
    }
  }

  Future<void> _payPart(String method) async {
    final l = context.l10n;
    final v = await showFormDialog(context, title: l.payPart, fields: [CrudField('amount', l.amountToPay, number: true)]);
    if (v != null) await _payOnline(method, amount: v['amount']);
  }

  Future<void> _requestBill() async {
    final l = context.l10n;
    try {
      await GetIt.I<OrderRepository>().serviceRequest('bill');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.requestSent)));
    } on ApiFailure catch (f) {
      if (mounted) showFailure(context, f);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Card(child: Padding(padding: const EdgeInsets.all(Space.md), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AmountRow(label: l.balance, value: widget.due, bold: true),
      const SizedBox(height: Space.sm),
      FutureBuilder<Map<String, dynamic>>(future: _options, builder: (c, snap) {
        final online = snap.data?['online'] != null;
        final enabled = ((snap.data?['methods'] as List?) ?? const []).cast<Map<dynamic, dynamic>>().where((m) => m['is_manual'] != 1 && m['code'] != 'payment_link').toList();
        // Razorpay's own checkout offers UPI, cards and the rest, so one button is enough.
        final method = enabled.isEmpty ? null : enabled.first['code'] as String;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_waiting) Padding(padding: const EdgeInsets.only(bottom: Space.sm), child: Text(l.paymentPending, textAlign: TextAlign.center)),
          if (online && method != null) ...[
            FilledButton(onPressed: _busy ? null : () => _payOnline(method), child: Text(l.payOnline)),
            const SizedBox(height: Space.xs),
            TextButton(onPressed: _busy ? null : () => _payPart(method), child: Text(l.payPart)),
            const SizedBox(height: Space.sm),
          ],
          if (snap.hasData && (!online || method == null)) Padding(padding: const EdgeInsets.only(bottom: Space.sm), child: Text(l.onlinePaymentUnavailable, textAlign: TextAlign.center)),
          OutlinedButton.icon(onPressed: _requestBill, icon: const Icon(Icons.point_of_sale), label: Text(l.payAtCounter)),
        ]);
      }),
    ])));
  }
}

class _ReviewCard extends StatefulWidget {
  const _ReviewCard({required this.orderId});
  final String orderId;
  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  int _rating = 0;
  bool _done = false;
  final _comment = TextEditingController();

  @override
  void dispose() { _comment.dispose(); super.dispose(); }

  Future<void> _submit() async {
    try {
      await GetIt.I<OrderRepository>().review(widget.orderId, _rating, _comment.text.trim());
      if (mounted) setState(() => _done = true);
    } on ApiFailure catch (f) {
      if (f.status == 409 && f.code == 'DUPLICATE') {
        if (mounted) setState(() => _done = true);
      } else if (mounted) {
        showFailure(context, f);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (_done) return Card(child: Padding(padding: const EdgeInsets.all(Space.md), child: Center(child: Text(l.thanks))));
    return Card(child: Padding(padding: const EdgeInsets.all(Space.md), child: Column(children: [
      Text(l.rateUs, style: Theme.of(context).textTheme.titleSmall),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 1; i <= 5; i++) IconButton(tooltip: '$i', icon: Icon(i <= _rating ? Icons.star : Icons.star_border), onPressed: () => setState(() => _rating = i)),
      ]),
      TextField(controller: _comment, maxLength: 2000, decoration: InputDecoration(labelText: l.notes)),
      FilledButton(onPressed: _rating == 0 ? null : _submit, child: Text(l.submit)),
    ])));
  }
}

class SessionOrdersPage extends StatelessWidget {
  const SessionOrdersPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.myOrders)),
      body: LoadView<List<CafeOrder>>(
        load: () => GetIt.I<OrderRepository>().forSession(),
        builder: (c, orders, _) => ListView.separated(
          padding: const EdgeInsets.all(Space.md),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
          itemBuilder: (_, i) {
            final o = orders[i];
            return Card(child: ListTile(title: Text(l.orderNumber(o.orderNumber)), subtitle: Text(l.orderStatus(o.status)), trailing: MoneyText(o.total), onTap: () => c.push('/orders/${o.publicId}')));
          },
        ),
      ),
    );
  }
}
