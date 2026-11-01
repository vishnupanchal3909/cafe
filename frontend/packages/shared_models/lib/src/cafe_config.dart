import 'package:freezed_annotation/freezed_annotation.dart';

part 'cafe_config.freezed.dart';
part 'cafe_config.g.dart';

@freezed
abstract class CafeConfig with _$CafeConfig {
  const factory CafeConfig({
    required CafeInfo cafe,
    required CafeTheme theme,
    required List<CafeLanguage> languages,
    required String defaultLanguage,
    required CafeCurrency currency,
    required OrderingConfig ordering,
    @Default(<CafeBanner>[]) List<CafeBanner> banners,
  }) = _CafeConfig;
  factory CafeConfig.fromJson(Map<String, dynamic> json) => _$CafeConfigFromJson(json);
}

@freezed
abstract class CafeInfo with _$CafeInfo {
  const factory CafeInfo({
    required String publicId,
    required String slug,
    required String name,
    String? description,
    String? logoUrl,
    String? coverUrl,
    required String timezone,
    required String countryCode,
  }) = _CafeInfo;
  factory CafeInfo.fromJson(Map<String, dynamic> json) => _$CafeInfoFromJson(json);
}

@freezed
abstract class CafeTheme with _$CafeTheme {
  const factory CafeTheme({
    required String primaryColor,
    required String secondaryColor,
    required String backgroundColor,
    required String textColor,
    required String fontKey,
    required String buttonStyle,
    required String menuLayout,
    required String themeMode,
    required int version,
  }) = _CafeTheme;
  factory CafeTheme.fromJson(Map<String, dynamic> json) => _$CafeThemeFromJson(json);
}

@freezed
abstract class CafeLanguage with _$CafeLanguage {
  const factory CafeLanguage({required String code, required String nativeName, required String direction}) = _CafeLanguage;
  factory CafeLanguage.fromJson(Map<String, dynamic> json) => _$CafeLanguageFromJson(json);
}

@freezed
abstract class CafeCurrency with _$CafeCurrency {
  const factory CafeCurrency({required String code, required String symbol, required int minorUnit}) = _CafeCurrency;
  factory CafeCurrency.fromJson(Map<String, dynamic> json) => _$CafeCurrencyFromJson(json);
}

@freezed
abstract class OrderingConfig with _$OrderingConfig {
  const factory OrderingConfig({required String paymentPolicy, required bool guestOrderingEnabled}) = _OrderingConfig;
  factory OrderingConfig.fromJson(Map<String, dynamic> json) => _$OrderingConfigFromJson(json);
}

@freezed
abstract class CafeBanner with _$CafeBanner {
  const factory CafeBanner({required String publicId, required String placement, required String imageUrl, required String title, String? subtitle}) = _CafeBanner;
  factory CafeBanner.fromJson(Map<String, dynamic> json) => _$CafeBannerFromJson(json);
}
