// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KitchenTicket _$KitchenTicketFromJson(Map<String, dynamic> json) =>
    _KitchenTicket(
      publicId: json['public_id'] as String,
      status: json['status'] as String,
      priority: (json['priority'] as num).toInt(),
      orderNumber: (json['order_number'] as num).toInt(),
      orderType: json['order_type'] as String,
      tableNumber: json['table_number'] as String?,
      customerNotes: json['customer_notes'] as String?,
      stationName: json['station_name'] as String?,
      stationId: json['station_id'] as String?,
      elapsedMinutes: (json['elapsedMinutes'] as num).toInt(),
      isDelayed: json['isDelayed'] as bool,
      items: (json['items'] as List<dynamic>)
          .map((e) => KitchenTicketItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$KitchenTicketToJson(_KitchenTicket instance) =>
    <String, dynamic>{
      'public_id': instance.publicId,
      'status': instance.status,
      'priority': instance.priority,
      'order_number': instance.orderNumber,
      'order_type': instance.orderType,
      'table_number': instance.tableNumber,
      'customer_notes': instance.customerNotes,
      'station_name': instance.stationName,
      'station_id': instance.stationId,
      'elapsedMinutes': instance.elapsedMinutes,
      'isDelayed': instance.isDelayed,
      'items': instance.items,
    };

_KitchenTicketItem _$KitchenTicketItemFromJson(Map<String, dynamic> json) =>
    _KitchenTicketItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      variant: json['variant'] as String?,
      quantity: (json['quantity'] as num).toInt(),
      notes: json['notes'] as String?,
      addons:
          (json['addons'] as List<dynamic>?)
              ?.map(
                (e) => KitchenTicketAddon.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <KitchenTicketAddon>[],
    );

Map<String, dynamic> _$KitchenTicketItemToJson(_KitchenTicketItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'variant': instance.variant,
      'quantity': instance.quantity,
      'notes': instance.notes,
      'addons': instance.addons,
    };

_KitchenTicketAddon _$KitchenTicketAddonFromJson(Map<String, dynamic> json) =>
    _KitchenTicketAddon(
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$KitchenTicketAddonToJson(_KitchenTicketAddon instance) =>
    <String, dynamic>{'name': instance.name, 'quantity': instance.quantity};
