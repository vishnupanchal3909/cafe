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
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: BlocBuilder<CartCubit, Cart>(builder: (c, cart) => cart.isEmpty ? const SizedBox.shrink() : _CartBar(cart: cart)),
        body: NestedScrollView(
          headerSliverBuilder: (_, _) => [
            SliverAppBar(
              pinned: true,
              stretch: true,
              expandedHeight: Breakpoints.isCompact(c) ? 220 : 260,
              foregroundColor: Colors.white,
              backgroundColor: toneOf(Theme.of(c).colorScheme.primary, 0.2),
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
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                centerTitle: false,
                titlePadding: const EdgeInsetsDirectional.only(start: Space.md, bottom: 14, end: 160),
                title: Text(config.cafe.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, shadows: [Shadow(color: Colors.black54, blurRadius: 8)])),
                background: _MenuHero(config: config, table: l.welcomeTable(ctx.tableNumber)),
              ),
            ),
          ],
          body: LoadView<Menu>(
            key: ValueKey('${ctx.slug}/${session.language}'),
            load: () => repo.load(slug: ctx.slug, language: session.language, branchId: ctx.branchId),
            isEmpty: (m) => m.products.isEmpty,
            builder: (c, menu, reload) => _buildMenu(c, config, menu),
          ),
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
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.lg),
              itemCount: config.banners.length,
              separatorBuilder: (_, _) => const SizedBox(width: Space.md),
              itemBuilder: (_, i) {
                final b = config.banners[i];
                return SizedBox(
                  width: 300,
                  child: Raised(
                    tilt: true,
                    child: Stack(fit: StackFit.expand, children: [
                      NetworkPhoto(url: '$apiBaseUrl${b.imageUrl}'),
                      const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xAA000000)]))),
                      PositionedDirectional(
                        start: Space.md,
                        end: Space.md,
                        bottom: Space.md,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                          if (b.subtitle != null) Text(b.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                        ]),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
        ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: depthShadows(Theme.of(c).colorScheme, lift: 0.6)),
            child: TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.search), onChanged: (v) => setState(() => _query = v)),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 68,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.md), children: [
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
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 260, mainAxisSpacing: Space.md, crossAxisSpacing: Space.md, childAspectRatio: 0.7),
            delegate: SliverChildBuilderDelegate((_, i) => ProductCard(product: visible[i], grid: true), childCount: visible.length),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, 96),
          sliver: SliverList.separated(itemCount: visible.length, separatorBuilder: (_, _) => const SizedBox(height: Space.md), itemBuilder: (_, i) => ProductCard(product: visible[i], grid: false)),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final url = product.imageUrls.isEmpty ? null : '$apiBaseUrl${product.imageUrls.first}';
    final available = product.isAvailable;
    final price = available
        ? MoneyText(product.variants.isNotEmpty ? product.variants.first.price : product.price, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: scheme.primary))
        : Text(l.outOfStock, style: TextStyle(color: scheme.error, fontWeight: FontWeight.w700));
    final name = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (l.dietary(product.dietaryClass).isNotEmpty) ...[
        Padding(padding: const EdgeInsets.only(top: 3), child: _DietMark(product.dietaryClass, l.dietary(product.dietaryClass))),
        const SizedBox(width: 6),
      ],
      Expanded(child: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
    ]);
    final photo = Stack(fit: StackFit.expand, children: [
      NetworkPhoto(url: url, fallback: GlossyIcon(icon: Icons.restaurant, size: grid ? 52 : 36)),
      if (!available) const ColoredBox(color: Color(0x88000000)),
    ]);
    final add = available ? const GlossyIcon(icon: Icons.add, size: 36, circle: true) : null;
    if (grid) {
      return Raised(
        tilt: true,
        onTap: available ? () => showProductSheet(context, product) : null,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: Stack(fit: StackFit.expand, children: [
            photo,
            if (add != null) PositionedDirectional(end: Space.sm, bottom: Space.sm, child: add),
          ])),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [name, const SizedBox(height: 6), price]),
          ),
        ]),
      );
    }
    return Raised(
      onTap: available ? () => showProductSheet(context, product) : null,
      padding: const EdgeInsets.all(10),
      child: Row(children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: depthShadows(scheme, lift: 0.6)),
          child: ClipRRect(borderRadius: BorderRadius.circular(16), child: photo),
        ),
        const SizedBox(width: Space.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          name,
          if (product.description != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(product.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
          const SizedBox(height: 6),
          price,
        ])),
        if (add != null) ...[const SizedBox(width: Space.sm), add],
      ]),
    );
  }
}

