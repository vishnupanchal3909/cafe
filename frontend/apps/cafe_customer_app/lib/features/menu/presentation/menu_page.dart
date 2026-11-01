import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'package:shared_localization/shared_localization.dart';
import 'package:shared_models/shared_models.dart';
import '../../../config.dart';
import '../../cart/domain/cart.dart';
import '../../cart/presentation/cart_cubit.dart';
import '../../orders/data/order_repository.dart';
import '../../session/presentation/session_cubit.dart';
import '../data/menu_repository.dart';
import 'product_sheet.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});
  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String _query = '';
  String? _category;
  bool _vegOnly = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocBuilder<SessionCubit, SessionState>(builder: (c, session) {
      final ctx = session.context;
      if (ctx == null) return const Scaffold(body: SkeletonList());
      final config = ctx.config;
      final repo = GetIt.I<MenuRepository>();
      return Scaffold(
        appBar: AppBar(
          title: Row(children: [
            if (config.cafe.logoUrl != null) ...[
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network('$apiBaseUrl${config.cafe.logoUrl}', height: 36, width: 36, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink())),
              const SizedBox(width: Space.sm),
            ],
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(config.cafe.name, overflow: TextOverflow.ellipsis),
              Text(l.welcomeTable(ctx.tableNumber), style: Theme.of(context).textTheme.labelMedium),
            ])),
          ]),
          actions: [
            if (config.languages.length > 1) LanguageMenu(languages: [for (final lang in config.languages) (lang.code, lang.nativeName)], onSelected: c.read<SessionCubit>().setLanguage),
            PopupMenuButton<String>(
              icon: const Icon(Icons.room_service_outlined),
              tooltip: l.callStaff,
              onSelected: (type) async {
                try {
                  await GetIt.I<OrderRepository>().serviceRequest(type);
                  if (c.mounted) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(l.requestSent)));
                } on ApiFailure catch (f) {
                  if (c.mounted) showFailure(c, f);
                }
              },
              itemBuilder: (_) => [PopupMenuItem(value: 'waiter', child: Text(l.callWaiter)), PopupMenuItem(value: 'bill', child: Text(l.requestBill)), PopupMenuItem(value: 'staff', child: Text(l.callStaff))],
            ),
            IconButton(tooltip: l.myOrders, icon: const Icon(Icons.receipt_long), onPressed: () => c.push('/orders')),
            IconButton(tooltip: l.profile, icon: const Icon(Icons.person_outline), onPressed: () => c.push('/account')),
          ],
        ),
        floatingActionButton: BlocBuilder<CartCubit, Cart>(
          builder: (c, cart) => cart.isEmpty
              ? const SizedBox.shrink()
              : FloatingActionButton.extended(
                  onPressed: () => c.push('/cart'),
                  icon: Badge(label: Text('${cart.itemCount}'), child: const Icon(Icons.shopping_bag_outlined)),
                  label: Row(mainAxisSize: MainAxisSize.min, children: [Text(l.viewCart), const SizedBox(width: Space.sm), MoneyText(cart.previewTotal!)]),
                ),
        ),
        body: LoadView<Menu>(
          key: ValueKey('${ctx.slug}/${session.language}'),
          load: () => repo.load(slug: ctx.slug, language: session.language, branchId: ctx.branchId),
          isEmpty: (m) => m.products.isEmpty,
          builder: (c, menu, reload) => _buildMenu(c, config, menu),
        ),
      );
    });
  }

  Widget _buildMenu(BuildContext c, CafeConfig config, Menu menu) {
    final l = c.l10n;
    final q = _query.trim().toLowerCase();
    final visible = menu.products.where((p) {
      if (_category != null && p.categoryId != _category) return false;
      if (_vegOnly && !['veg', 'vegan'].contains(p.dietaryClass)) return false;
      return q.isEmpty || p.name.toLowerCase().contains(q) || (p.description ?? '').toLowerCase().contains(q);
    }).toList();
    final grid = config.theme.menuLayout == 'grid';
    return CustomScrollView(slivers: [
      if (config.banners.isNotEmpty)
        SliverToBoxAdapter(
          child: SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(Space.md),
              itemCount: config.banners.length,
              separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
              itemBuilder: (_, i) {
                final b = config.banners[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(children: [
                    Image.network('$apiBaseUrl${b.imageUrl}', width: 280, height: 108, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(width: 280, color: Theme.of(c).colorScheme.secondaryContainer)),
                    PositionedDirectional(start: Space.sm, bottom: Space.sm, child: Text(b.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, shadows: [Shadow(blurRadius: 6)]))),
                  ]),
                );
              },
            ),
          ),
        ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 0),
          child: TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.search, isDense: true), onChanged: (v) => setState(() => _query = v)),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 56,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm), children: [
            ChoiceChip(label: Text(l.allCategories), selected: _category == null, onSelected: (_) => setState(() => _category = null)),
            for (final cat in menu.categories) ...[const SizedBox(width: Space.sm), ChoiceChip(label: Text(cat.name), selected: _category == cat.publicId, onSelected: (_) => setState(() => _category = cat.publicId))],
            const SizedBox(width: Space.sm),
            FilterChip(label: Text(l.veg), avatar: const Icon(Icons.eco, size: 16), selected: _vegOnly, onSelected: (v) => setState(() => _vegOnly = v)),
          ]),
        ),
      ),
      if (visible.isEmpty)
        SliverFillRemaining(hasScrollBody: false, child: EmptyState(icon: Icons.search_off, message: l.noResults))
      else if (grid)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, 96),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 260, mainAxisSpacing: Space.sm, crossAxisSpacing: Space.sm, childAspectRatio: 0.8),
            delegate: SliverChildBuilderDelegate((_, i) => ProductCard(product: visible[i], grid: true), childCount: visible.length),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, 96),
          sliver: SliverList.separated(itemCount: visible.length, separatorBuilder: (_, _) => const SizedBox(height: Space.sm), itemBuilder: (_, i) => ProductCard(product: visible[i], grid: false)),
        ),
    ]);
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.grid});
  final MenuProduct product;
  final bool grid;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final image = product.imageUrls.isEmpty
        ? null
        : Image.network('$apiBaseUrl${product.imageUrls.first}', fit: BoxFit.cover, width: grid ? double.infinity : 88, height: grid ? 110 : 88, errorBuilder: (_, _, _) => const SizedBox.shrink());
    final info = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        if (l.dietary(product.dietaryClass).isNotEmpty) ...[
          Tooltip(message: l.dietary(product.dietaryClass), child: Icon(product.dietaryClass == 'non_veg' ? Icons.set_meal : Icons.eco, size: 14, color: product.dietaryClass == 'non_veg' ? Colors.red.shade700 : Colors.green.shade700)),
          const SizedBox(width: Space.xs),
        ],
        Expanded(child: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall)),
      ]),
      if (product.description != null && !grid) Text(product.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: Space.xs),
      product.isAvailable ? MoneyText(product.variants.isNotEmpty ? product.variants.first.price : product.price, style: Theme.of(context).textTheme.titleSmall) : Text(l.outOfStock, style: TextStyle(color: Theme.of(context).colorScheme.error)),
    ]);
    return Card(
      child: InkWell(
        onTap: product.isAvailable ? () => showProductSheet(context, product) : null,
        child: grid
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [if (image != null) image, Padding(padding: const EdgeInsets.all(Space.sm), child: info)])
            : Padding(padding: const EdgeInsets.all(Space.sm), child: Row(children: [if (image != null) ...[ClipRRect(borderRadius: BorderRadius.circular(8), child: image), const SizedBox(width: Space.md)], Expanded(child: info), Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary)])),
      ),
    );
  }
}

