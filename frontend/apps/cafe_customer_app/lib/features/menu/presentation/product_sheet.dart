import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'package:shared_models/shared_models.dart';
import '../../account/data/account_repository.dart';
import '../../cart/domain/cart.dart';
import '../../cart/presentation/cart_cubit.dart';
import '../../session/presentation/session_cubit.dart';

Future<void> showProductSheet(BuildContext context, MenuProduct product) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => MultiBlocProvider(providers: [BlocProvider.value(value: context.read<CartCubit>()), BlocProvider.value(value: context.read<SessionCubit>())], child: ProductSheet(product: product)),
    );

class ProductSheet extends StatefulWidget {
  const ProductSheet({super.key, required this.product});
  final MenuProduct product;
  @override
  State<ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<ProductSheet> {
  MenuVariant? _variant;
  final _addons = <MenuAddon>[];
  int _qty = 1;
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    final vs = widget.product.variants;
    if (vs.isNotEmpty) _variant = vs.firstWhere((v) => v.isDefault, orElse: () => vs.first);
  }

  @override
  void dispose() { _notes.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = widget.product;
    final line = CartLine(product: p, variant: _variant, addons: List.of(_addons), quantity: _qty, notes: _notes.text.trim());
    final valid = selectionValid(p, _variant, _addons);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: Text(p.name, style: Theme.of(context).textTheme.titleLarge)),
            if (GetIt.I.isRegistered<AccountRepository>() && GetIt.I<AccountRepository>().signedIn)
              IconButton(
                tooltip: l.wishlist,
                icon: const Icon(Icons.bookmark_add_outlined),
                onPressed: () async {
                  final slug = context.read<SessionCubit>().state.context?.slug;
                  if (slug == null) return;
                  try {
                    await GetIt.I<AccountRepository>().addWish(slug, p.publicId);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.thanks)));
                  } on ApiFailure catch (f) {
                    if (context.mounted) showFailure(context, f);
                  }
                },
              ),
          ]),
          if (p.description != null) Padding(padding: const EdgeInsets.only(top: Space.xs), child: Text(p.description!)),
          if (p.variants.isNotEmpty) ...[
            const SizedBox(height: Space.md),
            Text(l.chooseOption, style: Theme.of(context).textTheme.titleSmall),
            RadioGroup<String>(
              groupValue: _variant?.publicId,
              onChanged: (id) => setState(() => _variant = p.variants.firstWhere((v) => v.publicId == id)),
              child: Column(children: [for (final v in p.variants) RadioListTile<String>(value: v.publicId, contentPadding: EdgeInsets.zero, title: Text(v.name), secondary: MoneyText(v.price))]),
            ),
          ],
          for (final g in p.addonGroups) ...[
            const SizedBox(height: Space.md),
            Text(g.name, style: Theme.of(context).textTheme.titleSmall),
            for (final a in g.addons)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _addons.any((x) => x.publicId == a.publicId),
                title: Text(a.name),
                secondary: MoneyText(a.price),
                onChanged: (on) => setState(() { if (on == true) { _addons.add(a); } else { _addons.removeWhere((x) => x.publicId == a.publicId); } }),
              ),
          ],
          const SizedBox(height: Space.md),
          TextField(controller: _notes, maxLength: 500, decoration: InputDecoration(labelText: l.specialInstructions), onChanged: (_) => setState(() {})),
          const SizedBox(height: Space.sm),
          Row(children: [
            IconButton.outlined(tooltip: l.quantity, onPressed: _qty > 1 ? () => setState(() => _qty--) : null, icon: const Icon(Icons.remove)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: Space.md), child: Text('$_qty', style: Theme.of(context).textTheme.titleLarge)),
            IconButton.outlined(tooltip: l.quantity, onPressed: () => setState(() => _qty++), icon: const Icon(Icons.add)),
            const SizedBox(width: Space.md),
            Expanded(
              child: FilledButton(
                onPressed: valid ? () { context.read<CartCubit>().add(line); Navigator.pop(context); } : null,
                child: FittedBox(child: Row(mainAxisSize: MainAxisSize.min, children: [Text(l.addToCart), const SizedBox(width: Space.sm), MoneyText(line.lineTotal)])),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
