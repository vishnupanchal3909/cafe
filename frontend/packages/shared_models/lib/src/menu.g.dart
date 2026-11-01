// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Menu _$MenuFromJson(Map<String, dynamic> json) => _Menu(
  language: json['language'] as String,
  currency: json['currency'] as String,
  categories: (json['categories'] as List<dynamic>)
      .map((e) => MenuCategory.fromJson(e as Map<String, dynamic>))
      .toList(),
  products: (json['products'] as List<dynamic>)
      .map((e) => MenuProduct.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$MenuToJson(_Menu instance) => <String, dynamic>{
  'language': instance.language,
  'currency': instance.currency,
  'categories': instance.categories,
  'products': instance.products,
};

_MenuCategory _$MenuCategoryFromJson(Map<String, dynamic> json) =>
    _MenuCategory(
      publicId: json['publicId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sortOrder: (json['sortOrder'] as num).toInt(),
      isActive: json['isActive'] as bool,
    );

Map<String, dynamic> _$MenuCategoryToJson(_MenuCategory instance) =>
    <String, dynamic>{
      'publicId': instance.publicId,
      'name': instance.name,
      'description': instance.description,
      'sortOrder': instance.sortOrder,
      'isActive': instance.isActive,
    };

_MenuProduct _$MenuProductFromJson(Map<String, dynamic> json) => _MenuProduct(
  publicId: json['publicId'] as String,
  categoryId: json['categoryId'] as String?,
  name: json['name'] as String,
  description: json['description'] as String?,
  price: const MoneyConverter().fromJson(json['price'] as Map<String, dynamic>),
  dietaryClass: json['dietaryClass'] as String,
  isAvailable: json['isAvailable'] as bool,
  isActive: json['isActive'] as bool? ?? true,
  isOutOfStock: json['isOutOfStock'] as bool? ?? false,
  imageUrls:
      (json['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  variants:
      (json['variants'] as List<dynamic>?)
          ?.map((e) => MenuVariant.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MenuVariant>[],
  addonGroups:
      (json['addonGroups'] as List<dynamic>?)
          ?.map((e) => MenuAddonGroup.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MenuAddonGroup>[],
);

Map<String, dynamic> _$MenuProductToJson(_MenuProduct instance) =>
    <String, dynamic>{
      'publicId': instance.publicId,
      'categoryId': instance.categoryId,
      'name': instance.name,
      'description': instance.description,
      'price': const MoneyConverter().toJson(instance.price),
      'dietaryClass': instance.dietaryClass,
      'isAvailable': instance.isAvailable,
      'isActive': instance.isActive,
      'isOutOfStock': instance.isOutOfStock,
      'imageUrls': instance.imageUrls,
      'variants': instance.variants,
      'addonGroups': instance.addonGroups,
    };

_MenuVariant _$MenuVariantFromJson(Map<String, dynamic> json) => _MenuVariant(
  publicId: json['publicId'] as String,
  name: json['name'] as String,
  price: const MoneyConverter().fromJson(json['price'] as Map<String, dynamic>),
  isDefault: json['isDefault'] as bool,
);

Map<String, dynamic> _$MenuVariantToJson(_MenuVariant instance) =>
    <String, dynamic>{
      'publicId': instance.publicId,
      'name': instance.name,
      'price': const MoneyConverter().toJson(instance.price),
      'isDefault': instance.isDefault,
    };

_MenuAddonGroup _$MenuAddonGroupFromJson(Map<String, dynamic> json) =>
    _MenuAddonGroup(
      publicId: json['publicId'] as String,
      name: json['name'] as String,
      minSelect: (json['minSelect'] as num).toInt(),
      maxSelect: (json['maxSelect'] as num?)?.toInt(),
      addons: (json['addons'] as List<dynamic>)
          .map((e) => MenuAddon.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MenuAddonGroupToJson(_MenuAddonGroup instance) =>
    <String, dynamic>{
      'publicId': instance.publicId,
      'name': instance.name,
      'minSelect': instance.minSelect,
      'maxSelect': instance.maxSelect,
      'addons': instance.addons,
    };

_MenuAddon _$MenuAddonFromJson(Map<String, dynamic> json) => _MenuAddon(
  publicId: json['publicId'] as String,
  name: json['name'] as String,
  price: const MoneyConverter().fromJson(json['price'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MenuAddonToJson(_MenuAddon instance) =>
    <String, dynamic>{
      'publicId': instance.publicId,
      'name': instance.name,
      'price': const MoneyConverter().toJson(instance.price),
    };
