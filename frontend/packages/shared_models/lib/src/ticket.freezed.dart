// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ticket.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KitchenTicket {

@JsonKey(name: 'public_id') String get publicId; String get status; int get priority;@JsonKey(name: 'order_number') int get orderNumber;@JsonKey(name: 'order_type') String get orderType;@JsonKey(name: 'table_number') String? get tableNumber;@JsonKey(name: 'customer_notes') String? get customerNotes;@JsonKey(name: 'station_name') String? get stationName;@JsonKey(name: 'station_id') String? get stationId; int get elapsedMinutes; bool get isDelayed; List<KitchenTicketItem> get items;
/// Create a copy of KitchenTicket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KitchenTicketCopyWith<KitchenTicket> get copyWith => _$KitchenTicketCopyWithImpl<KitchenTicket>(this as KitchenTicket, _$identity);

  /// Serializes this KitchenTicket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KitchenTicket&&(identical(other.publicId, publicId) || other.publicId == publicId)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.orderNumber, orderNumber) || other.orderNumber == orderNumber)&&(identical(other.orderType, orderType) || other.orderType == orderType)&&(identical(other.tableNumber, tableNumber) || other.tableNumber == tableNumber)&&(identical(other.customerNotes, customerNotes) || other.customerNotes == customerNotes)&&(identical(other.stationName, stationName) || other.stationName == stationName)&&(identical(other.stationId, stationId) || other.stationId == stationId)&&(identical(other.elapsedMinutes, elapsedMinutes) || other.elapsedMinutes == elapsedMinutes)&&(identical(other.isDelayed, isDelayed) || other.isDelayed == isDelayed)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicId,status,priority,orderNumber,orderType,tableNumber,customerNotes,stationName,stationId,elapsedMinutes,isDelayed,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'KitchenTicket(publicId: $publicId, status: $status, priority: $priority, orderNumber: $orderNumber, orderType: $orderType, tableNumber: $tableNumber, customerNotes: $customerNotes, stationName: $stationName, stationId: $stationId, elapsedMinutes: $elapsedMinutes, isDelayed: $isDelayed, items: $items)';
}


}

