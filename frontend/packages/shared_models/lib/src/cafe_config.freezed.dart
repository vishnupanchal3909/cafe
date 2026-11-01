// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cafe_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CafeConfig {

 CafeInfo get cafe; CafeTheme get theme; List<CafeLanguage> get languages; String get defaultLanguage; CafeCurrency get currency; OrderingConfig get ordering; List<CafeBanner> get banners;
/// Create a copy of CafeConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CafeConfigCopyWith<CafeConfig> get copyWith => _$CafeConfigCopyWithImpl<CafeConfig>(this as CafeConfig, _$identity);

  /// Serializes this CafeConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CafeConfig&&(identical(other.cafe, cafe) || other.cafe == cafe)&&(identical(other.theme, theme) || other.theme == theme)&&const DeepCollectionEquality().equals(other.languages, languages)&&(identical(other.defaultLanguage, defaultLanguage) || other.defaultLanguage == defaultLanguage)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.ordering, ordering) || other.ordering == ordering)&&const DeepCollectionEquality().equals(other.banners, banners));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cafe,theme,const DeepCollectionEquality().hash(languages),defaultLanguage,currency,ordering,const DeepCollectionEquality().hash(banners));

@override
String toString() {
  return 'CafeConfig(cafe: $cafe, theme: $theme, languages: $languages, defaultLanguage: $defaultLanguage, currency: $currency, ordering: $ordering, banners: $banners)';
}


}

/// @nodoc
abstract mixin class $CafeConfigCopyWith<$Res>  {
  factory $CafeConfigCopyWith(CafeConfig value, $Res Function(CafeConfig) _then) = _$CafeConfigCopyWithImpl;
@useResult
$Res call({
 CafeInfo cafe, CafeTheme theme, List<CafeLanguage> languages, String defaultLanguage, CafeCurrency currency, OrderingConfig ordering, List<CafeBanner> banners
});


$CafeInfoCopyWith<$Res> get cafe;$CafeThemeCopyWith<$Res> get theme;$CafeCurrencyCopyWith<$Res> get currency;$OrderingConfigCopyWith<$Res> get ordering;

}
/// @nodoc
class _$CafeConfigCopyWithImpl<$Res>
    implements $CafeConfigCopyWith<$Res> {
  _$CafeConfigCopyWithImpl(this._self, this._then);

  final CafeConfig _self;
  final $Res Function(CafeConfig) _then;

/// Create a copy of CafeConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cafe = null,Object? theme = null,Object? languages = null,Object? defaultLanguage = null,Object? currency = null,Object? ordering = null,Object? banners = null,}) {
  return _then(_self.copyWith(
cafe: null == cafe ? _self.cafe : cafe // ignore: cast_nullable_to_non_nullable
as CafeInfo,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as CafeTheme,languages: null == languages ? _self.languages : languages // ignore: cast_nullable_to_non_nullable
as List<CafeLanguage>,defaultLanguage: null == defaultLanguage ? _self.defaultLanguage : defaultLanguage // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as CafeCurrency,ordering: null == ordering ? _self.ordering : ordering // ignore: cast_nullable_to_non_nullable
as OrderingConfig,banners: null == banners ? _self.banners : banners // ignore: cast_nullable_to_non_nullable
as List<CafeBanner>,
  ));
}
/// Create a copy of CafeConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CafeInfoCopyWith<$Res> get cafe {
  
  return $CafeInfoCopyWith<$Res>(_self.cafe, (value) {
    return _then(_self.copyWith(cafe: value));
  });
}/// Create a copy of CafeConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CafeThemeCopyWith<$Res> get theme {
  
  return $CafeThemeCopyWith<$Res>(_self.theme, (value) {
    return _then(_self.copyWith(theme: value));
  });
}/// Create a copy of CafeConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CafeCurrencyCopyWith<$Res> get currency {
  
  return $CafeCurrencyCopyWith<$Res>(_self.currency, (value) {
    return _then(_self.copyWith(currency: value));
  });
}/// Create a copy of CafeConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderingConfigCopyWith<$Res> get ordering {
  
  return $OrderingConfigCopyWith<$Res>(_self.ordering, (value) {
    return _then(_self.copyWith(ordering: value));
  });
}
}


