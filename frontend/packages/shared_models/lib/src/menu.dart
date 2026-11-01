import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_core/shared_core.dart';
import 'money_converter.dart';

part 'menu.freezed.dart';
part 'menu.g.dart';

@freezed
abstract class Menu with _$Menu {
  const factory Menu({required String language, required String currency, required List<MenuCategory> categories, required List<MenuProduct> products}) = _Menu;
  factory Menu.fromJson(Map<String, dynamic> json) => _$MenuFromJson(json);
}

@freezed
abstract class MenuCategory with _$MenuCategory {
  const factory MenuCategory({required String publicId, required String name, String? description, required int sortOrder, required bool isActive}) = _MenuCategory;
  factory MenuCategory.fromJson(Map<String, dynamic> json) => _$MenuCategoryFromJson(json);
}

@freezed
abstract class MenuProduct with _$MenuProduct {
  const factory MenuProduct({
    required String publicId,
    String? categoryId,
    required String name,
    String? description,
    @MoneyConverter() required Money price,
    required String dietaryClass,
    required bool isAvailable,
    @Default(true) bool isActive,
    @Default(false) bool isOutOfStock,
    @Default(<String>[]) List<String> imageUrls,
    @Default(<MenuVariant>[]) List<MenuVariant> variants,
    @Default(<MenuAddonGroup>[]) List<MenuAddonGroup> addonGroups,
  }) = _MenuProduct;
  factory MenuProduct.fromJson(Map<String, dynamic> json) => _$MenuProductFromJson(json);
}

@freezed
abstract class MenuVariant with _$MenuVariant {
  const factory MenuVariant({required String publicId, required String name, @MoneyConverter() required Money price, required bool isDefault}) = _MenuVariant;
  factory MenuVariant.fromJson(Map<String, dynamic> json) => _$MenuVariantFromJson(json);
}

@freezed
abstract class MenuAddonGroup with _$MenuAddonGroup {
  const factory MenuAddonGroup({required String publicId, required String name, required int minSelect, int? maxSelect, required List<MenuAddon> addons}) = _MenuAddonGroup;
  factory MenuAddonGroup.fromJson(Map<String, dynamic> json) => _$MenuAddonGroupFromJson(json);
}

@freezed
abstract class MenuAddon with _$MenuAddon {
  const factory MenuAddon({required String publicId, required String name, @MoneyConverter() required Money price}) = _MenuAddon;
  factory MenuAddon.fromJson(Map<String, dynamic> json) => _$MenuAddonFromJson(json);
}
