// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CafeOrder {

 String get publicId; int get orderNumber; String get status; String get paymentStatus; String? get tableNumber; String? get notes;@MoneyConverter() Money get subtotal;@MoneyConverter() Money get discount;@MoneyConverter() Money get tax;@MoneyConverter() Money get serviceCharge;@MoneyConverter() Money get total;@MoneyConverter() Money get paid;@MoneyConverter() Money get refunded; List<CafeOrderItem> get items;
/// Create a copy of CafeOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CafeOrderCopyWith<CafeOrder> get copyWith => _$CafeOrderCopyWithImpl<CafeOrder>(this as CafeOrder, _$identity);

  /// Serializes this CafeOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CafeOrder&&(identical(other.publicId, publicId) || other.publicId == publicId)&&(identical(other.orderNumber, orderNumber) || other.orderNumber == orderNumber)&&(identical(other.status, status) || other.status == status)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.tableNumber, tableNumber) || other.tableNumber == tableNumber)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.tax, tax) || other.tax == tax)&&(identical(other.serviceCharge, serviceCharge) || other.serviceCharge == serviceCharge)&&(identical(other.total, total) || other.total == total)&&(identical(other.paid, paid) || other.paid == paid)&&(identical(other.refunded, refunded) || other.refunded == refunded)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicId,orderNumber,status,paymentStatus,tableNumber,notes,subtotal,discount,tax,serviceCharge,total,paid,refunded,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'CafeOrder(publicId: $publicId, orderNumber: $orderNumber, status: $status, paymentStatus: $paymentStatus, tableNumber: $tableNumber, notes: $notes, subtotal: $subtotal, discount: $discount, tax: $tax, serviceCharge: $serviceCharge, total: $total, paid: $paid, refunded: $refunded, items: $items)';
}


}

