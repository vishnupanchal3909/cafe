// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cafe_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CafeConfig _$CafeConfigFromJson(Map<String, dynamic> json) => _CafeConfig(
  cafe: CafeInfo.fromJson(json['cafe'] as Map<String, dynamic>),
  theme: CafeTheme.fromJson(json['theme'] as Map<String, dynamic>),
  languages: (json['languages'] as List<dynamic>)
      .map((e) => CafeLanguage.fromJson(e as Map<String, dynamic>))
      .toList(),
  defaultLanguage: json['defaultLanguage'] as String,
  currency: CafeCurrency.fromJson(json['currency'] as Map<String, dynamic>),
  ordering: OrderingConfig.fromJson(json['ordering'] as Map<String, dynamic>),
  banners:
      (json['banners'] as List<dynamic>?)
          ?.map((e) => CafeBanner.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CafeBanner>[],
);

Map<String, dynamic> _$CafeConfigToJson(_CafeConfig instance) =>
    <String, dynamic>{
      'cafe': instance.cafe,
      'theme': instance.theme,
      'languages': instance.languages,
      'defaultLanguage': instance.defaultLanguage,
      'currency': instance.currency,
      'ordering': instance.ordering,
      'banners': instance.banners,
    };

_CafeInfo _$CafeInfoFromJson(Map<String, dynamic> json) => _CafeInfo(
  publicId: json['publicId'] as String,
  slug: json['slug'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  logoUrl: json['logoUrl'] as String?,
  coverUrl: json['coverUrl'] as String?,
  timezone: json['timezone'] as String,
  countryCode: json['countryCode'] as String,
);

Map<String, dynamic> _$CafeInfoToJson(_CafeInfo instance) => <String, dynamic>{
  'publicId': instance.publicId,
  'slug': instance.slug,
  'name': instance.name,
  'description': instance.description,
  'logoUrl': instance.logoUrl,
  'coverUrl': instance.coverUrl,
  'timezone': instance.timezone,
  'countryCode': instance.countryCode,
};

_CafeTheme _$CafeThemeFromJson(Map<String, dynamic> json) => _CafeTheme(
  primaryColor: json['primaryColor'] as String,
  secondaryColor: json['secondaryColor'] as String,
  backgroundColor: json['backgroundColor'] as String,
  textColor: json['textColor'] as String,
  fontKey: json['fontKey'] as String,
  buttonStyle: json['buttonStyle'] as String,
  menuLayout: json['menuLayout'] as String,
  themeMode: json['themeMode'] as String,
  version: (json['version'] as num).toInt(),
);

Map<String, dynamic> _$CafeThemeToJson(_CafeTheme instance) =>
    <String, dynamic>{
      'primaryColor': instance.primaryColor,
      'secondaryColor': instance.secondaryColor,
      'backgroundColor': instance.backgroundColor,
      'textColor': instance.textColor,
      'fontKey': instance.fontKey,
      'buttonStyle': instance.buttonStyle,
      'menuLayout': instance.menuLayout,
      'themeMode': instance.themeMode,
      'version': instance.version,
    };

_CafeLanguage _$CafeLanguageFromJson(Map<String, dynamic> json) =>
    _CafeLanguage(
      code: json['code'] as String,
      nativeName: json['nativeName'] as String,
      direction: json['direction'] as String,
    );

Map<String, dynamic> _$CafeLanguageToJson(_CafeLanguage instance) =>
    <String, dynamic>{
      'code': instance.code,
      'nativeName': instance.nativeName,
      'direction': instance.direction,
    };

_CafeCurrency _$CafeCurrencyFromJson(Map<String, dynamic> json) =>
    _CafeCurrency(
      code: json['code'] as String,
      symbol: json['symbol'] as String,
      minorUnit: (json['minorUnit'] as num).toInt(),
    );

Map<String, dynamic> _$CafeCurrencyToJson(_CafeCurrency instance) =>
    <String, dynamic>{
      'code': instance.code,
      'symbol': instance.symbol,
      'minorUnit': instance.minorUnit,
    };

_OrderingConfig _$OrderingConfigFromJson(Map<String, dynamic> json) =>
    _OrderingConfig(
      paymentPolicy: json['paymentPolicy'] as String,
      guestOrderingEnabled: json['guestOrderingEnabled'] as bool,
    );

Map<String, dynamic> _$OrderingConfigToJson(_OrderingConfig instance) =>
    <String, dynamic>{
      'paymentPolicy': instance.paymentPolicy,
      'guestOrderingEnabled': instance.guestOrderingEnabled,
    };

_CafeBanner _$CafeBannerFromJson(Map<String, dynamic> json) => _CafeBanner(
  publicId: json['publicId'] as String,
  placement: json['placement'] as String,
  imageUrl: json['imageUrl'] as String,
  title: json['title'] as String,
  subtitle: json['subtitle'] as String?,
);

Map<String, dynamic> _$CafeBannerToJson(_CafeBanner instance) =>
    <String, dynamic>{
      'publicId': instance.publicId,
      'placement': instance.placement,
      'imageUrl': instance.imageUrl,
      'title': instance.title,
      'subtitle': instance.subtitle,
    };
