import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/cart.dart';

class CartCubit extends Cubit<Cart> {
  CartCubit() : super(const Cart.empty());
  void add(CartLine line) => emit(state.add(line));
  void setQuantity(String key, int q) => emit(state.setQuantity(key, q));
  void clear() => emit(const Cart.empty());
}
