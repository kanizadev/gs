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
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    required bool sortAscending,
  }) {
    final nq = _normalizeQuery(query);
    final nc = (category ?? '').trim().toLowerCase();
    final nMin = minPrice?.toStringAsFixed(2) ?? '';
    final nMax = maxPrice?.toStringAsFixed(2) ?? '';
    final sBy = (sortBy ?? '').trim().toLowerCase();
    return 'q=$nq|c=$nc|min=$nMin|max=$nMax|sb=$sBy|sa=$sortAscending';
  }

  List<Product> _applyClientFiltersAndSorting({
    required List<Product> products,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    required bool sortAscending,
  }) {
    final normalizedCategory = category?.trim().toLowerCase();

    final filtered = products.where((p) {
      final pCategory = (p.category ?? '').trim().toLowerCase();
      if (normalizedCategory != null && normalizedCategory.isNotEmpty) {
        if (pCategory != normalizedCategory) return false;
      }

      if (minPrice != null && p.price < minPrice) return false;
      if (maxPrice != null && p.price > maxPrice) return false;
      return true;
    }).toList();

    if (sortBy == null || sortBy.trim().isEmpty) {
      return filtered;
    }

    filtered.sort((a, b) {
      int cmp;
      switch (sortBy) {
        case 'price':
          cmp = a.price.compareTo(b.price);
          break;
        case 'name':
        default:
          cmp = a.name.compareTo(b.name);
          break;
      }
      return sortAscending ? cmp : -cmp;
    });

    return filtered;
  }

  /// Backend endpoint contract (suggested):
  /// GET /products?query=<q>&category=<category>
  /// -> { "items": [ { id, name, unit, price, imagePath } ] }
  Future<List<Product>> searchProducts({
    required String query,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    bool sortAscending = true,
    bool forceRefresh = false,
  }) async {
    final key = _cacheKey(
      query: query,
      category: category,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sortBy: sortBy,
      sortAscending: sortAscending,
    );
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
      if (minPrice != null) q['minPrice'] = minPrice;
      if (maxPrice != null) q['maxPrice'] = maxPrice;
      if (sortBy != null && sortBy.trim().isNotEmpty) {
        q['sortBy'] = sortBy.trim();
        q['sortOrder'] = sortAscending ? 'asc' : 'desc';
      }

      final json = await _api.getJson('/products', query: q);

      final items = json['items'];
      if (items is List) {
        final parsed = items
            .whereType<Map>()
            .map((e) => Product.fromJson(e.cast<String, dynamic>()))
            .toList();
        final finalProducts = _applyClientFiltersAndSorting(
          products: parsed,
          category: category,
          minPrice: minPrice,
          maxPrice: maxPrice,
          sortBy: sortBy,
          sortAscending: sortAscending,
        );
        _searchCache[key] = _CacheEntry(finalProducts, now);
        return finalProducts;
      }

      throw ApiException('Invalid products payload');
    } catch (_) {
      if (!AppConfig.allowDemoFallback) rethrow;

      final trimmedQuery = query.trim().toLowerCase();
      final demoFiltered = _demoProducts.where((p) {
        final matchesQuery = trimmedQuery.isEmpty
            ? true
            : p.name.toLowerCase().contains(trimmedQuery);

        if (!matchesQuery) return false;

        final normalizedCategory = category?.trim().toLowerCase();
        if (normalizedCategory == null || normalizedCategory.isEmpty) return true;

        return (p.category ?? '').trim().toLowerCase() == normalizedCategory;
      }).toList();

      final finalProducts = _applyClientFiltersAndSorting(
        products: demoFiltered,
        category: category,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sortBy: sortBy,
        sortAscending: sortAscending,
      );

      _searchCache[key] = _CacheEntry(finalProducts, now);
      return finalProducts;
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