/// @nodoc
abstract mixin class $KitchenTicketCopyWith<$Res>  {
  factory $KitchenTicketCopyWith(KitchenTicket value, $Res Function(KitchenTicket) _then) = _$KitchenTicketCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'public_id') String publicId, String status, int priority,@JsonKey(name: 'order_number') int orderNumber,@JsonKey(name: 'order_type') String orderType,@JsonKey(name: 'table_number') String? tableNumber,@JsonKey(name: 'customer_notes') String? customerNotes,@JsonKey(name: 'station_name') String? stationName,@JsonKey(name: 'station_id') String? stationId, int elapsedMinutes, bool isDelayed, List<KitchenTicketItem> items
});




}
/// @nodoc
class _$KitchenTicketCopyWithImpl<$Res>
    implements $KitchenTicketCopyWith<$Res> {
  _$KitchenTicketCopyWithImpl(this._self, this._then);

  final KitchenTicket _self;
  final $Res Function(KitchenTicket) _then;

/// Create a copy of KitchenTicket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? publicId = null,Object? status = null,Object? priority = null,Object? orderNumber = null,Object? orderType = null,Object? tableNumber = freezed,Object? customerNotes = freezed,Object? stationName = freezed,Object? stationId = freezed,Object? elapsedMinutes = null,Object? isDelayed = null,Object? items = null,}) {
  return _then(_self.copyWith(
publicId: null == publicId ? _self.publicId : publicId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,orderNumber: null == orderNumber ? _self.orderNumber : orderNumber // ignore: cast_nullable_to_non_nullable
as int,orderType: null == orderType ? _self.orderType : orderType // ignore: cast_nullable_to_non_nullable
as String,tableNumber: freezed == tableNumber ? _self.tableNumber : tableNumber // ignore: cast_nullable_to_non_nullable
as String?,customerNotes: freezed == customerNotes ? _self.customerNotes : customerNotes // ignore: cast_nullable_to_non_nullable
as String?,stationName: freezed == stationName ? _self.stationName : stationName // ignore: cast_nullable_to_non_nullable
as String?,stationId: freezed == stationId ? _self.stationId : stationId // ignore: cast_nullable_to_non_nullable
as String?,elapsedMinutes: null == elapsedMinutes ? _self.elapsedMinutes : elapsedMinutes // ignore: cast_nullable_to_non_nullable
as int,isDelayed: null == isDelayed ? _self.isDelayed : isDelayed // ignore: cast_nullable_to_non_nullable
as bool,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<KitchenTicketItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [KitchenTicket].
extension KitchenTicketPatterns on KitchenTicket {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KitchenTicket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KitchenTicket() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KitchenTicket value)  $default,){
final _that = this;
switch (_that) {
case _KitchenTicket():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KitchenTicket value)?  $default,){
final _that = this;
switch (_that) {
case _KitchenTicket() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'public_id')  String publicId,  String status,  int priority, @JsonKey(name: 'order_number')  int orderNumber, @JsonKey(name: 'order_type')  String orderType, @JsonKey(name: 'table_number')  String? tableNumber, @JsonKey(name: 'customer_notes')  String? customerNotes, @JsonKey(name: 'station_name')  String? stationName, @JsonKey(name: 'station_id')  String? stationId,  int elapsedMinutes,  bool isDelayed,  List<KitchenTicketItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KitchenTicket() when $default != null:
return $default(_that.publicId,_that.status,_that.priority,_that.orderNumber,_that.orderType,_that.tableNumber,_that.customerNotes,_that.stationName,_that.stationId,_that.elapsedMinutes,_that.isDelayed,_that.items);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'public_id')  String publicId,  String status,  int priority, @JsonKey(name: 'order_number')  int orderNumber, @JsonKey(name: 'order_type')  String orderType, @JsonKey(name: 'table_number')  String? tableNumber, @JsonKey(name: 'customer_notes')  String? customerNotes, @JsonKey(name: 'station_name')  String? stationName, @JsonKey(name: 'station_id')  String? stationId,  int elapsedMinutes,  bool isDelayed,  List<KitchenTicketItem> items)  $default,) {final _that = this;
switch (_that) {
case _KitchenTicket():
return $default(_that.publicId,_that.status,_that.priority,_that.orderNumber,_that.orderType,_that.tableNumber,_that.customerNotes,_that.stationName,_that.stationId,_that.elapsedMinutes,_that.isDelayed,_that.items);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'public_id')  String publicId,  String status,  int priority, @JsonKey(name: 'order_number')  int orderNumber, @JsonKey(name: 'order_type')  String orderType, @JsonKey(name: 'table_number')  String? tableNumber, @JsonKey(name: 'customer_notes')  String? customerNotes, @JsonKey(name: 'station_name')  String? stationName, @JsonKey(name: 'station_id')  String? stationId,  int elapsedMinutes,  bool isDelayed,  List<KitchenTicketItem> items)?  $default,) {final _that = this;
switch (_that) {
case _KitchenTicket() when $default != null:
return $default(_that.publicId,_that.status,_that.priority,_that.orderNumber,_that.orderType,_that.tableNumber,_that.customerNotes,_that.stationName,_that.stationId,_that.elapsedMinutes,_that.isDelayed,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KitchenTicket implements KitchenTicket {
  const _KitchenTicket({@JsonKey(name: 'public_id') required this.publicId, required this.status, required this.priority, @JsonKey(name: 'order_number') required this.orderNumber, @JsonKey(name: 'order_type') required this.orderType, @JsonKey(name: 'table_number') this.tableNumber, @JsonKey(name: 'customer_notes') this.customerNotes, @JsonKey(name: 'station_name') this.stationName, @JsonKey(name: 'station_id') this.stationId, required this.elapsedMinutes, required this.isDelayed, required final  List<KitchenTicketItem> items}): _items = items;
  factory _KitchenTicket.fromJson(Map<String, dynamic> json) => _$KitchenTicketFromJson(json);

@override@JsonKey(name: 'public_id') final  String publicId;
@override final  String status;
@override final  int priority;
@override@JsonKey(name: 'order_number') final  int orderNumber;
@override@JsonKey(name: 'order_type') final  String orderType;
@override@JsonKey(name: 'table_number') final  String? tableNumber;
@override@JsonKey(name: 'customer_notes') final  String? customerNotes;
@override@JsonKey(name: 'station_name') final  String? stationName;
@override@JsonKey(name: 'station_id') final  String? stationId;
@override final  int elapsedMinutes;
@override final  bool isDelayed;
 final  List<KitchenTicketItem> _items;
@override List<KitchenTicketItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of KitchenTicket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KitchenTicketCopyWith<_KitchenTicket> get copyWith => __$KitchenTicketCopyWithImpl<_KitchenTicket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KitchenTicketToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KitchenTicket&&(identical(other.publicId, publicId) || other.publicId == publicId)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.orderNumber, orderNumber) || other.orderNumber == orderNumber)&&(identical(other.orderType, orderType) || other.orderType == orderType)&&(identical(other.tableNumber, tableNumber) || other.tableNumber == tableNumber)&&(identical(other.customerNotes, customerNotes) || other.customerNotes == customerNotes)&&(identical(other.stationName, stationName) || other.stationName == stationName)&&(identical(other.stationId, stationId) || other.stationId == stationId)&&(identical(other.elapsedMinutes, elapsedMinutes) || other.elapsedMinutes == elapsedMinutes)&&(identical(other.isDelayed, isDelayed) || other.isDelayed == isDelayed)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicId,status,priority,orderNumber,orderType,tableNumber,customerNotes,stationName,stationId,elapsedMinutes,isDelayed,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'KitchenTicket(publicId: $publicId, status: $status, priority: $priority, orderNumber: $orderNumber, orderType: $orderType, tableNumber: $tableNumber, customerNotes: $customerNotes, stationName: $stationName, stationId: $stationId, elapsedMinutes: $elapsedMinutes, isDelayed: $isDelayed, items: $items)';
}


}

