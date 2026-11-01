// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CafeOrder _$CafeOrderFromJson(Map<String, dynamic> json) => _CafeOrder(
  publicId: json['publicId'] as String,
  orderNumber: (json['orderNumber'] as num).toInt(),
  status: json['status'] as String,
  paymentStatus: json['paymentStatus'] as String,
  tableNumber: json['tableNumber'] as String?,
  notes: json['notes'] as String?,
  subtotal: const MoneyConverter().fromJson(
    json['subtotal'] as Map<String, dynamic>,
  ),
  discount: const MoneyConverter().fromJson(
    json['discount'] as Map<String, dynamic>,
  ),
  tax: const MoneyConverter().fromJson(json['tax'] as Map<String, dynamic>),
  serviceCharge: const MoneyConverter().fromJson(
    json['serviceCharge'] as Map<String, dynamic>,
  ),
  total: const MoneyConverter().fromJson(json['total'] as Map<String, dynamic>),
  paid: const MoneyConverter().fromJson(json['paid'] as Map<String, dynamic>),
  refunded: const MoneyConverter().fromJson(
    json['refunded'] as Map<String, dynamic>,
  ),
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => CafeOrderItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CafeOrderItem>[],
);

Map<String, dynamic> _$CafeOrderToJson(_CafeOrder instance) =>
    <String, dynamic>{
      'publicId': instance.publicId,
      'orderNumber': instance.orderNumber,
      'status': instance.status,
      'paymentStatus': instance.paymentStatus,
      'tableNumber': instance.tableNumber,
      'notes': instance.notes,
      'subtotal': const MoneyConverter().toJson(instance.subtotal),
      'discount': const MoneyConverter().toJson(instance.discount),
      'tax': const MoneyConverter().toJson(instance.tax),
      'serviceCharge': const MoneyConverter().toJson(instance.serviceCharge),
      'total': const MoneyConverter().toJson(instance.total),
      'paid': const MoneyConverter().toJson(instance.paid),
      'refunded': const MoneyConverter().toJson(instance.refunded),
      'items': instance.items,
    };

_CafeOrderItem _$CafeOrderItemFromJson(Map<String, dynamic> json) =>
    _CafeOrderItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      variant: json['variant'] as String?,
      quantity: (json['quantity'] as num).toInt(),
      status: json['status'] as String,
      notes: json['notes'] as String?,
      lineTotal: const MoneyConverter().fromJson(
        json['lineTotal'] as Map<String, dynamic>,
      ),
      addons:
          (json['addons'] as List<dynamic>?)
              ?.map(
                (e) => CafeOrderItemAddon.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <CafeOrderItemAddon>[],
    );

Map<String, dynamic> _$CafeOrderItemToJson(_CafeOrderItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'variant': instance.variant,
      'quantity': instance.quantity,
      'status': instance.status,
      'notes': instance.notes,
      'lineTotal': const MoneyConverter().toJson(instance.lineTotal),
      'addons': instance.addons,
    };

_CafeOrderItemAddon _$CafeOrderItemAddonFromJson(Map<String, dynamic> json) =>
    _CafeOrderItemAddon(
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$CafeOrderItemAddonToJson(_CafeOrderItemAddon instance) =>
    <String, dynamic>{'name': instance.name, 'quantity': instance.quantity};
