import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product.dart';
import 'product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void updateQuery(String q) => state = q;
}
final searchProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class CategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void updateCategory(String? c) => state = c;
}
final categoryFilterProvider = NotifierProvider<CategoryFilterNotifier, String?>(CategoryFilterNotifier.new);

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final query = ref.watch(searchProvider);
  final category = ref.watch(categoryFilterProvider);
  return repo.searchProducts(query: query, category: category);
});

// A provider that keeps all products without filtering for the catalog
final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.searchProducts(query: '');
});
