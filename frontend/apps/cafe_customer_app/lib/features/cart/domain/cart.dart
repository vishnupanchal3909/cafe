import 'package:equatable/equatable.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_models/shared_models.dart';

/// Pure cart logic. Amounts here are a preview only: the server prices the order when it is placed.
class CartLine extends Equatable {
  const CartLine({required this.product, this.variant, this.addons = const [], this.quantity = 1, this.notes});
  final MenuProduct product;
  final MenuVariant? variant;
  final List<MenuAddon> addons;
  final int quantity;
  final String? notes;

  String get key => '${product.publicId}|${variant?.publicId ?? ''}|${addons.map((a) => a.publicId).join(',')}|${notes ?? ''}';

  Money get unitPrice {
    final base = variant?.price ?? product.price;
    return addons.fold(base, (sum, a) => sum + a.price);
  }

  Money get lineTotal => unitPrice.times(quantity);

  CartLine withQuantity(int q) => CartLine(product: product, variant: variant, addons: addons, quantity: q, notes: notes);

  /// Prices are deliberately absent from the request.
  Map<String, dynamic> toRequest() => {
        'productId': product.publicId,
        if (variant != null) 'variantId': variant!.publicId,
        'quantity': quantity,
        if (addons.isNotEmpty) 'addons': [for (final a in addons) {'addonId': a.publicId}],
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };

  @override
  List<Object?> get props => [key, quantity];
}

class Cart extends Equatable {
  const Cart(this.lines);
  const Cart.empty() : lines = const [];
  final List<CartLine> lines;

  bool get isEmpty => lines.isEmpty;
  int get itemCount => lines.fold(0, (n, l) => n + l.quantity);
  Money? get previewTotal => lines.isEmpty ? null : lines.skip(1).fold(lines.first.lineTotal, (sum, l) => sum! + l.lineTotal);

  Cart add(CartLine line) {
    final i = lines.indexWhere((l) => l.key == line.key);
    if (i < 0) return Cart([...lines, line]);
    final next = [...lines];
    next[i] = next[i].withQuantity(next[i].quantity + line.quantity);
    return Cart(next);
  }

  Cart setQuantity(String key, int quantity) {
    if (quantity <= 0) return Cart(lines.where((l) => l.key != key).toList());
    return Cart([for (final l in lines) l.key == key ? l.withQuantity(quantity) : l]);
  }

  @override
  List<Object?> get props => [lines];
}

/// What a guest must choose before the item can be added. Mirrors the server, which still re-checks it.
bool selectionValid(MenuProduct p, MenuVariant? variant, List<MenuAddon> addons) {
  if (p.variants.isNotEmpty && variant == null) return false;
  for (final g in p.addonGroups) {
    final n = addons.where((a) => g.addons.any((x) => x.publicId == a.publicId)).length;
    if (n < g.minSelect) return false;
    if (g.maxSelect != null && n > g.maxSelect!) return false;
  }
  return true;
}
