import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final cartProvider = NotifierProvider<CartNotifier, Map<String, int>>(CartNotifier.new);

class CartNotifier extends Notifier<Map<String, int>> {
  late Box<int> _box;

  @override
  Map<String, int> build() {
    _box = Hive.box<int>('cart');
    return Map<String, int>.from(_box.toMap());
  }

  void add(String productId) {
    state = {...state, productId: 1};
    _box.put(productId, 1);
  }

  void addWithQty(String productId, int qty) {
    final currentQty = state[productId] ?? 0;
    final newQty = currentQty + qty;
    state = {...state, productId: newQty};
    _box.put(productId, newQty);
  }

  void increase(String productId) {
    if (state.containsKey(productId)) {
      final newQty = state[productId]! + 1;
      state = {...state, productId: newQty};
      _box.put(productId, newQty);
    }
  }

  void decrease(String productId) {
    if (state.containsKey(productId)) {
      final newQty = state[productId]! - 1;
      if (newQty > 0) {
        state = {...state, productId: newQty};
        _box.put(productId, newQty);
      } else {
        remove(productId);
      }
    }
  }

  void remove(String productId) {
    final newState = Map<String, int>.from(state);
    newState.remove(productId);
    state = newState;
    _box.delete(productId);
  }
}
