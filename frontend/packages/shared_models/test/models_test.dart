import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  test('money comes through exactly from string amounts', () {
    final p = MenuProduct.fromJson({
      'publicId': 'P', 'name': 'Chai', 'price': {'amount': '0.1', 'currency': 'INR'}, 'dietaryClass': 'veg', 'isAvailable': true,
      'variants': [{'publicId': 'V', 'name': 'L', 'price': {'amount': '150.25', 'currency': 'INR'}, 'isDefault': true}],
    });
    expect(p.price.amount.toString(), '0.1');
    expect(p.variants.single.price.amount.toString(), '150.25');
    expect(p.addonGroups, isEmpty);
  });

  test('a kitchen ticket maps snake_case API fields', () {
    final t = KitchenTicket.fromJson({'public_id': 'T', 'status': 'new', 'priority': 0, 'order_number': 7, 'order_type': 'dine_in', 'table_number': 'T1', 'elapsedMinutes': 3, 'isDelayed': false, 'items': [{'id': 1, 'name': 'X', 'quantity': 2, 'addons': [{'name': 'Y', 'quantity': 1}]}]});
    expect(t.orderNumber, 7);
    expect(t.items.single.addons.single.name, 'Y');
  });
}