/// The square veg / non-veg mark diners look for, with its meaning on hover and for screen readers.
class _DietMark extends StatelessWidget {
  const _DietMark(this.dietary, this.label);
  final String dietary;
  final String label;
  @override
  Widget build(BuildContext context) {
    final color = switch (dietary) { 'non_veg' => Colors.red.shade700, 'egg' => Colors.amber.shade800, _ => Colors.green.shade700 };
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        label: label,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: color, width: 1.5), borderRadius: BorderRadius.circular(3)),
          child: Icon(dietary == 'non_veg' ? Icons.change_history : Icons.circle, size: 8, color: color),
        ),
      ),
    );
  }
}

/// The cafe's cover photo, or its colours lit in depth when it has none, with its logo and the guest's table.
class _MenuHero extends StatelessWidget {
  const _MenuHero({required this.config, required this.table});
  final CafeConfig config;
  final String table;
  @override
  Widget build(BuildContext context) {
    final cover = config.cafe.coverUrl;
    final logo = config.cafe.logoUrl;
    final name = config.cafe.name;
    return Stack(fit: StackFit.expand, children: [
      if (cover != null) NetworkPhoto(url: '$apiBaseUrl$cover', fallback: const SizedBox.shrink()) else const AuroraBackdrop(child: SizedBox.expand()),
      const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x66000000), Color(0x00000000), Color(0xB3000000)], stops: [0, 0.4, 1]))),
      PositionedDirectional(
        start: Space.md,
        bottom: 52,
        child: FloatIn(
          child: Row(children: [
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white, width: 2.5), boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8))]),
              child: logo != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(16), child: SizedBox.square(dimension: 56, child: NetworkPhoto(url: '$apiBaseUrl$logo')))
                  : GlossyIcon(size: 56, color: Theme.of(context).colorScheme.secondary, child: Text(name.isEmpty ? '' : name.characters.first.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900))),
            ),
            const SizedBox(width: Space.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.35))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.table_restaurant, size: 16, color: Colors.white), const SizedBox(width: 6), Text(table, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))]),
            ),
          ]),
        ),
      ),
    ]);
  }
}

/// The way to the cart: a lit bar floating over the menu, with the count and the running total.
class _CartBar extends StatelessWidget {
  const _CartBar({required this.cart});
  final Cart cart;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = Theme.of(context).colorScheme;
    final ink = s.onPrimary;
    // As wide as the screen allows, less a gutter each side, and never sprawling on a desktop.
    final width = (MediaQuery.sizeOf(context).width - 2 * Space.md).clamp(0.0, 520.0);
    return SizedBox(
      width: width,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(31),
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(s.primary, Colors.white, 0.14)!, s.primary, Color.lerp(s.primary, Colors.black, 0.14)!]),
          boxShadow: [
            BoxShadow(color: s.primary.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 12), spreadRadius: -6),
            const BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(31),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/cart'),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 20, 8),
              child: Row(children: [
                Container(
                  width: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: ink.withValues(alpha: 0.18), border: Border.all(color: ink.withValues(alpha: 0.3))),
                  child: Text('${cart.itemCount}', style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 17)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(l.viewCart, overflow: TextOverflow.ellipsis, style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 16))),
                MoneyText(cart.previewTotal!, style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(width: Space.sm),
                Icon(Icons.arrow_forward, color: ink),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