/// @nodoc
abstract mixin class _$KitchenTicketCopyWith<$Res> implements $KitchenTicketCopyWith<$Res> {
  factory _$KitchenTicketCopyWith(_KitchenTicket value, $Res Function(_KitchenTicket) _then) = __$KitchenTicketCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'public_id') String publicId, String status, int priority,@JsonKey(name: 'order_number') int orderNumber,@JsonKey(name: 'order_type') String orderType,@JsonKey(name: 'table_number') String? tableNumber,@JsonKey(name: 'customer_notes') String? customerNotes,@JsonKey(name: 'station_name') String? stationName,@JsonKey(name: 'station_id') String? stationId, int elapsedMinutes, bool isDelayed, List<KitchenTicketItem> items
});




}
/// @nodoc
class __$KitchenTicketCopyWithImpl<$Res>
    implements _$KitchenTicketCopyWith<$Res> {
  __$KitchenTicketCopyWithImpl(this._self, this._then);

  final _KitchenTicket _self;
  final $Res Function(_KitchenTicket) _then;

/// Create a copy of KitchenTicket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? publicId = null,Object? status = null,Object? priority = null,Object? orderNumber = null,Object? orderType = null,Object? tableNumber = freezed,Object? customerNotes = freezed,Object? stationName = freezed,Object? stationId = freezed,Object? elapsedMinutes = null,Object? isDelayed = null,Object? items = null,}) {
  return _then(_KitchenTicket(
publicId: null == publicId ? _self.publicId : publicId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,orderNumber: null == orderNumber ? _self.orderNumber : orderNumber // ignore: cast_nullable_to_non_nullable
as int,orderType: null == orderType ? _self.orderType : orderType // ignore: cast_nullable_to_non_nullable
as String,tableNumber: freezed == tableNumber ? _self.tableNumber : tableNumber // ignore: cast_nullable_to_non_nullable
as String?,customerNotes: freezed == customerNotes ? _self.customerNotes : customerNotes // ignore: cast_nullable_to_non_nullable
as String?,stationName: freezed == stationName ? _self.stationName : stationName // ignore: cast_nullable_to_non_nullable
as String?,stationId: freezed == stationId ? _self.stationId : stationId // ignore: cast_nullable_to_non_nullable
as String?,elapsedMinutes: null == elapsedMinutes ? _self.elapsedMinutes : elapsedMinutes // ignore: cast_nullable_to_non_nullable
as int,isDelayed: null == isDelayed ? _self.isDelayed : isDelayed // ignore: cast_nullable_to_non_nullable
as bool,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<KitchenTicketItem>,
  ));
}


}


