import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// Exact money. Built from the API's string amounts, never from a double.
class Money extends Equatable {
  const Money(this.amount, this.currency);

  factory Money.fromJson(Map<String, dynamic> json) => Money(Decimal.parse(json['amount'] as String), json['currency'] as String);

  factory Money.zero(String currency) => Money(Decimal.zero, currency);

  final Decimal amount;
  final String currency;

  Money operator +(Money other) {
    _check(other);
    return Money(amount + other.amount, currency);
  }

  Money operator -(Money other) {
    _check(other);
    return Money(amount - other.amount, currency);
  }

  Money times(int quantity) => Money(amount * Decimal.fromInt(quantity), currency);

  bool get isZero => amount == Decimal.zero;

  void _check(Money other) {
    if (other.currency != currency) throw ArgumentError('Cannot combine $currency with ${other.currency}');
  }

  Map<String, dynamic> toJson() => {'amount': amount.toString(), 'currency': currency};

  @override
  List<Object?> get props => [amount, currency];
}