/// Adds pattern-matching-related methods to [CafeConfig].
extension CafeConfigPatterns on CafeConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CafeConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CafeConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CafeConfig value)  $default,){
final _that = this;
switch (_that) {
case _CafeConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CafeConfig value)?  $default,){
final _that = this;
switch (_that) {
case _CafeConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CafeInfo cafe,  CafeTheme theme,  List<CafeLanguage> languages,  String defaultLanguage,  CafeCurrency currency,  OrderingConfig ordering,  List<CafeBanner> banners)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CafeConfig() when $default != null:
return $default(_that.cafe,_that.theme,_that.languages,_that.defaultLanguage,_that.currency,_that.ordering,_that.banners);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CafeInfo cafe,  CafeTheme theme,  List<CafeLanguage> languages,  String defaultLanguage,  CafeCurrency currency,  OrderingConfig ordering,  List<CafeBanner> banners)  $default,) {final _that = this;
switch (_that) {
case _CafeConfig():
return $default(_that.cafe,_that.theme,_that.languages,_that.defaultLanguage,_that.currency,_that.ordering,_that.banners);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CafeInfo cafe,  CafeTheme theme,  List<CafeLanguage> languages,  String defaultLanguage,  CafeCurrency currency,  OrderingConfig ordering,  List<CafeBanner> banners)?  $default,) {final _that = this;
switch (_that) {
case _CafeConfig() when $default != null:
return $default(_that.cafe,_that.theme,_that.languages,_that.defaultLanguage,_that.currency,_that.ordering,_that.banners);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CafeConfig implements CafeConfig {
  const _CafeConfig({required this.cafe, required this.theme, required final  List<CafeLanguage> languages, required this.defaultLanguage, required this.currency, required this.ordering, final  List<CafeBanner> banners = const <CafeBanner>[]}): _languages = languages,_banners = banners;
  factory _CafeConfig.fromJson(Map<String, dynamic> json) => _$CafeConfigFromJson(json);

@override final  CafeInfo cafe;
@override final  CafeTheme theme;
 final  List<CafeLanguage> _languages;
@override List<CafeLanguage> get languages {
  if (_languages is EqualUnmodifiableListView) return _languages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_languages);
}

@override final  String defaultLanguage;
@override final  CafeCurrency currency;
@override final  OrderingConfig ordering;
 final  List<CafeBanner> _banners;
@override@JsonKey() List<CafeBanner> get banners {
  if (_banners is EqualUnmodifiableListView) return _banners;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_banners);
}


/// Create a copy of CafeConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CafeConfigCopyWith<_CafeConfig> get copyWith => __$CafeConfigCopyWithImpl<_CafeConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CafeConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CafeConfig&&(identical(other.cafe, cafe) || other.cafe == cafe)&&(identical(other.theme, theme) || other.theme == theme)&&const DeepCollectionEquality().equals(other._languages, _languages)&&(identical(other.defaultLanguage, defaultLanguage) || other.defaultLanguage == defaultLanguage)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.ordering, ordering) || other.ordering == ordering)&&const DeepCollectionEquality().equals(other._banners, _banners));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cafe,theme,const DeepCollectionEquality().hash(_languages),defaultLanguage,currency,ordering,const DeepCollectionEquality().hash(_banners));

@override
String toString() {
  return 'CafeConfig(cafe: $cafe, theme: $theme, languages: $languages, defaultLanguage: $defaultLanguage, currency: $currency, ordering: $ordering, banners: $banners)';
}


}

/// @nodoc
abstract mixin class _$CafeConfigCopyWith<$Res> implements $CafeConfigCopyWith<$Res> {
  factory _$CafeConfigCopyWith(_CafeConfig value, $Res Function(_CafeConfig) _then) = __$CafeConfigCopyWithImpl;
@override @useResult
$Res call({
 CafeInfo cafe, CafeTheme theme, List<CafeLanguage> languages, String defaultLanguage, CafeCurrency currency, OrderingConfig ordering, List<CafeBanner> banners
});


@override $CafeInfoCopyWith<$Res> get cafe;@override $CafeThemeCopyWith<$Res> get theme;@override $CafeCurrencyCopyWith<$Res> get currency;@override $OrderingConfigCopyWith<$Res> get ordering;

}
/// @nodoc
class __$CafeConfigCopyWithImpl<$Res>
    implements _$CafeConfigCopyWith<$Res> {
  __$CafeConfigCopyWithImpl(this._self, this._then);

  final _CafeConfig _self;
  final $Res Function(_CafeConfig) _then;

/// Create a copy of CafeConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cafe = null,Object? theme = null,Object? languages = null,Object? defaultLanguage = null,Object? currency = null,Object? ordering = null,Object? banners = null,}) {
  return _then(_CafeConfig(
cafe: null == cafe ? _self.cafe : cafe // ignore: cast_nullable_to_non_nullable
as CafeInfo,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as CafeTheme,languages: null == languages ? _self._languages : languages // ignore: cast_nullable_to_non_nullable
as List<CafeLanguage>,defaultLanguage: null == defaultLanguage ? _self.defaultLanguage : defaultLanguage // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as CafeCurrency,ordering: null == ordering ? _self.ordering : ordering // ignore: cast_nullable_to_non_nullable
as OrderingConfig,banners: null == banners ? _self._banners : banners // ignore: cast_nullable_to_non_nullable
as List<CafeBanner>,
  ));
}

/// Create a copy of CafeConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CafeInfoCopyWith<$Res> get cafe {
  
  return $CafeInfoCopyWith<$Res>(_self.cafe, (value) {
    return _then(_self.copyWith(cafe: value));
  });
}/// Create a copy of CafeConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CafeThemeCopyWith<$Res> get theme {
  
  return $CafeThemeCopyWith<$Res>(_self.theme, (value) {
    return _then(_self.copyWith(theme: value));
  });
}/// Create a copy of CafeConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CafeCurrencyCopyWith<$Res> get currency {
  
  return $CafeCurrencyCopyWith<$Res>(_self.currency, (value) {
    return _then(_self.copyWith(currency: value));
  });
}/// Create a copy of CafeConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderingConfigCopyWith<$Res> get ordering {
  
  return $OrderingConfigCopyWith<$Res>(_self.ordering, (value) {
    return _then(_self.copyWith(ordering: value));
  });
}
}