/// @nodoc
mixin _$KitchenTicketItem {

 int get id; String get name; String? get variant; int get quantity; String? get notes; List<KitchenTicketAddon> get addons;
/// Create a copy of KitchenTicketItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KitchenTicketItemCopyWith<KitchenTicketItem> get copyWith => _$KitchenTicketItemCopyWithImpl<KitchenTicketItem>(this as KitchenTicketItem, _$identity);

  /// Serializes this KitchenTicketItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KitchenTicketItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other.addons, addons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,variant,quantity,notes,const DeepCollectionEquality().hash(addons));

@override
String toString() {
  return 'KitchenTicketItem(id: $id, name: $name, variant: $variant, quantity: $quantity, notes: $notes, addons: $addons)';
}


}

/// @nodoc
abstract mixin class $KitchenTicketItemCopyWith<$Res>  {
  factory $KitchenTicketItemCopyWith(KitchenTicketItem value, $Res Function(KitchenTicketItem) _then) = _$KitchenTicketItemCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? variant, int quantity, String? notes, List<KitchenTicketAddon> addons
});




}
/// @nodoc
class _$KitchenTicketItemCopyWithImpl<$Res>
    implements $KitchenTicketItemCopyWith<$Res> {
  _$KitchenTicketItemCopyWithImpl(this._self, this._then);

  final KitchenTicketItem _self;
  final $Res Function(KitchenTicketItem) _then;

/// Create a copy of KitchenTicketItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? variant = freezed,Object? quantity = null,Object? notes = freezed,Object? addons = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,variant: freezed == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,addons: null == addons ? _self.addons : addons // ignore: cast_nullable_to_non_nullable
as List<KitchenTicketAddon>,
  ));
}

}


/// Adds pattern-matching-related methods to [KitchenTicketItem].
extension KitchenTicketItemPatterns on KitchenTicketItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KitchenTicketItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KitchenTicketItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KitchenTicketItem value)  $default,){
final _that = this;
switch (_that) {
case _KitchenTicketItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KitchenTicketItem value)?  $default,){
final _that = this;
switch (_that) {
case _KitchenTicketItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? variant,  int quantity,  String? notes,  List<KitchenTicketAddon> addons)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KitchenTicketItem() when $default != null:
return $default(_that.id,_that.name,_that.variant,_that.quantity,_that.notes,_that.addons);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? variant,  int quantity,  String? notes,  List<KitchenTicketAddon> addons)  $default,) {final _that = this;
switch (_that) {
case _KitchenTicketItem():
return $default(_that.id,_that.name,_that.variant,_that.quantity,_that.notes,_that.addons);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? variant,  int quantity,  String? notes,  List<KitchenTicketAddon> addons)?  $default,) {final _that = this;
switch (_that) {
case _KitchenTicketItem() when $default != null:
return $default(_that.id,_that.name,_that.variant,_that.quantity,_that.notes,_that.addons);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KitchenTicketItem implements KitchenTicketItem {
  const _KitchenTicketItem({required this.id, required this.name, this.variant, required this.quantity, this.notes, final  List<KitchenTicketAddon> addons = const <KitchenTicketAddon>[]}): _addons = addons;
  factory _KitchenTicketItem.fromJson(Map<String, dynamic> json) => _$KitchenTicketItemFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? variant;
@override final  int quantity;
@override final  String? notes;
 final  List<KitchenTicketAddon> _addons;
@override@JsonKey() List<KitchenTicketAddon> get addons {
  if (_addons is EqualUnmodifiableListView) return _addons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_addons);
}


/// Create a copy of KitchenTicketItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KitchenTicketItemCopyWith<_KitchenTicketItem> get copyWith => __$KitchenTicketItemCopyWithImpl<_KitchenTicketItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KitchenTicketItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KitchenTicketItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other._addons, _addons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,variant,quantity,notes,const DeepCollectionEquality().hash(_addons));

@override
String toString() {
  return 'KitchenTicketItem(id: $id, name: $name, variant: $variant, quantity: $quantity, notes: $notes, addons: $addons)';
}


}

/// @nodoc
abstract mixin class _$KitchenTicketItemCopyWith<$Res> implements $KitchenTicketItemCopyWith<$Res> {
  factory _$KitchenTicketItemCopyWith(_KitchenTicketItem value, $Res Function(_KitchenTicketItem) _then) = __$KitchenTicketItemCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? variant, int quantity, String? notes, List<KitchenTicketAddon> addons
});




}
/// @nodoc
class __$KitchenTicketItemCopyWithImpl<$Res>
    implements _$KitchenTicketItemCopyWith<$Res> {
  __$KitchenTicketItemCopyWithImpl(this._self, this._then);

  final _KitchenTicketItem _self;
  final $Res Function(_KitchenTicketItem) _then;

/// Create a copy of KitchenTicketItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? variant = freezed,Object? quantity = null,Object? notes = freezed,Object? addons = null,}) {
  return _then(_KitchenTicketItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,variant: freezed == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,addons: null == addons ? _self._addons : addons // ignore: cast_nullable_to_non_nullable
as List<KitchenTicketAddon>,
  ));
}


}


