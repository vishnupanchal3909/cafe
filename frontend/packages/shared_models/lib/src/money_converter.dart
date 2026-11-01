import 'package:json_annotation/json_annotation.dart';
import 'package:shared_core/shared_core.dart';

class MoneyConverter implements JsonConverter<Money, Map<String, dynamic>> {
  const MoneyConverter();
  @override
  Money fromJson(Map<String, dynamic> json) => Money.fromJson(json);
  @override
  Map<String, dynamic> toJson(Money object) => object.toJson();
}