/// @nodoc
mixin _$CafeInfo {

 String get publicId; String get slug; String get name; String? get description; String? get logoUrl; String? get coverUrl; String get timezone; String get countryCode;
/// Create a copy of CafeInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CafeInfoCopyWith<CafeInfo> get copyWith => _$CafeInfoCopyWithImpl<CafeInfo>(this as CafeInfo, _$identity);

  /// Serializes this CafeInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CafeInfo&&(identical(other.publicId, publicId) || other.publicId == publicId)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicId,slug,name,description,logoUrl,coverUrl,timezone,countryCode);

@override
String toString() {
  return 'CafeInfo(publicId: $publicId, slug: $slug, name: $name, description: $description, logoUrl: $logoUrl, coverUrl: $coverUrl, timezone: $timezone, countryCode: $countryCode)';
}


}

/// @nodoc
abstract mixin class $CafeInfoCopyWith<$Res>  {
  factory $CafeInfoCopyWith(CafeInfo value, $Res Function(CafeInfo) _then) = _$CafeInfoCopyWithImpl;
@useResult
$Res call({
 String publicId, String slug, String name, String? description, String? logoUrl, String? coverUrl, String timezone, String countryCode
});




}
/// @nodoc
class _$CafeInfoCopyWithImpl<$Res>
    implements $CafeInfoCopyWith<$Res> {
  _$CafeInfoCopyWithImpl(this._self, this._then);

  final CafeInfo _self;
  final $Res Function(CafeInfo) _then;

/// Create a copy of CafeInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? publicId = null,Object? slug = null,Object? name = null,Object? description = freezed,Object? logoUrl = freezed,Object? coverUrl = freezed,Object? timezone = null,Object? countryCode = null,}) {
  return _then(_self.copyWith(
publicId: null == publicId ? _self.publicId : publicId // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,countryCode: null == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CafeInfo].
extension CafeInfoPatterns on CafeInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CafeInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CafeInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CafeInfo value)  $default,){
final _that = this;
switch (_that) {
case _CafeInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CafeInfo value)?  $default,){
final _that = this;
switch (_that) {
case _CafeInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String publicId,  String slug,  String name,  String? description,  String? logoUrl,  String? coverUrl,  String timezone,  String countryCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CafeInfo() when $default != null:
return $default(_that.publicId,_that.slug,_that.name,_that.description,_that.logoUrl,_that.coverUrl,_that.timezone,_that.countryCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String publicId,  String slug,  String name,  String? description,  String? logoUrl,  String? coverUrl,  String timezone,  String countryCode)  $default,) {final _that = this;
switch (_that) {
case _CafeInfo():
return $default(_that.publicId,_that.slug,_that.name,_that.description,_that.logoUrl,_that.coverUrl,_that.timezone,_that.countryCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String publicId,  String slug,  String name,  String? description,  String? logoUrl,  String? coverUrl,  String timezone,  String countryCode)?  $default,) {final _that = this;
switch (_that) {
case _CafeInfo() when $default != null:
return $default(_that.publicId,_that.slug,_that.name,_that.description,_that.logoUrl,_that.coverUrl,_that.timezone,_that.countryCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CafeInfo implements CafeInfo {
  const _CafeInfo({required this.publicId, required this.slug, required this.name, this.description, this.logoUrl, this.coverUrl, required this.timezone, required this.countryCode});
  factory _CafeInfo.fromJson(Map<String, dynamic> json) => _$CafeInfoFromJson(json);

@override final  String publicId;
@override final  String slug;
@override final  String name;
@override final  String? description;
@override final  String? logoUrl;
@override final  String? coverUrl;
@override final  String timezone;
@override final  String countryCode;

/// Create a copy of CafeInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CafeInfoCopyWith<_CafeInfo> get copyWith => __$CafeInfoCopyWithImpl<_CafeInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CafeInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CafeInfo&&(identical(other.publicId, publicId) || other.publicId == publicId)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicId,slug,name,description,logoUrl,coverUrl,timezone,countryCode);

@override
String toString() {
  return 'CafeInfo(publicId: $publicId, slug: $slug, name: $name, description: $description, logoUrl: $logoUrl, coverUrl: $coverUrl, timezone: $timezone, countryCode: $countryCode)';
}


}

/// @nodoc
abstract mixin class _$CafeInfoCopyWith<$Res> implements $CafeInfoCopyWith<$Res> {
  factory _$CafeInfoCopyWith(_CafeInfo value, $Res Function(_CafeInfo) _then) = __$CafeInfoCopyWithImpl;
@override @useResult
$Res call({
 String publicId, String slug, String name, String? description, String? logoUrl, String? coverUrl, String timezone, String countryCode
});




}
/// @nodoc
class __$CafeInfoCopyWithImpl<$Res>
    implements _$CafeInfoCopyWith<$Res> {
  __$CafeInfoCopyWithImpl(this._self, this._then);

  final _CafeInfo _self;
  final $Res Function(_CafeInfo) _then;

/// Create a copy of CafeInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? publicId = null,Object? slug = null,Object? name = null,Object? description = freezed,Object? logoUrl = freezed,Object? coverUrl = freezed,Object? timezone = null,Object? countryCode = null,}) {
  return _then(_CafeInfo(
publicId: null == publicId ? _self.publicId : publicId // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,countryCode: null == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CafeTheme {

 String get primaryColor; String get secondaryColor; String get backgroundColor; String get textColor; String get fontKey; String get buttonStyle; String get menuLayout; String get themeMode; int get version;
/// Create a copy of CafeTheme
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CafeThemeCopyWith<CafeTheme> get copyWith => _$CafeThemeCopyWithImpl<CafeTheme>(this as CafeTheme, _$identity);

  /// Serializes this CafeTheme to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CafeTheme&&(identical(other.primaryColor, primaryColor) || other.primaryColor == primaryColor)&&(identical(other.secondaryColor, secondaryColor) || other.secondaryColor == secondaryColor)&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&(identical(other.textColor, textColor) || other.textColor == textColor)&&(identical(other.fontKey, fontKey) || other.fontKey == fontKey)&&(identical(other.buttonStyle, buttonStyle) || other.buttonStyle == buttonStyle)&&(identical(other.menuLayout, menuLayout) || other.menuLayout == menuLayout)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,primaryColor,secondaryColor,backgroundColor,textColor,fontKey,buttonStyle,menuLayout,themeMode,version);

@override
String toString() {
  return 'CafeTheme(primaryColor: $primaryColor, secondaryColor: $secondaryColor, backgroundColor: $backgroundColor, textColor: $textColor, fontKey: $fontKey, buttonStyle: $buttonStyle, menuLayout: $menuLayout, themeMode: $themeMode, version: $version)';
}


}

/// @nodoc
abstract mixin class $CafeThemeCopyWith<$Res>  {
  factory $CafeThemeCopyWith(CafeTheme value, $Res Function(CafeTheme) _then) = _$CafeThemeCopyWithImpl;
@useResult
$Res call({
 String primaryColor, String secondaryColor, String backgroundColor, String textColor, String fontKey, String buttonStyle, String menuLayout, String themeMode, int version
});




}
/// @nodoc
class _$CafeThemeCopyWithImpl<$Res>
    implements $CafeThemeCopyWith<$Res> {
  _$CafeThemeCopyWithImpl(this._self, this._then);

  final CafeTheme _self;
  final $Res Function(CafeTheme) _then;

/// Create a copy of CafeTheme
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? primaryColor = null,Object? secondaryColor = null,Object? backgroundColor = null,Object? textColor = null,Object? fontKey = null,Object? buttonStyle = null,Object? menuLayout = null,Object? themeMode = null,Object? version = null,}) {
  return _then(_self.copyWith(
primaryColor: null == primaryColor ? _self.primaryColor : primaryColor // ignore: cast_nullable_to_non_nullable
as String,secondaryColor: null == secondaryColor ? _self.secondaryColor : secondaryColor // ignore: cast_nullable_to_non_nullable
as String,backgroundColor: null == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as String,textColor: null == textColor ? _self.textColor : textColor // ignore: cast_nullable_to_non_nullable
as String,fontKey: null == fontKey ? _self.fontKey : fontKey // ignore: cast_nullable_to_non_nullable
as String,buttonStyle: null == buttonStyle ? _self.buttonStyle : buttonStyle // ignore: cast_nullable_to_non_nullable
as String,menuLayout: null == menuLayout ? _self.menuLayout : menuLayout // ignore: cast_nullable_to_non_nullable
as String,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CafeTheme].
extension CafeThemePatterns on CafeTheme {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CafeTheme value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CafeTheme() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CafeTheme value)  $default,){
final _that = this;
switch (_that) {
case _CafeTheme():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CafeTheme value)?  $default,){
final _that = this;
switch (_that) {
case _CafeTheme() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String primaryColor,  String secondaryColor,  String backgroundColor,  String textColor,  String fontKey,  String buttonStyle,  String menuLayout,  String themeMode,  int version)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CafeTheme() when $default != null:
return $default(_that.primaryColor,_that.secondaryColor,_that.backgroundColor,_that.textColor,_that.fontKey,_that.buttonStyle,_that.menuLayout,_that.themeMode,_that.version);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String primaryColor,  String secondaryColor,  String backgroundColor,  String textColor,  String fontKey,  String buttonStyle,  String menuLayout,  String themeMode,  int version)  $default,) {final _that = this;
switch (_that) {
case _CafeTheme():
return $default(_that.primaryColor,_that.secondaryColor,_that.backgroundColor,_that.textColor,_that.fontKey,_that.buttonStyle,_that.menuLayout,_that.themeMode,_that.version);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String primaryColor,  String secondaryColor,  String backgroundColor,  String textColor,  String fontKey,  String buttonStyle,  String menuLayout,  String themeMode,  int version)?  $default,) {final _that = this;
switch (_that) {
case _CafeTheme() when $default != null:
return $default(_that.primaryColor,_that.secondaryColor,_that.backgroundColor,_that.textColor,_that.fontKey,_that.buttonStyle,_that.menuLayout,_that.themeMode,_that.version);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CafeTheme implements CafeTheme {
  const _CafeTheme({required this.primaryColor, required this.secondaryColor, required this.backgroundColor, required this.textColor, required this.fontKey, required this.buttonStyle, required this.menuLayout, required this.themeMode, required this.version});
  factory _CafeTheme.fromJson(Map<String, dynamic> json) => _$CafeThemeFromJson(json);

@override final  String primaryColor;
@override final  String secondaryColor;
@override final  String backgroundColor;
@override final  String textColor;
@override final  String fontKey;
@override final  String buttonStyle;
@override final  String menuLayout;
@override final  String themeMode;
@override final  int version;

/// Create a copy of CafeTheme
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CafeThemeCopyWith<_CafeTheme> get copyWith => __$CafeThemeCopyWithImpl<_CafeTheme>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CafeThemeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CafeTheme&&(identical(other.primaryColor, primaryColor) || other.primaryColor == primaryColor)&&(identical(other.secondaryColor, secondaryColor) || other.secondaryColor == secondaryColor)&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&(identical(other.textColor, textColor) || other.textColor == textColor)&&(identical(other.fontKey, fontKey) || other.fontKey == fontKey)&&(identical(other.buttonStyle, buttonStyle) || other.buttonStyle == buttonStyle)&&(identical(other.menuLayout, menuLayout) || other.menuLayout == menuLayout)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,primaryColor,secondaryColor,backgroundColor,textColor,fontKey,buttonStyle,menuLayout,themeMode,version);

@override
String toString() {
  return 'CafeTheme(primaryColor: $primaryColor, secondaryColor: $secondaryColor, backgroundColor: $backgroundColor, textColor: $textColor, fontKey: $fontKey, buttonStyle: $buttonStyle, menuLayout: $menuLayout, themeMode: $themeMode, version: $version)';
}


}

/// @nodoc
abstract mixin class _$CafeThemeCopyWith<$Res> implements $CafeThemeCopyWith<$Res> {
  factory _$CafeThemeCopyWith(_CafeTheme value, $Res Function(_CafeTheme) _then) = __$CafeThemeCopyWithImpl;
@override @useResult
$Res call({
 String primaryColor, String secondaryColor, String backgroundColor, String textColor, String fontKey, String buttonStyle, String menuLayout, String themeMode, int version
});




}
/// @nodoc
class __$CafeThemeCopyWithImpl<$Res>
    implements _$CafeThemeCopyWith<$Res> {
  __$CafeThemeCopyWithImpl(this._self, this._then);

  final _CafeTheme _self;
  final $Res Function(_CafeTheme) _then;

/// Create a copy of CafeTheme
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? primaryColor = null,Object? secondaryColor = null,Object? backgroundColor = null,Object? textColor = null,Object? fontKey = null,Object? buttonStyle = null,Object? menuLayout = null,Object? themeMode = null,Object? version = null,}) {
  return _then(_CafeTheme(
primaryColor: null == primaryColor ? _self.primaryColor : primaryColor // ignore: cast_nullable_to_non_nullable
as String,secondaryColor: null == secondaryColor ? _self.secondaryColor : secondaryColor // ignore: cast_nullable_to_non_nullable
as String,backgroundColor: null == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as String,textColor: null == textColor ? _self.textColor : textColor // ignore: cast_nullable_to_non_nullable
as String,fontKey: null == fontKey ? _self.fontKey : fontKey // ignore: cast_nullable_to_non_nullable
as String,buttonStyle: null == buttonStyle ? _self.buttonStyle : buttonStyle // ignore: cast_nullable_to_non_nullable
as String,menuLayout: null == menuLayout ? _self.menuLayout : menuLayout // ignore: cast_nullable_to_non_nullable
as String,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CafeLanguage {

 String get code; String get nativeName; String get direction;
/// Create a copy of CafeLanguage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CafeLanguageCopyWith<CafeLanguage> get copyWith => _$CafeLanguageCopyWithImpl<CafeLanguage>(this as CafeLanguage, _$identity);

  /// Serializes this CafeLanguage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CafeLanguage&&(identical(other.code, code) || other.code == code)&&(identical(other.nativeName, nativeName) || other.nativeName == nativeName)&&(identical(other.direction, direction) || other.direction == direction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,nativeName,direction);

@override
String toString() {
  return 'CafeLanguage(code: $code, nativeName: $nativeName, direction: $direction)';
}


}

/// @nodoc
abstract mixin class $CafeLanguageCopyWith<$Res>  {
  factory $CafeLanguageCopyWith(CafeLanguage value, $Res Function(CafeLanguage) _then) = _$CafeLanguageCopyWithImpl;
@useResult
$Res call({
 String code, String nativeName, String direction
});




}
/// @nodoc
class _$CafeLanguageCopyWithImpl<$Res>
    implements $CafeLanguageCopyWith<$Res> {
  _$CafeLanguageCopyWithImpl(this._self, this._then);

  final CafeLanguage _self;
  final $Res Function(CafeLanguage) _then;

/// Create a copy of CafeLanguage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? nativeName = null,Object? direction = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,nativeName: null == nativeName ? _self.nativeName : nativeName // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CafeLanguage].
extension CafeLanguagePatterns on CafeLanguage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CafeLanguage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CafeLanguage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CafeLanguage value)  $default,){
final _that = this;
switch (_that) {
case _CafeLanguage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CafeLanguage value)?  $default,){
final _that = this;
switch (_that) {
case _CafeLanguage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String nativeName,  String direction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CafeLanguage() when $default != null:
return $default(_that.code,_that.nativeName,_that.direction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String nativeName,  String direction)  $default,) {final _that = this;
switch (_that) {
case _CafeLanguage():
return $default(_that.code,_that.nativeName,_that.direction);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String nativeName,  String direction)?  $default,) {final _that = this;
switch (_that) {
case _CafeLanguage() when $default != null:
return $default(_that.code,_that.nativeName,_that.direction);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CafeLanguage implements CafeLanguage {
  const _CafeLanguage({required this.code, required this.nativeName, required this.direction});
  factory _CafeLanguage.fromJson(Map<String, dynamic> json) => _$CafeLanguageFromJson(json);

@override final  String code;
@override final  String nativeName;
@override final  String direction;

/// Create a copy of CafeLanguage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CafeLanguageCopyWith<_CafeLanguage> get copyWith => __$CafeLanguageCopyWithImpl<_CafeLanguage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CafeLanguageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CafeLanguage&&(identical(other.code, code) || other.code == code)&&(identical(other.nativeName, nativeName) || other.nativeName == nativeName)&&(identical(other.direction, direction) || other.direction == direction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,nativeName,direction);

@override
String toString() {
  return 'CafeLanguage(code: $code, nativeName: $nativeName, direction: $direction)';
}


}

/// @nodoc
abstract mixin class _$CafeLanguageCopyWith<$Res> implements $CafeLanguageCopyWith<$Res> {
  factory _$CafeLanguageCopyWith(_CafeLanguage value, $Res Function(_CafeLanguage) _then) = __$CafeLanguageCopyWithImpl;
@override @useResult
$Res call({
 String code, String nativeName, String direction
});




}
/// @nodoc
class __$CafeLanguageCopyWithImpl<$Res>
    implements _$CafeLanguageCopyWith<$Res> {
  __$CafeLanguageCopyWithImpl(this._self, this._then);

  final _CafeLanguage _self;
  final $Res Function(_CafeLanguage) _then;

/// Create a copy of CafeLanguage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? nativeName = null,Object? direction = null,}) {
  return _then(_CafeLanguage(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,nativeName: null == nativeName ? _self.nativeName : nativeName // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CafeCurrency {

 String get code; String get symbol; int get minorUnit;
/// Create a copy of CafeCurrency
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CafeCurrencyCopyWith<CafeCurrency> get copyWith => _$CafeCurrencyCopyWithImpl<CafeCurrency>(this as CafeCurrency, _$identity);

  /// Serializes this CafeCurrency to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CafeCurrency&&(identical(other.code, code) || other.code == code)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.minorUnit, minorUnit) || other.minorUnit == minorUnit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,symbol,minorUnit);

@override
String toString() {
  return 'CafeCurrency(code: $code, symbol: $symbol, minorUnit: $minorUnit)';
}


}

/// @nodoc
abstract mixin class $CafeCurrencyCopyWith<$Res>  {
  factory $CafeCurrencyCopyWith(CafeCurrency value, $Res Function(CafeCurrency) _then) = _$CafeCurrencyCopyWithImpl;
@useResult
$Res call({
 String code, String symbol, int minorUnit
});




}
/// @nodoc
class _$CafeCurrencyCopyWithImpl<$Res>
    implements $CafeCurrencyCopyWith<$Res> {
  _$CafeCurrencyCopyWithImpl(this._self, this._then);

  final CafeCurrency _self;
  final $Res Function(CafeCurrency) _then;

/// Create a copy of CafeCurrency
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? symbol = null,Object? minorUnit = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,minorUnit: null == minorUnit ? _self.minorUnit : minorUnit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CafeCurrency].
extension CafeCurrencyPatterns on CafeCurrency {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CafeCurrency value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CafeCurrency() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CafeCurrency value)  $default,){
final _that = this;
switch (_that) {
case _CafeCurrency():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CafeCurrency value)?  $default,){
final _that = this;
switch (_that) {
case _CafeCurrency() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String symbol,  int minorUnit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CafeCurrency() when $default != null:
return $default(_that.code,_that.symbol,_that.minorUnit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String symbol,  int minorUnit)  $default,) {final _that = this;
switch (_that) {
case _CafeCurrency():
return $default(_that.code,_that.symbol,_that.minorUnit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String symbol,  int minorUnit)?  $default,) {final _that = this;
switch (_that) {
case _CafeCurrency() when $default != null:
return $default(_that.code,_that.symbol,_that.minorUnit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CafeCurrency implements CafeCurrency {
  const _CafeCurrency({required this.code, required this.symbol, required this.minorUnit});
  factory _CafeCurrency.fromJson(Map<String, dynamic> json) => _$CafeCurrencyFromJson(json);

@override final  String code;
@override final  String symbol;
@override final  int minorUnit;

/// Create a copy of CafeCurrency
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CafeCurrencyCopyWith<_CafeCurrency> get copyWith => __$CafeCurrencyCopyWithImpl<_CafeCurrency>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CafeCurrencyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CafeCurrency&&(identical(other.code, code) || other.code == code)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.minorUnit, minorUnit) || other.minorUnit == minorUnit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,symbol,minorUnit);

@override
String toString() {
  return 'CafeCurrency(code: $code, symbol: $symbol, minorUnit: $minorUnit)';
}


}

/// @nodoc
abstract mixin class _$CafeCurrencyCopyWith<$Res> implements $CafeCurrencyCopyWith<$Res> {
  factory _$CafeCurrencyCopyWith(_CafeCurrency value, $Res Function(_CafeCurrency) _then) = __$CafeCurrencyCopyWithImpl;
@override @useResult
$Res call({
 String code, String symbol, int minorUnit
});




}
/// @nodoc
class __$CafeCurrencyCopyWithImpl<$Res>
    implements _$CafeCurrencyCopyWith<$Res> {
  __$CafeCurrencyCopyWithImpl(this._self, this._then);

  final _CafeCurrency _self;
  final $Res Function(_CafeCurrency) _then;

/// Create a copy of CafeCurrency
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? symbol = null,Object? minorUnit = null,}) {
  return _then(_CafeCurrency(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,minorUnit: null == minorUnit ? _self.minorUnit : minorUnit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$OrderingConfig {

 String get paymentPolicy; bool get guestOrderingEnabled;
/// Create a copy of OrderingConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderingConfigCopyWith<OrderingConfig> get copyWith => _$OrderingConfigCopyWithImpl<OrderingConfig>(this as OrderingConfig, _$identity);

  /// Serializes this OrderingConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderingConfig&&(identical(other.paymentPolicy, paymentPolicy) || other.paymentPolicy == paymentPolicy)&&(identical(other.guestOrderingEnabled, guestOrderingEnabled) || other.guestOrderingEnabled == guestOrderingEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,paymentPolicy,guestOrderingEnabled);

@override
String toString() {
  return 'OrderingConfig(paymentPolicy: $paymentPolicy, guestOrderingEnabled: $guestOrderingEnabled)';
}


}

/// @nodoc
abstract mixin class $OrderingConfigCopyWith<$Res>  {
  factory $OrderingConfigCopyWith(OrderingConfig value, $Res Function(OrderingConfig) _then) = _$OrderingConfigCopyWithImpl;
@useResult
$Res call({
 String paymentPolicy, bool guestOrderingEnabled
});




}
/// @nodoc
class _$OrderingConfigCopyWithImpl<$Res>
    implements $OrderingConfigCopyWith<$Res> {
  _$OrderingConfigCopyWithImpl(this._self, this._then);

  final OrderingConfig _self;
  final $Res Function(OrderingConfig) _then;

/// Create a copy of OrderingConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? paymentPolicy = null,Object? guestOrderingEnabled = null,}) {
  return _then(_self.copyWith(
paymentPolicy: null == paymentPolicy ? _self.paymentPolicy : paymentPolicy // ignore: cast_nullable_to_non_nullable
as String,guestOrderingEnabled: null == guestOrderingEnabled ? _self.guestOrderingEnabled : guestOrderingEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderingConfig].
extension OrderingConfigPatterns on OrderingConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderingConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderingConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderingConfig value)  $default,){
final _that = this;
switch (_that) {
case _OrderingConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderingConfig value)?  $default,){
final _that = this;
switch (_that) {
case _OrderingConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String paymentPolicy,  bool guestOrderingEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderingConfig() when $default != null:
return $default(_that.paymentPolicy,_that.guestOrderingEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String paymentPolicy,  bool guestOrderingEnabled)  $default,) {final _that = this;
switch (_that) {
case _OrderingConfig():
return $default(_that.paymentPolicy,_that.guestOrderingEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String paymentPolicy,  bool guestOrderingEnabled)?  $default,) {final _that = this;
switch (_that) {
case _OrderingConfig() when $default != null:
return $default(_that.paymentPolicy,_that.guestOrderingEnabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderingConfig implements OrderingConfig {
  const _OrderingConfig({required this.paymentPolicy, required this.guestOrderingEnabled});
  factory _OrderingConfig.fromJson(Map<String, dynamic> json) => _$OrderingConfigFromJson(json);

@override final  String paymentPolicy;
@override final  bool guestOrderingEnabled;

/// Create a copy of OrderingConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderingConfigCopyWith<_OrderingConfig> get copyWith => __$OrderingConfigCopyWithImpl<_OrderingConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderingConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderingConfig&&(identical(other.paymentPolicy, paymentPolicy) || other.paymentPolicy == paymentPolicy)&&(identical(other.guestOrderingEnabled, guestOrderingEnabled) || other.guestOrderingEnabled == guestOrderingEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,paymentPolicy,guestOrderingEnabled);

@override
String toString() {
  return 'OrderingConfig(paymentPolicy: $paymentPolicy, guestOrderingEnabled: $guestOrderingEnabled)';
}


}

/// @nodoc
abstract mixin class _$OrderingConfigCopyWith<$Res> implements $OrderingConfigCopyWith<$Res> {
  factory _$OrderingConfigCopyWith(_OrderingConfig value, $Res Function(_OrderingConfig) _then) = __$OrderingConfigCopyWithImpl;
@override @useResult
$Res call({
 String paymentPolicy, bool guestOrderingEnabled
});




}
/// @nodoc
class __$OrderingConfigCopyWithImpl<$Res>
    implements _$OrderingConfigCopyWith<$Res> {
  __$OrderingConfigCopyWithImpl(this._self, this._then);

  final _OrderingConfig _self;
  final $Res Function(_OrderingConfig) _then;

/// Create a copy of OrderingConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? paymentPolicy = null,Object? guestOrderingEnabled = null,}) {
  return _then(_OrderingConfig(
paymentPolicy: null == paymentPolicy ? _self.paymentPolicy : paymentPolicy // ignore: cast_nullable_to_non_nullable
as String,guestOrderingEnabled: null == guestOrderingEnabled ? _self.guestOrderingEnabled : guestOrderingEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$CafeBanner {

 String get publicId; String get placement; String get imageUrl; String get title; String? get subtitle;
/// Create a copy of CafeBanner
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CafeBannerCopyWith<CafeBanner> get copyWith => _$CafeBannerCopyWithImpl<CafeBanner>(this as CafeBanner, _$identity);

  /// Serializes this CafeBanner to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CafeBanner&&(identical(other.publicId, publicId) || other.publicId == publicId)&&(identical(other.placement, placement) || other.placement == placement)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicId,placement,imageUrl,title,subtitle);

@override
String toString() {
  return 'CafeBanner(publicId: $publicId, placement: $placement, imageUrl: $imageUrl, title: $title, subtitle: $subtitle)';
}


}

/// @nodoc
abstract mixin class $CafeBannerCopyWith<$Res>  {
  factory $CafeBannerCopyWith(CafeBanner value, $Res Function(CafeBanner) _then) = _$CafeBannerCopyWithImpl;
@useResult
$Res call({
 String publicId, String placement, String imageUrl, String title, String? subtitle
});




}
/// @nodoc
class _$CafeBannerCopyWithImpl<$Res>
    implements $CafeBannerCopyWith<$Res> {
  _$CafeBannerCopyWithImpl(this._self, this._then);

  final CafeBanner _self;
  final $Res Function(CafeBanner) _then;

/// Create a copy of CafeBanner
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? publicId = null,Object? placement = null,Object? imageUrl = null,Object? title = null,Object? subtitle = freezed,}) {
  return _then(_self.copyWith(
publicId: null == publicId ? _self.publicId : publicId // ignore: cast_nullable_to_non_nullable
as String,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CafeBanner].
extension CafeBannerPatterns on CafeBanner {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CafeBanner value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CafeBanner() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CafeBanner value)  $default,){
final _that = this;
switch (_that) {
case _CafeBanner():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CafeBanner value)?  $default,){
final _that = this;
switch (_that) {
case _CafeBanner() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String publicId,  String placement,  String imageUrl,  String title,  String? subtitle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CafeBanner() when $default != null:
return $default(_that.publicId,_that.placement,_that.imageUrl,_that.title,_that.subtitle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String publicId,  String placement,  String imageUrl,  String title,  String? subtitle)  $default,) {final _that = this;
switch (_that) {
case _CafeBanner():
return $default(_that.publicId,_that.placement,_that.imageUrl,_that.title,_that.subtitle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String publicId,  String placement,  String imageUrl,  String title,  String? subtitle)?  $default,) {final _that = this;
switch (_that) {
case _CafeBanner() when $default != null:
return $default(_that.publicId,_that.placement,_that.imageUrl,_that.title,_that.subtitle);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CafeBanner implements CafeBanner {
  const _CafeBanner({required this.publicId, required this.placement, required this.imageUrl, required this.title, this.subtitle});
  factory _CafeBanner.fromJson(Map<String, dynamic> json) => _$CafeBannerFromJson(json);

@override final  String publicId;
@override final  String placement;
@override final  String imageUrl;
@override final  String title;
@override final  String? subtitle;

/// Create a copy of CafeBanner
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CafeBannerCopyWith<_CafeBanner> get copyWith => __$CafeBannerCopyWithImpl<_CafeBanner>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CafeBannerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CafeBanner&&(identical(other.publicId, publicId) || other.publicId == publicId)&&(identical(other.placement, placement) || other.placement == placement)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicId,placement,imageUrl,title,subtitle);

@override
String toString() {
  return 'CafeBanner(publicId: $publicId, placement: $placement, imageUrl: $imageUrl, title: $title, subtitle: $subtitle)';
}


}

/// @nodoc
abstract mixin class _$CafeBannerCopyWith<$Res> implements $CafeBannerCopyWith<$Res> {
  factory _$CafeBannerCopyWith(_CafeBanner value, $Res Function(_CafeBanner) _then) = __$CafeBannerCopyWithImpl;
@override @useResult
$Res call({
 String publicId, String placement, String imageUrl, String title, String? subtitle
});




}
/// @nodoc
class __$CafeBannerCopyWithImpl<$Res>
    implements _$CafeBannerCopyWith<$Res> {
  __$CafeBannerCopyWithImpl(this._self, this._then);

  final _CafeBanner _self;
  final $Res Function(_CafeBanner) _then;

/// Create a copy of CafeBanner
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? publicId = null,Object? placement = null,Object? imageUrl = null,Object? title = null,Object? subtitle = freezed,}) {
  return _then(_CafeBanner(
publicId: null == publicId ? _self.publicId : publicId // ignore: cast_nullable_to_non_nullable
as String,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