/// @nodoc
mixin _$KitchenTicketAddon {

 String get name; int get quantity;
/// Create a copy of KitchenTicketAddon
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KitchenTicketAddonCopyWith<KitchenTicketAddon> get copyWith => _$KitchenTicketAddonCopyWithImpl<KitchenTicketAddon>(this as KitchenTicketAddon, _$identity);

  /// Serializes this KitchenTicketAddon to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KitchenTicketAddon&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,quantity);

@override
String toString() {
  return 'KitchenTicketAddon(name: $name, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class $KitchenTicketAddonCopyWith<$Res>  {
  factory $KitchenTicketAddonCopyWith(KitchenTicketAddon value, $Res Function(KitchenTicketAddon) _then) = _$KitchenTicketAddonCopyWithImpl;
@useResult
$Res call({
 String name, int quantity
});




}
/// @nodoc
class _$KitchenTicketAddonCopyWithImpl<$Res>
    implements $KitchenTicketAddonCopyWith<$Res> {
  _$KitchenTicketAddonCopyWithImpl(this._self, this._then);

  final KitchenTicketAddon _self;
  final $Res Function(KitchenTicketAddon) _then;

/// Create a copy of KitchenTicketAddon
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? quantity = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [KitchenTicketAddon].
extension KitchenTicketAddonPatterns on KitchenTicketAddon {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KitchenTicketAddon value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KitchenTicketAddon() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KitchenTicketAddon value)  $default,){
final _that = this;
switch (_that) {
case _KitchenTicketAddon():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KitchenTicketAddon value)?  $default,){
final _that = this;
switch (_that) {
case _KitchenTicketAddon() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int quantity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KitchenTicketAddon() when $default != null:
return $default(_that.name,_that.quantity);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int quantity)  $default,) {final _that = this;
switch (_that) {
case _KitchenTicketAddon():
return $default(_that.name,_that.quantity);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int quantity)?  $default,) {final _that = this;
switch (_that) {
case _KitchenTicketAddon() when $default != null:
return $default(_that.name,_that.quantity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KitchenTicketAddon implements KitchenTicketAddon {
  const _KitchenTicketAddon({required this.name, required this.quantity});
  factory _KitchenTicketAddon.fromJson(Map<String, dynamic> json) => _$KitchenTicketAddonFromJson(json);

@override final  String name;
@override final  int quantity;

/// Create a copy of KitchenTicketAddon
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KitchenTicketAddonCopyWith<_KitchenTicketAddon> get copyWith => __$KitchenTicketAddonCopyWithImpl<_KitchenTicketAddon>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KitchenTicketAddonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KitchenTicketAddon&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,quantity);

@override
String toString() {
  return 'KitchenTicketAddon(name: $name, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class _$KitchenTicketAddonCopyWith<$Res> implements $KitchenTicketAddonCopyWith<$Res> {
  factory _$KitchenTicketAddonCopyWith(_KitchenTicketAddon value, $Res Function(_KitchenTicketAddon) _then) = __$KitchenTicketAddonCopyWithImpl;
@override @useResult
$Res call({
 String name, int quantity
});




}
/// @nodoc
class __$KitchenTicketAddonCopyWithImpl<$Res>
    implements _$KitchenTicketAddonCopyWith<$Res> {
  __$KitchenTicketAddonCopyWithImpl(this._self, this._then);

  final _KitchenTicketAddon _self;
  final $Res Function(_KitchenTicketAddon) _then;

/// Create a copy of KitchenTicketAddon
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? quantity = null,}) {
  return _then(_KitchenTicketAddon(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