/// @nodoc
abstract mixin class $CafeOrderCopyWith<$Res>  {
  factory $CafeOrderCopyWith(CafeOrder value, $Res Function(CafeOrder) _then) = _$CafeOrderCopyWithImpl;
@useResult
$Res call({
 String publicId, int orderNumber, String status, String paymentStatus, String? tableNumber, String? notes,@MoneyConverter() Money subtotal,@MoneyConverter() Money discount,@MoneyConverter() Money tax,@MoneyConverter() Money serviceCharge,@MoneyConverter() Money total,@MoneyConverter() Money paid,@MoneyConverter() Money refunded, List<CafeOrderItem> items
});




}
/// @nodoc
class _$CafeOrderCopyWithImpl<$Res>
    implements $CafeOrderCopyWith<$Res> {
  _$CafeOrderCopyWithImpl(this._self, this._then);

  final CafeOrder _self;
  final $Res Function(CafeOrder) _then;

/// Create a copy of CafeOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? publicId = null,Object? orderNumber = null,Object? status = null,Object? paymentStatus = null,Object? tableNumber = freezed,Object? notes = freezed,Object? subtotal = null,Object? discount = null,Object? tax = null,Object? serviceCharge = null,Object? total = null,Object? paid = null,Object? refunded = null,Object? items = null,}) {
  return _then(_self.copyWith(
publicId: null == publicId ? _self.publicId : publicId // ignore: cast_nullable_to_non_nullable
as String,orderNumber: null == orderNumber ? _self.orderNumber : orderNumber // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String,tableNumber: freezed == tableNumber ? _self.tableNumber : tableNumber // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as Money,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as Money,tax: null == tax ? _self.tax : tax // ignore: cast_nullable_to_non_nullable
as Money,serviceCharge: null == serviceCharge ? _self.serviceCharge : serviceCharge // ignore: cast_nullable_to_non_nullable
as Money,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as Money,paid: null == paid ? _self.paid : paid // ignore: cast_nullable_to_non_nullable
as Money,refunded: null == refunded ? _self.refunded : refunded // ignore: cast_nullable_to_non_nullable
as Money,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CafeOrderItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [CafeOrder].
extension CafeOrderPatterns on CafeOrder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CafeOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CafeOrder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CafeOrder value)  $default,){
final _that = this;
switch (_that) {
case _CafeOrder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CafeOrder value)?  $default,){
final _that = this;
switch (_that) {
case _CafeOrder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String publicId,  int orderNumber,  String status,  String paymentStatus,  String? tableNumber,  String? notes, @MoneyConverter()  Money subtotal, @MoneyConverter()  Money discount, @MoneyConverter()  Money tax, @MoneyConverter()  Money serviceCharge, @MoneyConverter()  Money total, @MoneyConverter()  Money paid, @MoneyConverter()  Money refunded,  List<CafeOrderItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CafeOrder() when $default != null:
return $default(_that.publicId,_that.orderNumber,_that.status,_that.paymentStatus,_that.tableNumber,_that.notes,_that.subtotal,_that.discount,_that.tax,_that.serviceCharge,_that.total,_that.paid,_that.refunded,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String publicId,  int orderNumber,  String status,  String paymentStatus,  String? tableNumber,  String? notes, @MoneyConverter()  Money subtotal, @MoneyConverter()  Money discount, @MoneyConverter()  Money tax, @MoneyConverter()  Money serviceCharge, @MoneyConverter()  Money total, @MoneyConverter()  Money paid, @MoneyConverter()  Money refunded,  List<CafeOrderItem> items)  $default,) {final _that = this;
switch (_that) {
case _CafeOrder():
return $default(_that.publicId,_that.orderNumber,_that.status,_that.paymentStatus,_that.tableNumber,_that.notes,_that.subtotal,_that.discount,_that.tax,_that.serviceCharge,_that.total,_that.paid,_that.refunded,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String publicId,  int orderNumber,  String status,  String paymentStatus,  String? tableNumber,  String? notes, @MoneyConverter()  Money subtotal, @MoneyConverter()  Money discount, @MoneyConverter()  Money tax, @MoneyConverter()  Money serviceCharge, @MoneyConverter()  Money total, @MoneyConverter()  Money paid, @MoneyConverter()  Money refunded,  List<CafeOrderItem> items)?  $default,) {final _that = this;
switch (_that) {
case _CafeOrder() when $default != null:
return $default(_that.publicId,_that.orderNumber,_that.status,_that.paymentStatus,_that.tableNumber,_that.notes,_that.subtotal,_that.discount,_that.tax,_that.serviceCharge,_that.total,_that.paid,_that.refunded,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CafeOrder implements CafeOrder {
  const _CafeOrder({required this.publicId, required this.orderNumber, required this.status, required this.paymentStatus, this.tableNumber, this.notes, @MoneyConverter() required this.subtotal, @MoneyConverter() required this.discount, @MoneyConverter() required this.tax, @MoneyConverter() required this.serviceCharge, @MoneyConverter() required this.total, @MoneyConverter() required this.paid, @MoneyConverter() required this.refunded, final  List<CafeOrderItem> items = const <CafeOrderItem>[]}): _items = items;
  factory _CafeOrder.fromJson(Map<String, dynamic> json) => _$CafeOrderFromJson(json);

@override final  String publicId;
@override final  int orderNumber;
@override final  String status;
@override final  String paymentStatus;
@override final  String? tableNumber;
@override final  String? notes;
@override@MoneyConverter() final  Money subtotal;
@override@MoneyConverter() final  Money discount;
@override@MoneyConverter() final  Money tax;
@override@MoneyConverter() final  Money serviceCharge;
@override@MoneyConverter() final  Money total;
@override@MoneyConverter() final  Money paid;
@override@MoneyConverter() final  Money refunded;
 final  List<CafeOrderItem> _items;
@override@JsonKey() List<CafeOrderItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of CafeOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CafeOrderCopyWith<_CafeOrder> get copyWith => __$CafeOrderCopyWithImpl<_CafeOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CafeOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CafeOrder&&(identical(other.publicId, publicId) || other.publicId == publicId)&&(identical(other.orderNumber, orderNumber) || other.orderNumber == orderNumber)&&(identical(other.status, status) || other.status == status)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.tableNumber, tableNumber) || other.tableNumber == tableNumber)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.tax, tax) || other.tax == tax)&&(identical(other.serviceCharge, serviceCharge) || other.serviceCharge == serviceCharge)&&(identical(other.total, total) || other.total == total)&&(identical(other.paid, paid) || other.paid == paid)&&(identical(other.refunded, refunded) || other.refunded == refunded)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicId,orderNumber,status,paymentStatus,tableNumber,notes,subtotal,discount,tax,serviceCharge,total,paid,refunded,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'CafeOrder(publicId: $publicId, orderNumber: $orderNumber, status: $status, paymentStatus: $paymentStatus, tableNumber: $tableNumber, notes: $notes, subtotal: $subtotal, discount: $discount, tax: $tax, serviceCharge: $serviceCharge, total: $total, paid: $paid, refunded: $refunded, items: $items)';
}


}

/// @nodoc
abstract mixin class _$CafeOrderCopyWith<$Res> implements $CafeOrderCopyWith<$Res> {
  factory _$CafeOrderCopyWith(_CafeOrder value, $Res Function(_CafeOrder) _then) = __$CafeOrderCopyWithImpl;
@override @useResult
$Res call({
 String publicId, int orderNumber, String status, String paymentStatus, String? tableNumber, String? notes,@MoneyConverter() Money subtotal,@MoneyConverter() Money discount,@MoneyConverter() Money tax,@MoneyConverter() Money serviceCharge,@MoneyConverter() Money total,@MoneyConverter() Money paid,@MoneyConverter() Money refunded, List<CafeOrderItem> items
});




}
/// @nodoc
class __$CafeOrderCopyWithImpl<$Res>
    implements _$CafeOrderCopyWith<$Res> {
  __$CafeOrderCopyWithImpl(this._self, this._then);

  final _CafeOrder _self;
  final $Res Function(_CafeOrder) _then;

/// Create a copy of CafeOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? publicId = null,Object? orderNumber = null,Object? status = null,Object? paymentStatus = null,Object? tableNumber = freezed,Object? notes = freezed,Object? subtotal = null,Object? discount = null,Object? tax = null,Object? serviceCharge = null,Object? total = null,Object? paid = null,Object? refunded = null,Object? items = null,}) {
  return _then(_CafeOrder(
publicId: null == publicId ? _self.publicId : publicId // ignore: cast_nullable_to_non_nullable
as String,orderNumber: null == orderNumber ? _self.orderNumber : orderNumber // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String,tableNumber: freezed == tableNumber ? _self.tableNumber : tableNumber // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as Money,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as Money,tax: null == tax ? _self.tax : tax // ignore: cast_nullable_to_non_nullable
as Money,serviceCharge: null == serviceCharge ? _self.serviceCharge : serviceCharge // ignore: cast_nullable_to_non_nullable
as Money,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as Money,paid: null == paid ? _self.paid : paid // ignore: cast_nullable_to_non_nullable
as Money,refunded: null == refunded ? _self.refunded : refunded // ignore: cast_nullable_to_non_nullable
as Money,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CafeOrderItem>,
  ));
}


}


