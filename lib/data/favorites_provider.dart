import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);

class FavoritesNotifier extends Notifier<Set<String>> {
  late Box<bool> _box;

  @override
  Set<String> build() {
    _box = Hive.box<bool>('favorites');
    return _box.keys.cast<String>().where((k) => _box.get(k) == true).toSet();
  }

  void toggle(String productId) {
    final isFav = state.contains(productId);
    if (isFav) {
      state = {...state}..remove(productId);
      _box.put(productId, false);
    } else {
      state = {...state, productId};
      _box.put(productId, true);
    }
  }
}
