import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_design_system/shared_design_system.dart';
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

  Future<void> _place(Cart cart) async {
    setState(() => _busy = true);
    try {
      final order = await GetIt.I<OrderRepository>().place(cart, notes: _notes.text.trim(), coupon: _coupon.text.trim(), language: context.read<SessionCubit>().state.language, idempotencyKey: _attemptKey);
      if (!mounted) return;
      context.read<CartCubit>().clear();
      _attemptKey = newIdempotencyKey();
      context.go('/orders/${order.publicId}');
    } on ApiFailure catch (f) {
      if (mounted) showFailure(context, f);
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
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(Space.sm),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(line.product.name, style: Theme.of(c).textTheme.titleSmall),
                            if (line.variant != null) Text(line.variant!.name),
                            for (final a in line.addons) Text('+ ${a.name}', style: Theme.of(c).textTheme.bodySmall),
                            if (line.notes != null && line.notes!.isNotEmpty) Text(line.notes!, style: Theme.of(c).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                            MoneyText(line.lineTotal),
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
                  AmountRow(label: l.subtotal, value: cart.previewTotal!, bold: true),
                  Text(l.plusTaxes, style: Theme.of(c).textTheme.bodySmall),
                ]),
          bottomNavigationBar: cart.isEmpty
              ? null
              : SafeArea(child: Padding(padding: const EdgeInsets.all(Space.md), child: FilledButton(onPressed: _busy ? null : () => _place(cart), child: _busy ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l.placeOrder)))),
        ));
  }
}