/// @nodoc
mixin _$CafeOrderItem {

 int get id; String get name; String? get variant; int get quantity; String get status; String? get notes;@MoneyConverter() Money get lineTotal; List<CafeOrderItemAddon> get addons;
/// Create a copy of CafeOrderItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CafeOrderItemCopyWith<CafeOrderItem> get copyWith => _$CafeOrderItemCopyWithImpl<CafeOrderItem>(this as CafeOrderItem, _$identity);

  /// Serializes this CafeOrderItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CafeOrderItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal)&&const DeepCollectionEquality().equals(other.addons, addons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,variant,quantity,status,notes,lineTotal,const DeepCollectionEquality().hash(addons));

@override
String toString() {
  return 'CafeOrderItem(id: $id, name: $name, variant: $variant, quantity: $quantity, status: $status, notes: $notes, lineTotal: $lineTotal, addons: $addons)';
}


}

/// @nodoc
abstract mixin class $CafeOrderItemCopyWith<$Res>  {
  factory $CafeOrderItemCopyWith(CafeOrderItem value, $Res Function(CafeOrderItem) _then) = _$CafeOrderItemCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? variant, int quantity, String status, String? notes,@MoneyConverter() Money lineTotal, List<CafeOrderItemAddon> addons
});




}
/// @nodoc
class _$CafeOrderItemCopyWithImpl<$Res>
    implements $CafeOrderItemCopyWith<$Res> {
  _$CafeOrderItemCopyWithImpl(this._self, this._then);

  final CafeOrderItem _self;
  final $Res Function(CafeOrderItem) _then;

/// Create a copy of CafeOrderItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? variant = freezed,Object? quantity = null,Object? status = null,Object? notes = freezed,Object? lineTotal = null,Object? addons = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,variant: freezed == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as Money,addons: null == addons ? _self.addons : addons // ignore: cast_nullable_to_non_nullable
as List<CafeOrderItemAddon>,
  ));
}

}


