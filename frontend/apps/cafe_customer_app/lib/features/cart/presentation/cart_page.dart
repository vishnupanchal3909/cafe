import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_design_system/shared_design_system.dart';
import '../../../config.dart';
import '../../account/data/account_repository.dart';
import '../../orders/data/order_repository.dart';
import '../../session/presentation/session_cubit.dart';
import '../domain/cart.dart';
import 'cart_cubit.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _notes = TextEditingController();
  final _coupon = TextEditingController();
  // One key per attempt: if a flaky network makes someone tap twice, they still get one order.
  String _attemptKey = newIdempotencyKey();
  bool _busy = false;

  bool get _signedIn => GetIt.I<AccountRepository>().signedIn;

  /// Ordering needs an account (the cafe owner's rule); browsing does not. The server enforces the same rule.
  Future<bool> _ensureSignedIn() async {
    if (_signedIn) return true;
    final ok = await context.push<bool>('/signin');
    if (mounted) setState(() {});
    return ok == true && _signedIn;
  }

  /// The four-digit PIN staff give the guests at the table, so a photo of the QR code cannot be used from elsewhere.
  Future<bool> _askPin() async {
    final l = context.l10n;
    final v = await showFormDialog(context, title: l.tablePinHint, fields: [CrudField('pin', l.enterTablePin, number: true)]);
    if (v == null || !mounted) return false;
    try {
      await GetIt.I<OrderRepository>().enterTablePin(v['pin']!.trim());
      return true;
    } on ApiFailure catch (f) {
      if (mounted) showFailure(context, f);
      return false;
    }
  }

  Future<void> _place(Cart cart) async {
    if (!await _ensureSignedIn() || !mounted) return;
    setState(() => _busy = true);
    try {
      final order = await GetIt.I<OrderRepository>().place(cart, notes: _notes.text.trim(), coupon: _coupon.text.trim(), language: context.read<SessionCubit>().state.language, idempotencyKey: _attemptKey);
      if (!mounted) return;
      context.read<CartCubit>().clear();
      _attemptKey = newIdempotencyKey();
      context.go('/orders/${order.publicId}');
    } on ApiFailure catch (f) {
      // The cafe asks for the table's PIN: once it is entered, the same order goes through.
      if (f.code == 'TABLE_PIN_REQUIRED') {
        if (mounted) setState(() => _busy = false);
        if (await _askPin() && mounted) await _place(cart);
        return;
      }
      if (mounted) showFailure(context, f);
      // A login that has since expired: sign in again, and the same attempt can be retried.
      if (f.code == 'CUSTOMER_LOGIN_REQUIRED') {
        await GetIt.I<AccountRepository>().signOut();
        _attemptKey = newIdempotencyKey();
        if (mounted) setState(() {});
        return;
      }
      // A definite refusal lets the guest change something and try again as a new request.
      if (!f.isNetwork) _attemptKey = newIdempotencyKey();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() { _notes.dispose(); _coupon.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocBuilder<CartCubit, Cart>(builder: (c, cart) => Scaffold(
          appBar: AppBar(title: Text(l.cart)),
          body: cart.isEmpty
              ? EmptyState(icon: Icons.shopping_bag_outlined, message: l.emptyCart)
              : ListView(padding: const EdgeInsets.all(Space.md), children: [
                  for (final line in cart.lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.md),
                      child: Raised(
                        padding: const EdgeInsets.all(10),
                        child: Row(children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: depthShadows(Theme.of(c).colorScheme, lift: 0.5)),
                            child: ClipRRect(borderRadius: BorderRadius.circular(14), child: NetworkPhoto(url: line.product.imageUrls.isEmpty ? null : '$apiBaseUrl${line.product.imageUrls.first}', fallback: const GlossyIcon(icon: Icons.restaurant, size: 30))),
                          ),
                          const SizedBox(width: Space.md),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(line.product.name, style: Theme.of(c).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                            if (line.variant != null) Text(line.variant!.name),
                            for (final a in line.addons) Text('+ ${a.name}', style: Theme.of(c).textTheme.bodySmall),
                            if (line.notes != null && line.notes!.isNotEmpty) Text(line.notes!, style: Theme.of(c).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                            const SizedBox(height: 4),
                            MoneyText(line.lineTotal, style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(c).colorScheme.primary)),
                          ])),
                          IconButton(tooltip: l.quantity, icon: const Icon(Icons.remove_circle_outline), onPressed: () => c.read<CartCubit>().setQuantity(line.key, line.quantity - 1)),
                          Text('${line.quantity}'),
                          IconButton(tooltip: l.quantity, icon: const Icon(Icons.add_circle_outline), onPressed: () => c.read<CartCubit>().setQuantity(line.key, line.quantity + 1)),
                        ]),
                      ),
                    ),
                  const SizedBox(height: Space.md),
                  TextField(controller: _notes, maxLength: 1000, decoration: InputDecoration(labelText: l.specialInstructions)),
                  TextField(controller: _coupon, maxLength: 40, decoration: InputDecoration(labelText: l.coupon, prefixIcon: const Icon(Icons.local_offer_outlined))),
                  const SizedBox(height: Space.sm),
                  Raised(
                    padding: const EdgeInsets.all(Space.md),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      AmountRow(label: l.subtotal, value: cart.previewTotal!, bold: true),
                      Text(l.plusTaxes, style: Theme.of(c).textTheme.bodySmall),
                    ]),
                  ),
                  if (!_signedIn) ...[
                    const SizedBox(height: Space.md),
                    Row(children: [
                      Icon(Icons.lock_outline, size: 18, color: Theme.of(c).colorScheme.primary),
                      const SizedBox(width: Space.sm),
                      Expanded(child: Text(l.signInToOrderHint, style: Theme.of(c).textTheme.bodySmall)),
                    ]),
                  ],
                ]),
          bottomNavigationBar: cart.isEmpty
              ? null
              : SafeArea(child: Padding(padding: const EdgeInsets.all(Space.md), child: FilledButton(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)), onPressed: _busy ? null : () => _place(cart), child: _busy ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_signedIn ? l.placeOrder : l.signInToOrder)))),
        ));
  }
}
