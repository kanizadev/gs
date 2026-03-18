import '../core/api_client.dart';
import '../core/app_config.dart';
import '../core/api_exception.dart';
import 'product.dart';

class ProductRepository {
  ProductRepository({ApiClient? api})
      : _api = api ?? ApiClient(baseUrl: AppConfig.apiBaseUrl);

  final ApiClient _api;
  final Map<String, _CacheEntry<List<Product>>> _searchCache = {};
  static const Duration _searchCacheTtl = Duration(minutes: 3);

  String _normalizeQuery(String q) => q.trim().toLowerCase();

  String _cacheKey({
    required String query,
    String? category,
  }) {
    final nq = _normalizeQuery(query);
    final nc = (category ?? '').trim().toLowerCase();
    return 'q=$nq|c=$nc';
  }

  /// Backend endpoint contract (suggested):
  /// GET /products?query=<q>&category=<category>
  /// -> { "items": [ { id, name, unit, price, imagePath } ] }
  Future<List<Product>> searchProducts({
    required String query,
    String? category,
    bool forceRefresh = false,
  }) async {
    final key = _cacheKey(query: query, category: category);
    final now = DateTime.now();
    final cached = _searchCache[key];
    if (!forceRefresh && cached != null && cached.isFresh(now, _searchCacheTtl)) {
      return cached.value;
    }

    try {
      final q = <String, dynamic>{'query': query};
      if (category != null && category.trim().isNotEmpty) {
        q['category'] = category.trim();
      }
      final json = await _api.getJson('/products', query: q);

      final items = json['items'];
      if (items is List) {
        final parsed = items
            .whereType<Map>()
            .map((e) => Product.fromJson(e.cast<String, dynamic>()))
            .toList();
        _searchCache[key] = _CacheEntry(parsed, now);
        return parsed;
      }

      throw ApiException('Invalid products payload');
    } catch (_) {
      if (!AppConfig.allowDemoFallback) rethrow;
      final parsed = _demoProducts
          .where(
            (p) {
              final matchesQuery = query.trim().isEmpty
                  ? true
                  : p.name.toLowerCase().contains(query.trim().toLowerCase());
              if (!matchesQuery) return false;
              if (category == null || category.trim().isEmpty) return true;
              return (p.category ?? '').toLowerCase() ==
                  category.trim().toLowerCase();
            },
          )
          .toList();
      _searchCache[key] = _CacheEntry(parsed, now);
      return parsed;
    }
  }

  static const List<Product> _demoProducts = <Product>[
    Product(
      id: 'egg_chicken_red',
      name: 'Egg Chicken Red',
      unit: '4pcs, Price',
      price: 1.99,
      imagePath: 'images/egg.png',
      category: 'Grocery',
    ),
    Product(
      id: 'egg_chicken_white',
      name: 'Egg Chicken White',
      unit: '180g, Price',
      price: 1.50,
      imagePath: 'images/egg.png',
      category: 'Grocery',
    ),
    Product(
      id: 'egg_pasta',
      name: 'Egg Pasta',
      unit: '30gm, Price',
      price: 15.99,
      imagePath: 'images/egg.png',
      category: 'Grocery',
    ),
    Product(
      id: 'egg_noodles',
      name: 'Egg Noodles',
      unit: '2L, Price',
      price: 15.99,
      imagePath: 'images/egg.png',
      category: 'Grocery',
    ),
    Product(
      id: 'mayo_eggless',
      name: 'Mayonnois Eggless',
      unit: '325ml, Price',
      price: 4.99,
      imagePath: 'images/egg.png',
      category: 'Grocery',
    ),
    Product(
      id: 'egg_noodles_2',
      name: 'Egg Noodles',
      unit: '330ml, Price',
      price: 4.99,
      imagePath: 'images/egg.png',
      category: 'Grocery',
    ),
  ];
}

class _CacheEntry<T> {
  _CacheEntry(this.value, this.createdAt);

  final T value;
  final DateTime createdAt;

  bool isFresh(DateTime now, Duration ttl) => now.difference(createdAt) <= ttl;
}

