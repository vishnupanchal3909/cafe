// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'menu.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Menu {

 String get language; String get currency; List<MenuCategory> get categories; List<MenuProduct> get products;
/// Create a copy of Menu
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuCopyWith<Menu> get copyWith => _$MenuCopyWithImpl<Menu>(this as Menu, _$identity);

  /// Serializes this Menu to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Menu&&(identical(other.language, language) || other.language == language)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.products, products));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,currency,const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(products));

@override
String toString() {
  return 'Menu(language: $language, currency: $currency, categories: $categories, products: $products)';
}


}

/// @nodoc
abstract mixin class $MenuCopyWith<$Res>  {
  factory $MenuCopyWith(Menu value, $Res Function(Menu) _then) = _$MenuCopyWithImpl;
@useResult
$Res call({
 String language, String currency, List<MenuCategory> categories, List<MenuProduct> products
});




}
/// @nodoc
class _$MenuCopyWithImpl<$Res>
    implements $MenuCopyWith<$Res> {
  _$MenuCopyWithImpl(this._self, this._then);

  final Menu _self;
  final $Res Function(Menu) _then;

/// Create a copy of Menu
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? language = null,Object? currency = null,Object? categories = null,Object? products = null,}) {
  return _then(_self.copyWith(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<MenuCategory>,products: null == products ? _self.products : products // ignore: cast_nullable_to_non_nullable
as List<MenuProduct>,
  ));
}

}


/// Adds pattern-matching-related methods to [Menu].
extension MenuPatterns on Menu {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Menu value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Menu() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Menu value)  $default,){
final _that = this;
switch (_that) {
case _Menu():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Menu value)?  $default,){
final _that = this;
switch (_that) {
case _Menu() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String language,  String currency,  List<MenuCategory> categories,  List<MenuProduct> products)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Menu() when $default != null:
return $default(_that.language,_that.currency,_that.categories,_that.products);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String language,  String currency,  List<MenuCategory> categories,  List<MenuProduct> products)  $default,) {final _that = this;
switch (_that) {
case _Menu():
return $default(_that.language,_that.currency,_that.categories,_that.products);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String language,  String currency,  List<MenuCategory> categories,  List<MenuProduct> products)?  $default,) {final _that = this;
switch (_that) {
case _Menu() when $default != null:
return $default(_that.language,_that.currency,_that.categories,_that.products);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Menu implements Menu {
  const _Menu({required this.language, required this.currency, required final  List<MenuCategory> categories, required final  List<MenuProduct> products}): _categories = categories,_products = products;
  factory _Menu.fromJson(Map<String, dynamic> json) => _$MenuFromJson(json);

@override final  String language;
@override final  String currency;
 final  List<MenuCategory> _categories;
@override List<MenuCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<MenuProduct> _products;
@override List<MenuProduct> get products {
  if (_products is EqualUnmodifiableListView) return _products;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_products);
}


/// Create a copy of Menu
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuCopyWith<_Menu> get copyWith => __$MenuCopyWithImpl<_Menu>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Menu&&(identical(other.language, language) || other.language == language)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._products, _products));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,currency,const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_products));

@override
String toString() {
  return 'Menu(language: $language, currency: $currency, categories: $categories, products: $products)';
}


}

/// @nodoc
abstract mixin class _$MenuCopyWith<$Res> implements $MenuCopyWith<$Res> {
  factory _$MenuCopyWith(_Menu value, $Res Function(_Menu) _then) = __$MenuCopyWithImpl;
@override @useResult
$Res call({
 String language, String currency, List<MenuCategory> categories, List<MenuProduct> products
});




}
/// @nodoc
class __$MenuCopyWithImpl<$Res>
    implements _$MenuCopyWith<$Res> {
  __$MenuCopyWithImpl(this._self, this._then);

  final _Menu _self;
  final $Res Function(_Menu) _then;

/// Create a copy of Menu
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? language = null,Object? currency = null,Object? categories = null,Object? products = null,}) {
  return _then(_Menu(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<MenuCategory>,products: null == products ? _self._products : products // ignore: cast_nullable_to_non_nullable
as List<MenuProduct>,
  ));
}


}