/// Adds pattern-matching-related methods to [CafeOrderItem].
extension CafeOrderItemPatterns on CafeOrderItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CafeOrderItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CafeOrderItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CafeOrderItem value)  $default,){
final _that = this;
switch (_that) {
case _CafeOrderItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CafeOrderItem value)?  $default,){
final _that = this;
switch (_that) {
case _CafeOrderItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? variant,  int quantity,  String status,  String? notes, @MoneyConverter()  Money lineTotal,  List<CafeOrderItemAddon> addons)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CafeOrderItem() when $default != null:
return $default(_that.id,_that.name,_that.variant,_that.quantity,_that.status,_that.notes,_that.lineTotal,_that.addons);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? variant,  int quantity,  String status,  String? notes, @MoneyConverter()  Money lineTotal,  List<CafeOrderItemAddon> addons)  $default,) {final _that = this;
switch (_that) {
case _CafeOrderItem():
return $default(_that.id,_that.name,_that.variant,_that.quantity,_that.status,_that.notes,_that.lineTotal,_that.addons);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? variant,  int quantity,  String status,  String? notes, @MoneyConverter()  Money lineTotal,  List<CafeOrderItemAddon> addons)?  $default,) {final _that = this;
switch (_that) {
case _CafeOrderItem() when $default != null:
return $default(_that.id,_that.name,_that.variant,_that.quantity,_that.status,_that.notes,_that.lineTotal,_that.addons);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CafeOrderItem implements CafeOrderItem {
  const _CafeOrderItem({required this.id, required this.name, this.variant, required this.quantity, required this.status, this.notes, @MoneyConverter() required this.lineTotal, final  List<CafeOrderItemAddon> addons = const <CafeOrderItemAddon>[]}): _addons = addons;
  factory _CafeOrderItem.fromJson(Map<String, dynamic> json) => _$CafeOrderItemFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? variant;
@override final  int quantity;
@override final  String status;
@override final  String? notes;
@override@MoneyConverter() final  Money lineTotal;
 final  List<CafeOrderItemAddon> _addons;
@override@JsonKey() List<CafeOrderItemAddon> get addons {
  if (_addons is EqualUnmodifiableListView) return _addons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_addons);
}


/// Create a copy of CafeOrderItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CafeOrderItemCopyWith<_CafeOrderItem> get copyWith => __$CafeOrderItemCopyWithImpl<_CafeOrderItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CafeOrderItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CafeOrderItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal)&&const DeepCollectionEquality().equals(other._addons, _addons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,variant,quantity,status,notes,lineTotal,const DeepCollectionEquality().hash(_addons));

@override
String toString() {
  return 'CafeOrderItem(id: $id, name: $name, variant: $variant, quantity: $quantity, status: $status, notes: $notes, lineTotal: $lineTotal, addons: $addons)';
}


}

/// @nodoc
abstract mixin class _$CafeOrderItemCopyWith<$Res> implements $CafeOrderItemCopyWith<$Res> {
  factory _$CafeOrderItemCopyWith(_CafeOrderItem value, $Res Function(_CafeOrderItem) _then) = __$CafeOrderItemCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? variant, int quantity, String status, String? notes,@MoneyConverter() Money lineTotal, List<CafeOrderItemAddon> addons
});




}
/// @nodoc
class __$CafeOrderItemCopyWithImpl<$Res>
    implements _$CafeOrderItemCopyWith<$Res> {
  __$CafeOrderItemCopyWithImpl(this._self, this._then);

  final _CafeOrderItem _self;
  final $Res Function(_CafeOrderItem) _then;

/// Create a copy of CafeOrderItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? variant = freezed,Object? quantity = null,Object? status = null,Object? notes = freezed,Object? lineTotal = null,Object? addons = null,}) {
  return _then(_CafeOrderItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,variant: freezed == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as Money,addons: null == addons ? _self._addons : addons // ignore: cast_nullable_to_non_nullable
as List<CafeOrderItemAddon>,
  ));
}


}


