import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_core/shared_core.dart';
import 'money_converter.dart';

part 'order.freezed.dart';
part 'order.g.dart';

@freezed
abstract class CafeOrder with _$CafeOrder {
  const factory CafeOrder({
    required String publicId,
    required int orderNumber,
    required String status,
    required String paymentStatus,
    String? tableNumber,
    String? notes,
    @MoneyConverter() required Money subtotal,
    @MoneyConverter() required Money discount,
    @MoneyConverter() required Money tax,
    @MoneyConverter() required Money serviceCharge,
    @MoneyConverter() required Money total,
    @MoneyConverter() required Money paid,
    @MoneyConverter() required Money refunded,
    @Default(<CafeOrderItem>[]) List<CafeOrderItem> items,
  }) = _CafeOrder;
  factory CafeOrder.fromJson(Map<String, dynamic> json) => _$CafeOrderFromJson(json);
}

@freezed
abstract class CafeOrderItem with _$CafeOrderItem {
  const factory CafeOrderItem({
    required int id,
    required String name,
    String? variant,
    required int quantity,
    required String status,
    String? notes,
    @MoneyConverter() required Money lineTotal,
    @Default(<CafeOrderItemAddon>[]) List<CafeOrderItemAddon> addons,
  }) = _CafeOrderItem;
  factory CafeOrderItem.fromJson(Map<String, dynamic> json) => _$CafeOrderItemFromJson(json);
}

@freezed
abstract class CafeOrderItemAddon with _$CafeOrderItemAddon {
  const factory CafeOrderItemAddon({required String name, required int quantity}) = _CafeOrderItemAddon;
  factory CafeOrderItemAddon.fromJson(Map<String, dynamic> json) => _$CafeOrderItemAddonFromJson(json);
}
