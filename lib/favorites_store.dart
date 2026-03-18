class FavoriteProduct {
  const FavoriteProduct({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.imagePath,
  });

  final String id;
  final String name;
  final String unit;
  final double price;
  final String imagePath;
}

/// Simple in-memory favorites store shared across pages.
/// (No persistence yet; restart app clears favorites.)
class FavoritesStore {
  FavoritesStore._();

  static final FavoritesStore instance = FavoritesStore._();

  final Map<String, FavoriteProduct> _items = <String, FavoriteProduct>{};

  List<FavoriteProduct> get items => _items.values.toList();

  bool isFavorite(String id) => _items.containsKey(id);

  void add(FavoriteProduct product) {
    _items[product.id] = product;
  }

  void remove(String id) {
    _items.remove(id);
  }
}

