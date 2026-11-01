import 'package:bloc_test/bloc_test.dart';
import 'package:cafe_customer_app/features/cart/domain/cart.dart';
import 'package:cafe_customer_app/features/cart/presentation/cart_cubit.dart';
import 'package:cafe_customer_app/features/menu/presentation/product_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'package:shared_models/shared_models.dart';

Map<String, String> money(String a) => {'amount': a, 'currency': 'INR'};
final addon = MenuAddon.fromJson({'publicId': 'A1', 'name': 'Ginger', 'price': money('20')});
final large = MenuVariant.fromJson({'publicId': 'V1', 'name': 'Large', 'price': money('150'), 'isDefault': true});
MenuProduct product({List<Map<String, dynamic>> variants = const [], List<Map<String, dynamic>> groups = const []}) => MenuProduct.fromJson({
      'publicId': 'P1', 'name': 'Chai', 'price': money('100'), 'dietaryClass': 'veg', 'isAvailable': true, 'variants': variants, 'addonGroups': groups,
    });
final required = {'publicId': 'G1', 'name': 'Milk', 'minSelect': 1, 'maxSelect': 1, 'addons': [{'publicId': 'A1', 'name': 'Oat', 'price': money('20')}, {'publicId': 'A2', 'name': 'Soy', 'price': money('20')}]};

void main() {
  group('cart', () {
    test('the same selection merges; a different one does not', () {
      final p = product();
      final c = const Cart.empty().add(CartLine(product: p)).add(CartLine(product: p, quantity: 2)).add(CartLine(product: p, addons: [addon]));
      expect(c.lines.length, 2);
      expect(c.itemCount, 4);
    });
    test('preview total is exact', () {
      final c = const Cart.empty().add(CartLine(product: product(), variant: large, addons: [addon], quantity: 2));
      expect(c.previewTotal!.amount.toString(), '340');
    });
    test('quantity 0 removes the line', () {
      final line = CartLine(product: product());
      expect(const Cart.empty().add(line).setQuantity(line.key, 0).isEmpty, true);
    });
    test('the order request sends ids and quantities, and no price of any kind', () {
      final r = CartLine(product: product(), variant: large, addons: [addon], quantity: 2, notes: 'hot').toRequest();
      expect(r, {'productId': 'P1', 'variantId': 'V1', 'quantity': 2, 'addons': [{'addonId': 'A1'}], 'notes': 'hot'});
      expect(r.toString().contains('150'), false);
    });
  });

  group('selection rules', () {
    test('a variant is needed when the product has them', () {
      final p = product(variants: [{'publicId': 'V1', 'name': 'L', 'price': money('1'), 'isDefault': true}]);
      expect(selectionValid(p, null, const []), false);
      expect(selectionValid(p, p.variants.first, const []), true);
    });
    test('add-on group minimum and maximum', () {
      final p = product(groups: [required]);
      final a = p.addonGroups.first.addons;
      expect(selectionValid(p, null, const []), false);
      expect(selectionValid(p, null, [a[0]]), true);
      expect(selectionValid(p, null, a), false);
    });
  });

  blocTest<CartCubit, Cart>('the cubit adds and clears', build: CartCubit.new, act: (c) { c.add(CartLine(product: product())); c.clear(); }, expect: () => [isA<Cart>().having((x) => x.itemCount, 'n', 1), const Cart.empty()]);

  testWidgets('the product sheet holds back Add until required choices are made', (t) async {
    final cubit = CartCubit();
    await t.pumpWidget(MaterialApp(
      supportedLocales: supportedAppLocales,
      localizationsDelegates: appLocalizationDelegates,
      home: Scaffold(body: BlocProvider.value(value: cubit, child: ProductSheet(product: product(groups: [required])))),
    ));
    await t.pumpAndSettle();
    FilledButton button() => t.widget<FilledButton>(find.byType(FilledButton));
    expect(button().onPressed, isNull);
    await t.tap(find.text('Oat'));
    await t.pump();
    expect(button().onPressed, isNotNull);
  });

  testWidgets('the product sheet renders right to left in Arabic without overflow', (t) async {
    await t.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: supportedAppLocales,
      localizationsDelegates: appLocalizationDelegates,
      home: Scaffold(body: BlocProvider(create: (_) => CartCubit(), child: ProductSheet(product: product(groups: [required])))),
    ));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(Directionality.of(t.element(find.byType(ProductSheet))), TextDirection.rtl);
  });
}