/// @nodoc
mixin _$MenuCategory {

 String get publicId; String get name; String? get description; int get sortOrder; bool get isActive;
/// Create a copy of MenuCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuCategoryCopyWith<MenuCategory> get copyWith => _$MenuCategoryCopyWithImpl<MenuCategory>(this as MenuCategory, _$identity);

  /// Serializes this MenuCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuCategory&&(identical(other.publicId, publicId) || other.publicId == publicId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicId,name,description,sortOrder,isActive);

@override
String toString() {
  return 'MenuCategory(publicId: $publicId, name: $name, description: $description, sortOrder: $sortOrder, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $MenuCategoryCopyWith<$Res>  {
  factory $MenuCategoryCopyWith(MenuCategory value, $Res Function(MenuCategory) _then) = _$MenuCategoryCopyWithImpl;
@useResult
$Res call({
 String publicId, String name, String? description, int sortOrder, bool isActive
});




}
/// @nodoc
class _$MenuCategoryCopyWithImpl<$Res>
    implements $MenuCategoryCopyWith<$Res> {
  _$MenuCategoryCopyWithImpl(this._self, this._then);

  final MenuCategory _self;
  final $Res Function(MenuCategory) _then;

/// Create a copy of MenuCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? publicId = null,Object? name = null,Object? description = freezed,Object? sortOrder = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
publicId: null == publicId ? _self.publicId : publicId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuCategory].
extension MenuCategoryPatterns on MenuCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuCategory value)  $default,){
final _that = this;
switch (_that) {
case _MenuCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuCategory value)?  $default,){
final _that = this;
switch (_that) {
case _MenuCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String publicId,  String name,  String? description,  int sortOrder,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuCategory() when $default != null:
return $default(_that.publicId,_that.name,_that.description,_that.sortOrder,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String publicId,  String name,  String? description,  int sortOrder,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _MenuCategory():
return $default(_that.publicId,_that.name,_that.description,_that.sortOrder,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String publicId,  String name,  String? description,  int sortOrder,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _MenuCategory() when $default != null:
return $default(_that.publicId,_that.name,_that.description,_that.sortOrder,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuCategory implements MenuCategory {
  const _MenuCategory({required this.publicId, required this.name, this.description, required this.sortOrder, required this.isActive});
  factory _MenuCategory.fromJson(Map<String, dynamic> json) => _$MenuCategoryFromJson(json);

@override final  String publicId;
@override final  String name;
@override final  String? description;
@override final  int sortOrder;
@override final  bool isActive;

/// Create a copy of MenuCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuCategoryCopyWith<_MenuCategory> get copyWith => __$MenuCategoryCopyWithImpl<_MenuCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuCategory&&(identical(other.publicId, publicId) || other.publicId == publicId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicId,name,description,sortOrder,isActive);

@override
String toString() {
  return 'MenuCategory(publicId: $publicId, name: $name, description: $description, sortOrder: $sortOrder, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$MenuCategoryCopyWith<$Res> implements $MenuCategoryCopyWith<$Res> {
  factory _$MenuCategoryCopyWith(_MenuCategory value, $Res Function(_MenuCategory) _then) = __$MenuCategoryCopyWithImpl;
@override @useResult
$Res call({
 String publicId, String name, String? description, int sortOrder, bool isActive
});




}
/// @nodoc
class __$MenuCategoryCopyWithImpl<$Res>
    implements _$MenuCategoryCopyWith<$Res> {
  __$MenuCategoryCopyWithImpl(this._self, this._then);

  final _MenuCategory _self;
  final $Res Function(_MenuCategory) _then;

/// Create a copy of MenuCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? publicId = null,Object? name = null,Object? description = freezed,Object? sortOrder = null,Object? isActive = null,}) {
  return _then(_MenuCategory(
publicId: null == publicId ? _self.publicId : publicId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$MenuProduct {

 String get publicId; String? get categoryId; String get name; String? get description;@MoneyConverter() Money get price; String get dietaryClass; bool get isAvailable; bool get isActive; bool get isOutOfStock; List<String> get imageUrls; List<MenuVariant> get variants; List<MenuAddonGroup> get addonGroups;
/// Create a copy of MenuProduct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuProductCopyWith<MenuProduct> get copyWith => _$MenuProductCopyWithImpl<MenuProduct>(this as MenuProduct, _$identity);

  /// Serializes this MenuProduct to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuProduct&&(identical(other.publicId, publicId) || other.publicId == publicId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.dietaryClass, dietaryClass) || other.dietaryClass == dietaryClass)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isOutOfStock, isOutOfStock) || other.isOutOfStock == isOutOfStock)&&const DeepCollectionEquality().equals(other.imageUrls, imageUrls)&&const DeepCollectionEquality().equals(other.variants, variants)&&const DeepCollectionEquality().equals(other.addonGroups, addonGroups));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicId,categoryId,name,description,price,dietaryClass,isAvailable,isActive,isOutOfStock,const DeepCollectionEquality().hash(imageUrls),const DeepCollectionEquality().hash(variants),const DeepCollectionEquality().hash(addonGroups));

@override
String toString() {
  return 'MenuProduct(publicId: $publicId, categoryId: $categoryId, name: $name, description: $description, price: $price, dietaryClass: $dietaryClass, isAvailable: $isAvailable, isActive: $isActive, isOutOfStock: $isOutOfStock, imageUrls: $imageUrls, variants: $variants, addonGroups: $addonGroups)';
}


}

/// @nodoc
abstract mixin class $MenuProductCopyWith<$Res>  {
  factory $MenuProductCopyWith(MenuProduct value, $Res Function(MenuProduct) _then) = _$MenuProductCopyWithImpl;
@useResult
$Res call({
 String publicId, String? categoryId, String name, String? description,@MoneyConverter() Money price, String dietaryClass, bool isAvailable, bool isActive, bool isOutOfStock, List<String> imageUrls, List<MenuVariant> variants, List<MenuAddonGroup> addonGroups
});




}
/// @nodoc
class _$MenuProductCopyWithImpl<$Res>
    implements $MenuProductCopyWith<$Res> {
  _$MenuProductCopyWithImpl(this._self, this._then);

  final MenuProduct _self;
  final $Res Function(MenuProduct) _then;

/// Create a copy of MenuProduct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? publicId = null,Object? categoryId = freezed,Object? name = null,Object? description = freezed,Object? price = null,Object? dietaryClass = null,Object? isAvailable = null,Object? isActive = null,Object? isOutOfStock = null,Object? imageUrls = null,Object? variants = null,Object? addonGroups = null,}) {
  return _then(_self.copyWith(
publicId: null == publicId ? _self.publicId : publicId // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Money,dietaryClass: null == dietaryClass ? _self.dietaryClass : dietaryClass // ignore: cast_nullable_to_non_nullable
as String,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isOutOfStock: null == isOutOfStock ? _self.isOutOfStock : isOutOfStock // ignore: cast_nullable_to_non_nullable
as bool,imageUrls: null == imageUrls ? _self.imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,variants: null == variants ? _self.variants : variants // ignore: cast_nullable_to_non_nullable
as List<MenuVariant>,addonGroups: null == addonGroups ? _self.addonGroups : addonGroups // ignore: cast_nullable_to_non_nullable
as List<MenuAddonGroup>,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuProduct].
extension MenuProductPatterns on MenuProduct {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuProduct value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuProduct() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuProduct value)  $default,){
final _that = this;
switch (_that) {
case _MenuProduct():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuProduct value)?  $default,){
final _that = this;
switch (_that) {
case _MenuProduct() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String publicId,  String? categoryId,  String name,  String? description, @MoneyConverter()  Money price,  String dietaryClass,  bool isAvailable,  bool isActive,  bool isOutOfStock,  List<String> imageUrls,  List<MenuVariant> variants,  List<MenuAddonGroup> addonGroups)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuProduct() when $default != null:
return $default(_that.publicId,_that.categoryId,_that.name,_that.description,_that.price,_that.dietaryClass,_that.isAvailable,_that.isActive,_that.isOutOfStock,_that.imageUrls,_that.variants,_that.addonGroups);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String publicId,  String? categoryId,  String name,  String? description, @MoneyConverter()  Money price,  String dietaryClass,  bool isAvailable,  bool isActive,  bool isOutOfStock,  List<String> imageUrls,  List<MenuVariant> variants,  List<MenuAddonGroup> addonGroups)  $default,) {final _that = this;
switch (_that) {
case _MenuProduct():
return $default(_that.publicId,_that.categoryId,_that.name,_that.description,_that.price,_that.dietaryClass,_that.isAvailable,_that.isActive,_that.isOutOfStock,_that.imageUrls,_that.variants,_that.addonGroups);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String publicId,  String? categoryId,  String name,  String? description, @MoneyConverter()  Money price,  String dietaryClass,  bool isAvailable,  bool isActive,  bool isOutOfStock,  List<String> imageUrls,  List<MenuVariant> variants,  List<MenuAddonGroup> addonGroups)?  $default,) {final _that = this;
switch (_that) {
case _MenuProduct() when $default != null:
return $default(_that.publicId,_that.categoryId,_that.name,_that.description,_that.price,_that.dietaryClass,_that.isAvailable,_that.isActive,_that.isOutOfStock,_that.imageUrls,_that.variants,_that.addonGroups);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuProduct implements MenuProduct {
  const _MenuProduct({required this.publicId, this.categoryId, required this.name, this.description, @MoneyConverter() required this.price, required this.dietaryClass, required this.isAvailable, this.isActive = true, this.isOutOfStock = false, final  List<String> imageUrls = const <String>[], final  List<MenuVariant> variants = const <MenuVariant>[], final  List<MenuAddonGroup> addonGroups = const <MenuAddonGroup>[]}): _imageUrls = imageUrls,_variants = variants,_addonGroups = addonGroups;
  factory _MenuProduct.fromJson(Map<String, dynamic> json) => _$MenuProductFromJson(json);

@override final  String publicId;
@override final  String? categoryId;
@override final  String name;
@override final  String? description;
@override@MoneyConverter() final  Money price;
@override final  String dietaryClass;
@override final  bool isAvailable;
@override@JsonKey() final  bool isActive;
@override@JsonKey() final  bool isOutOfStock;
 final  List<String> _imageUrls;
@override@JsonKey() List<String> get imageUrls {
  if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_imageUrls);
}

 final  List<MenuVariant> _variants;
@override@JsonKey() List<MenuVariant> get variants {
  if (_variants is EqualUnmodifiableListView) return _variants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_variants);
}

 final  List<MenuAddonGroup> _addonGroups;
@override@JsonKey() List<MenuAddonGroup> get addonGroups {
  if (_addonGroups is EqualUnmodifiableListView) return _addonGroups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_addonGroups);
}


/// Create a copy of MenuProduct
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuProductCopyWith<_MenuProduct> get copyWith => __$MenuProductCopyWithImpl<_MenuProduct>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuProduct&&(identical(other.publicId, publicId) || other.publicId == publicId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.dietaryClass, dietaryClass) || other.dietaryClass == dietaryClass)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isOutOfStock, isOutOfStock) || other.isOutOfStock == isOutOfStock)&&const DeepCollectionEquality().equals(other._imageUrls, _imageUrls)&&const DeepCollectionEquality().equals(other._variants, _variants)&&const DeepCollectionEquality().equals(other._addonGroups, _addonGroups));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicId,categoryId,name,description,price,dietaryClass,isAvailable,isActive,isOutOfStock,const DeepCollectionEquality().hash(_imageUrls),const DeepCollectionEquality().hash(_variants),const DeepCollectionEquality().hash(_addonGroups));

@override
String toString() {
  return 'MenuProduct(publicId: $publicId, categoryId: $categoryId, name: $name, description: $description, price: $price, dietaryClass: $dietaryClass, isAvailable: $isAvailable, isActive: $isActive, isOutOfStock: $isOutOfStock, imageUrls: $imageUrls, variants: $variants, addonGroups: $addonGroups)';
}


}

/// @nodoc
abstract mixin class _$MenuProductCopyWith<$Res> implements $MenuProductCopyWith<$Res> {
  factory _$MenuProductCopyWith(_MenuProduct value, $Res Function(_MenuProduct) _then) = __$MenuProductCopyWithImpl;
@override @useResult
$Res call({
 String publicId, String? categoryId, String name, String? description,@MoneyConverter() Money price, String dietaryClass, bool isAvailable, bool isActive, bool isOutOfStock, List<String> imageUrls, List<MenuVariant> variants, List<MenuAddonGroup> addonGroups
});




}
/// @nodoc
class __$MenuProductCopyWithImpl<$Res>
    implements _$MenuProductCopyWith<$Res> {
  __$MenuProductCopyWithImpl(this._self, this._then);

  final _MenuProduct _self;
  final $Res Function(_MenuProduct) _then;

/// Create a copy of MenuProduct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? publicId = null,Object? categoryId = freezed,Object? name = null,Object? description = freezed,Object? price = null,Object? dietaryClass = null,Object? isAvailable = null,Object? isActive = null,Object? isOutOfStock = null,Object? imageUrls = null,Object? variants = null,Object? addonGroups = null,}) {
  return _then(_MenuProduct(
publicId: null == publicId ? _self.publicId : publicId // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Money,dietaryClass: null == dietaryClass ? _self.dietaryClass : dietaryClass // ignore: cast_nullable_to_non_nullable
as String,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isOutOfStock: null == isOutOfStock ? _self.isOutOfStock : isOutOfStock // ignore: cast_nullable_to_non_nullable
as bool,imageUrls: null == imageUrls ? _self._imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,variants: null == variants ? _self._variants : variants // ignore: cast_nullable_to_non_nullable
as List<MenuVariant>,addonGroups: null == addonGroups ? _self._addonGroups : addonGroups // ignore: cast_nullable_to_non_nullable
as List<MenuAddonGroup>,
  ));
}


}


/// @nodoc
mixin _$MenuVariant {

 String get publicId; String get name;@MoneyConverter() Money get price; bool get isDefault;
/// Create a copy of MenuVariant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuVariantCopyWith<MenuVariant> get copyWith => _$MenuVariantCopyWithImpl<MenuVariant>(this as MenuVariant, _$identity);

  /// Serializes this MenuVariant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuVariant&&(identical(other.publicId, publicId) || other.publicId == publicId)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicId,name,price,isDefault);

@override
String toString() {
  return 'MenuVariant(publicId: $publicId, name: $name, price: $price, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class $MenuVariantCopyWith<$Res>  {
  factory $MenuVariantCopyWith(MenuVariant value, $Res Function(MenuVariant) _then) = _$MenuVariantCopyWithImpl;
@useResult
$Res call({
 String publicId, String name,@MoneyConverter() Money price, bool isDefault
});




}
/// @nodoc
class _$MenuVariantCopyWithImpl<$Res>
    implements $MenuVariantCopyWith<$Res> {
  _$MenuVariantCopyWithImpl(this._self, this._then);

  final MenuVariant _self;
  final $Res Function(MenuVariant) _then;

/// Create a copy of MenuVariant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? publicId = null,Object? name = null,Object? price = null,Object? isDefault = null,}) {
  return _then(_self.copyWith(
publicId: null == publicId ? _self.publicId : publicId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Money,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuVariant].
extension MenuVariantPatterns on MenuVariant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuVariant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuVariant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuVariant value)  $default,){
final _that = this;
switch (_that) {
case _MenuVariant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuVariant value)?  $default,){
final _that = this;
switch (_that) {
case _MenuVariant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String publicId,  String name, @MoneyConverter()  Money price,  bool isDefault)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuVariant() when $default != null:
return $default(_that.publicId,_that.name,_that.price,_that.isDefault);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String publicId,  String name, @MoneyConverter()  Money price,  bool isDefault)  $default,) {final _that = this;
switch (_that) {
case _MenuVariant():
return $default(_that.publicId,_that.name,_that.price,_that.isDefault);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String publicId,  String name, @MoneyConverter()  Money price,  bool isDefault)?  $default,) {final _that = this;
switch (_that) {
case _MenuVariant() when $default != null:
return $default(_that.publicId,_that.name,_that.price,_that.isDefault);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuVariant implements MenuVariant {
  const _MenuVariant({required this.publicId, required this.name, @MoneyConverter() required this.price, required this.isDefault});
  factory _MenuVariant.fromJson(Map<String, dynamic> json) => _$MenuVariantFromJson(json);

@override final  String publicId;
@override final  String name;
@override@MoneyConverter() final  Money price;
@override final  bool isDefault;

/// Create a copy of MenuVariant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuVariantCopyWith<_MenuVariant> get copyWith => __$MenuVariantCopyWithImpl<_MenuVariant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuVariantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuVariant&&(identical(other.publicId, publicId) || other.publicId == publicId)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicId,name,price,isDefault);

@override
String toString() {
  return 'MenuVariant(publicId: $publicId, name: $name, price: $price, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class _$MenuVariantCopyWith<$Res> implements $MenuVariantCopyWith<$Res> {
  factory _$MenuVariantCopyWith(_MenuVariant value, $Res Function(_MenuVariant) _then) = __$MenuVariantCopyWithImpl;
@override @useResult
$Res call({
 String publicId, String name,@MoneyConverter() Money price, bool isDefault
});




}
/// @nodoc
class __$MenuVariantCopyWithImpl<$Res>
    implements _$MenuVariantCopyWith<$Res> {
  __$MenuVariantCopyWithImpl(this._self, this._then);

  final _MenuVariant _self;
  final $Res Function(_MenuVariant) _then;

/// Create a copy of MenuVariant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? publicId = null,Object? name = null,Object? price = null,Object? isDefault = null,}) {
  return _then(_MenuVariant(
publicId: null == publicId ? _self.publicId : publicId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Money,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$MenuAddonGroup {

 String get publicId; String get name; int get minSelect; int? get maxSelect; List<MenuAddon> get addons;
/// Create a copy of MenuAddonGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuAddonGroupCopyWith<MenuAddonGroup> get copyWith => _$MenuAddonGroupCopyWithImpl<MenuAddonGroup>(this as MenuAddonGroup, _$identity);

  /// Serializes this MenuAddonGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuAddonGroup&&(identical(other.publicId, publicId) || other.publicId == publicId)&&(identical(other.name, name) || other.name == name)&&(identical(other.minSelect, minSelect) || other.minSelect == minSelect)&&(identical(other.maxSelect, maxSelect) || other.maxSelect == maxSelect)&&const DeepCollectionEquality().equals(other.addons, addons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicId,name,minSelect,maxSelect,const DeepCollectionEquality().hash(addons));

@override
String toString() {
  return 'MenuAddonGroup(publicId: $publicId, name: $name, minSelect: $minSelect, maxSelect: $maxSelect, addons: $addons)';
}


}

/// @nodoc
abstract mixin class $MenuAddonGroupCopyWith<$Res>  {
  factory $MenuAddonGroupCopyWith(MenuAddonGroup value, $Res Function(MenuAddonGroup) _then) = _$MenuAddonGroupCopyWithImpl;
@useResult
$Res call({
 String publicId, String name, int minSelect, int? maxSelect, List<MenuAddon> addons
});




}
/// @nodoc
class _$MenuAddonGroupCopyWithImpl<$Res>
    implements $MenuAddonGroupCopyWith<$Res> {
  _$MenuAddonGroupCopyWithImpl(this._self, this._then);

  final MenuAddonGroup _self;
  final $Res Function(MenuAddonGroup) _then;

/// Create a copy of MenuAddonGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? publicId = null,Object? name = null,Object? minSelect = null,Object? maxSelect = freezed,Object? addons = null,}) {
  return _then(_self.copyWith(
publicId: null == publicId ? _self.publicId : publicId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,minSelect: null == minSelect ? _self.minSelect : minSelect // ignore: cast_nullable_to_non_nullable
as int,maxSelect: freezed == maxSelect ? _self.maxSelect : maxSelect // ignore: cast_nullable_to_non_nullable
as int?,addons: null == addons ? _self.addons : addons // ignore: cast_nullable_to_non_nullable
as List<MenuAddon>,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuAddonGroup].
extension MenuAddonGroupPatterns on MenuAddonGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuAddonGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuAddonGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuAddonGroup value)  $default,){
final _that = this;
switch (_that) {
case _MenuAddonGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuAddonGroup value)?  $default,){
final _that = this;
switch (_that) {
case _MenuAddonGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String publicId,  String name,  int minSelect,  int? maxSelect,  List<MenuAddon> addons)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuAddonGroup() when $default != null:
return $default(_that.publicId,_that.name,_that.minSelect,_that.maxSelect,_that.addons);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String publicId,  String name,  int minSelect,  int? maxSelect,  List<MenuAddon> addons)  $default,) {final _that = this;
switch (_that) {
case _MenuAddonGroup():
return $default(_that.publicId,_that.name,_that.minSelect,_that.maxSelect,_that.addons);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String publicId,  String name,  int minSelect,  int? maxSelect,  List<MenuAddon> addons)?  $default,) {final _that = this;
switch (_that) {
case _MenuAddonGroup() when $default != null:
return $default(_that.publicId,_that.name,_that.minSelect,_that.maxSelect,_that.addons);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuAddonGroup implements MenuAddonGroup {
  const _MenuAddonGroup({required this.publicId, required this.name, required this.minSelect, this.maxSelect, required final  List<MenuAddon> addons}): _addons = addons;
  factory _MenuAddonGroup.fromJson(Map<String, dynamic> json) => _$MenuAddonGroupFromJson(json);

@override final  String publicId;
@override final  String name;
@override final  int minSelect;
@override final  int? maxSelect;
 final  List<MenuAddon> _addons;
@override List<MenuAddon> get addons {
  if (_addons is EqualUnmodifiableListView) return _addons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_addons);
}


/// Create a copy of MenuAddonGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuAddonGroupCopyWith<_MenuAddonGroup> get copyWith => __$MenuAddonGroupCopyWithImpl<_MenuAddonGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuAddonGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuAddonGroup&&(identical(other.publicId, publicId) || other.publicId == publicId)&&(identical(other.name, name) || other.name == name)&&(identical(other.minSelect, minSelect) || other.minSelect == minSelect)&&(identical(other.maxSelect, maxSelect) || other.maxSelect == maxSelect)&&const DeepCollectionEquality().equals(other._addons, _addons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicId,name,minSelect,maxSelect,const DeepCollectionEquality().hash(_addons));

@override
String toString() {
  return 'MenuAddonGroup(publicId: $publicId, name: $name, minSelect: $minSelect, maxSelect: $maxSelect, addons: $addons)';
}


}

/// @nodoc
abstract mixin class _$MenuAddonGroupCopyWith<$Res> implements $MenuAddonGroupCopyWith<$Res> {
  factory _$MenuAddonGroupCopyWith(_MenuAddonGroup value, $Res Function(_MenuAddonGroup) _then) = __$MenuAddonGroupCopyWithImpl;
@override @useResult
$Res call({
 String publicId, String name, int minSelect, int? maxSelect, List<MenuAddon> addons
});




}
/// @nodoc
class __$MenuAddonGroupCopyWithImpl<$Res>
    implements _$MenuAddonGroupCopyWith<$Res> {
  __$MenuAddonGroupCopyWithImpl(this._self, this._then);

  final _MenuAddonGroup _self;
  final $Res Function(_MenuAddonGroup) _then;

/// Create a copy of MenuAddonGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? publicId = null,Object? name = null,Object? minSelect = null,Object? maxSelect = freezed,Object? addons = null,}) {
  return _then(_MenuAddonGroup(
publicId: null == publicId ? _self.publicId : publicId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,minSelect: null == minSelect ? _self.minSelect : minSelect // ignore: cast_nullable_to_non_nullable
as int,maxSelect: freezed == maxSelect ? _self.maxSelect : maxSelect // ignore: cast_nullable_to_non_nullable
as int?,addons: null == addons ? _self._addons : addons // ignore: cast_nullable_to_non_nullable
as List<MenuAddon>,
  ));
}


}


/// @nodoc
mixin _$MenuAddon {

 String get publicId; String get name;@MoneyConverter() Money get price;
/// Create a copy of MenuAddon
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuAddonCopyWith<MenuAddon> get copyWith => _$MenuAddonCopyWithImpl<MenuAddon>(this as MenuAddon, _$identity);

  /// Serializes this MenuAddon to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuAddon&&(identical(other.publicId, publicId) || other.publicId == publicId)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicId,name,price);

@override
String toString() {
  return 'MenuAddon(publicId: $publicId, name: $name, price: $price)';
}


}

/// @nodoc
abstract mixin class $MenuAddonCopyWith<$Res>  {
  factory $MenuAddonCopyWith(MenuAddon value, $Res Function(MenuAddon) _then) = _$MenuAddonCopyWithImpl;
@useResult
$Res call({
 String publicId, String name,@MoneyConverter() Money price
});




}
/// @nodoc
class _$MenuAddonCopyWithImpl<$Res>
    implements $MenuAddonCopyWith<$Res> {
  _$MenuAddonCopyWithImpl(this._self, this._then);

  final MenuAddon _self;
  final $Res Function(MenuAddon) _then;

/// Create a copy of MenuAddon
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? publicId = null,Object? name = null,Object? price = null,}) {
  return _then(_self.copyWith(
publicId: null == publicId ? _self.publicId : publicId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Money,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuAddon].
extension MenuAddonPatterns on MenuAddon {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuAddon value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuAddon() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuAddon value)  $default,){
final _that = this;
switch (_that) {
case _MenuAddon():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuAddon value)?  $default,){
final _that = this;
switch (_that) {
case _MenuAddon() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String publicId,  String name, @MoneyConverter()  Money price)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuAddon() when $default != null:
return $default(_that.publicId,_that.name,_that.price);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String publicId,  String name, @MoneyConverter()  Money price)  $default,) {final _that = this;
switch (_that) {
case _MenuAddon():
return $default(_that.publicId,_that.name,_that.price);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String publicId,  String name, @MoneyConverter()  Money price)?  $default,) {final _that = this;
switch (_that) {
case _MenuAddon() when $default != null:
return $default(_that.publicId,_that.name,_that.price);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuAddon implements MenuAddon {
  const _MenuAddon({required this.publicId, required this.name, @MoneyConverter() required this.price});
  factory _MenuAddon.fromJson(Map<String, dynamic> json) => _$MenuAddonFromJson(json);

@override final  String publicId;
@override final  String name;
@override@MoneyConverter() final  Money price;

/// Create a copy of MenuAddon
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuAddonCopyWith<_MenuAddon> get copyWith => __$MenuAddonCopyWithImpl<_MenuAddon>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuAddonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuAddon&&(identical(other.publicId, publicId) || other.publicId == publicId)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicId,name,price);

@override
String toString() {
  return 'MenuAddon(publicId: $publicId, name: $name, price: $price)';
}


}

/// @nodoc
abstract mixin class _$MenuAddonCopyWith<$Res> implements $MenuAddonCopyWith<$Res> {
  factory _$MenuAddonCopyWith(_MenuAddon value, $Res Function(_MenuAddon) _then) = __$MenuAddonCopyWithImpl;
@override @useResult
$Res call({
 String publicId, String name,@MoneyConverter() Money price
});




}
/// @nodoc
class __$MenuAddonCopyWithImpl<$Res>
    implements _$MenuAddonCopyWith<$Res> {
  __$MenuAddonCopyWithImpl(this._self, this._then);

  final _MenuAddon _self;
  final $Res Function(_MenuAddon) _then;

/// Create a copy of MenuAddon
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? publicId = null,Object? name = null,Object? price = null,}) {
  return _then(_MenuAddon(
publicId: null == publicId ? _self.publicId : publicId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Money,
  ));
}


}

// dart format on
