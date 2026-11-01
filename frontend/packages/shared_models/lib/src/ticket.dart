import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket.freezed.dart';
part 'ticket.g.dart';

@freezed
abstract class KitchenTicket with _$KitchenTicket {
  const factory KitchenTicket({
    @JsonKey(name: 'public_id') required String publicId,
    required String status,
    required int priority,
    @JsonKey(name: 'order_number') required int orderNumber,
    @JsonKey(name: 'order_type') required String orderType,
    @JsonKey(name: 'table_number') String? tableNumber,
    @JsonKey(name: 'customer_notes') String? customerNotes,
    @JsonKey(name: 'station_name') String? stationName,
    @JsonKey(name: 'station_id') String? stationId,
    required int elapsedMinutes,
    required bool isDelayed,
    required List<KitchenTicketItem> items,
  }) = _KitchenTicket;
  factory KitchenTicket.fromJson(Map<String, dynamic> json) => _$KitchenTicketFromJson(json);
}

@freezed
abstract class KitchenTicketItem with _$KitchenTicketItem {
  const factory KitchenTicketItem({
    required int id,
    required String name,
    String? variant,
    required int quantity,
    String? notes,
    @Default(<KitchenTicketAddon>[]) List<KitchenTicketAddon> addons,
  }) = _KitchenTicketItem;
  factory KitchenTicketItem.fromJson(Map<String, dynamic> json) => _$KitchenTicketItemFromJson(json);
}

@freezed
abstract class KitchenTicketAddon with _$KitchenTicketAddon {
  const factory KitchenTicketAddon({required String name, required int quantity}) = _KitchenTicketAddon;
  factory KitchenTicketAddon.fromJson(Map<String, dynamic> json) => _$KitchenTicketAddonFromJson(json);
}