/// @nodoc
mixin _$CafeOrderItemAddon {

 String get name; int get quantity;
/// Create a copy of CafeOrderItemAddon
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CafeOrderItemAddonCopyWith<CafeOrderItemAddon> get copyWith => _$CafeOrderItemAddonCopyWithImpl<CafeOrderItemAddon>(this as CafeOrderItemAddon, _$identity);

  /// Serializes this CafeOrderItemAddon to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CafeOrderItemAddon&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,quantity);

@override
String toString() {
  return 'CafeOrderItemAddon(name: $name, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class $CafeOrderItemAddonCopyWith<$Res>  {
  factory $CafeOrderItemAddonCopyWith(CafeOrderItemAddon value, $Res Function(CafeOrderItemAddon) _then) = _$CafeOrderItemAddonCopyWithImpl;
@useResult
$Res call({
 String name, int quantity
});




}
/// @nodoc
class _$CafeOrderItemAddonCopyWithImpl<$Res>
    implements $CafeOrderItemAddonCopyWith<$Res> {
  _$CafeOrderItemAddonCopyWithImpl(this._self, this._then);

  final CafeOrderItemAddon _self;
  final $Res Function(CafeOrderItemAddon) _then;

/// Create a copy of CafeOrderItemAddon
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? quantity = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CafeOrderItemAddon].
extension CafeOrderItemAddonPatterns on CafeOrderItemAddon {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CafeOrderItemAddon value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CafeOrderItemAddon() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CafeOrderItemAddon value)  $default,){
final _that = this;
switch (_that) {
case _CafeOrderItemAddon():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CafeOrderItemAddon value)?  $default,){
final _that = this;
switch (_that) {
case _CafeOrderItemAddon() when $default != null:
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
case _CafeOrderItemAddon() when $default != null:
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
case _CafeOrderItemAddon():
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
case _CafeOrderItemAddon() when $default != null:
return $default(_that.name,_that.quantity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CafeOrderItemAddon implements CafeOrderItemAddon {
  const _CafeOrderItemAddon({required this.name, required this.quantity});
  factory _CafeOrderItemAddon.fromJson(Map<String, dynamic> json) => _$CafeOrderItemAddonFromJson(json);

@override final  String name;
@override final  int quantity;

/// Create a copy of CafeOrderItemAddon
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CafeOrderItemAddonCopyWith<_CafeOrderItemAddon> get copyWith => __$CafeOrderItemAddonCopyWithImpl<_CafeOrderItemAddon>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CafeOrderItemAddonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CafeOrderItemAddon&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,quantity);

@override
String toString() {
  return 'CafeOrderItemAddon(name: $name, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class _$CafeOrderItemAddonCopyWith<$Res> implements $CafeOrderItemAddonCopyWith<$Res> {
  factory _$CafeOrderItemAddonCopyWith(_CafeOrderItemAddon value, $Res Function(_CafeOrderItemAddon) _then) = __$CafeOrderItemAddonCopyWithImpl;
@override @useResult
$Res call({
 String name, int quantity
});




}
/// @nodoc
class __$CafeOrderItemAddonCopyWithImpl<$Res>
    implements _$CafeOrderItemAddonCopyWith<$Res> {
  __$CafeOrderItemAddonCopyWithImpl(this._self, this._then);

  final _CafeOrderItemAddon _self;
  final $Res Function(_CafeOrderItemAddon) _then;

/// Create a copy of CafeOrderItemAddon
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? quantity = null,}) {
  return _then(_CafeOrderItemAddon(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
