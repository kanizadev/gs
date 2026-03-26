import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cart_page.dart';
import 'explore_page.dart';
import 'favourite_page.dart';
import 'product_detail_page.dart';
import 'store_home_page.dart';
import 'account_page.dart';
import 'data/favorites_provider.dart';
import 'data/product.dart';
import 'data/product_repository.dart';

enum _SearchSortBy { name, price }

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with TickerProviderStateMixin {
  int _currentIndex = 1; // Closest tab to Search is Explore
  late List<AnimationController> _navAnimationControllers;
  late List<Animation<double>> _navScaleAnimations;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const String _searchHistoryKey = 'search_history_recent';
  List<String> _recentSearches = const <String>[];
  bool _historyLoaded = false;

  RangeValues? _priceRangeFilter;
  String? _categoryFilter;
  _SearchSortBy _sortBy = _SearchSortBy.name;
  bool _sortAscending = true;

  final ProductRepository _repo = ProductRepository();

  // Unfiltered by price/sort (based on query + category). Used for slider bounds.
  List<Product> _baseProducts = const <Product>[];
  // Filtered by price/sort (still derived from query + category).
  List<Product> _products = const <Product>[];
  // Unfiltered by price/sort AND category (same query). Used only to show category options.
  List<Product> _catalogProducts = const <Product>[];
  bool _loading = false;
  String? _error;
  Timer? _debounce;
  int _requestSeq = 0;

  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 10;
  int _itemsLimit = 10;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _searchController.text = widget.initialQuery;
    _initializeNavAnimations();
    _scrollController.addListener(_maybeLoadMore);
    _loadSearchHistory();
    _fetchProducts(
      query: _query,
      fetchBase: true,
      fetchDisplay: true,
      fetchCatalog: true,
    );
  }

  void _initializeNavAnimations() {
    _navAnimationControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );
    _navScaleAnimations = _navAnimationControllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();
    _navAnimationControllers[_currentIndex].forward();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController
      ..removeListener(_maybeLoadMore)
      ..dispose();
    _searchController.dispose();
    for (final c in _navAnimationControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_searchHistoryKey);
    if (!mounted) return;
    setState(() {
      _recentSearches = saved ?? const <String>[];
      _historyLoaded = true;
    });
  }

  Future<void> _saveSearchToHistory(String q) async {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final lower = trimmed.toLowerCase();

    final next = <String>[
      trimmed,
      ..._recentSearches.where((e) => e.toLowerCase() != lower),
    ].take(10).toList();

    await prefs.setStringList(_searchHistoryKey, next);
    if (!mounted) return;
    setState(() => _recentSearches = next);
  }

  void _commitSearch(String q) {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return;

    _debounce?.cancel();
    setState(() => _query = trimmed);

    _saveSearchToHistory(trimmed);
    _fetchProducts(
      query: trimmed,
      fetchBase: true,
      fetchDisplay: true,
      fetchCatalog: true,
    );
  }

  void _selectSuggestion(String q) {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return;
    _searchController.value = TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
    _commitSearch(trimmed);
  }

  void _maybeLoadMore() {
    if (_loading) return;
    if (_itemsLimit >= _filtered.length) return;
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= maxScroll - 350) {
      setState(() {
        _itemsLimit = (_itemsLimit + _pageSize).clamp(0, _filtered.length);
      });
    }
  }

  double get _minPrice {
    if (_baseProducts.isEmpty) return 0;
    return _baseProducts
        .map((e) => e.price)
        .reduce((a, b) => a < b ? a : b);
  }

  double get _maxPrice {
    if (_baseProducts.isEmpty) return 0;
    return _baseProducts
        .map((e) => e.price)
        .reduce((a, b) => a > b ? a : b);
  }

  List<Product> get _filtered {
    final priceRange = _priceRangeFilter;
    final categoryFilter = _categoryFilter?.trim().toLowerCase();

    final filtered = _products.where((p) {
      if (categoryFilter != null && categoryFilter.isNotEmpty) {
        final pc = (p.category ?? '').trim().toLowerCase();
        if (pc != categoryFilter) return false;
      }
      if (priceRange != null) {
        if (p.price < priceRange.start || p.price > priceRange.end) return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case _SearchSortBy.name:
          cmp = a.name.compareTo(b.name);
          break;
        case _SearchSortBy.price:
          cmp = a.price.compareTo(b.price);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return filtered;
  }

  Future<void> _fetchProducts({
    required String query,
    bool forceRefresh = false,
    bool fetchBase = false,
    bool fetchDisplay = true,
    bool fetchCatalog = false,
  }) async {
    final int requestId = ++_requestSeq;

    if (fetchBase || fetchDisplay) {
      setState(() {
        if (fetchDisplay) _loading = true;
        _error = null;
      });
    }

    try {
      // Fetch "All categories" list for building category chips.
      if (fetchCatalog) {
        final catalogItems = await _repo.searchProducts(
          query: query,
          category: null,
          forceRefresh: forceRefresh,
        );
        if (!mounted) return;
        if (requestId != _requestSeq) return; // ignore stale responses
        setState(() {
          _catalogProducts = catalogItems;
        });
      }

      // Fetch unfiltered list for slider bounds.
      if (fetchBase) {
        final baseItems = await _repo.searchProducts(
          query: query,
          category: _categoryFilter,
          forceRefresh: forceRefresh,
        );
        if (!mounted) return;
        if (requestId != _requestSeq) return; // ignore stale responses
        setState(() {
          _baseProducts = baseItems;
        });
      }

      // Fetch filtered/sorted list for results.
      if (fetchDisplay) {
        final sortByStr =
            _sortBy == _SearchSortBy.name ? 'name' : 'price';

        final items = await _repo.searchProducts(
          query: query,
          category: _categoryFilter,
          minPrice: _priceRangeFilter?.start,
          maxPrice: _priceRangeFilter?.end,
          sortBy: sortByStr,
          sortAscending: _sortAscending,
          forceRefresh: forceRefresh,
        );
        if (!mounted) return;
        if (requestId != _requestSeq) return; // ignore stale responses
        setState(() {
          _products = items;
          _itemsLimit = _pageSize;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (requestId != _requestSeq) return; // ignore stale responses
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _onQueryChanged(String v) {
    setState(() => _query = v);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _fetchProducts(
        query: _query,
        fetchBase: true,
        fetchDisplay: true,
        fetchCatalog: true,
      );
    });
  }

  void _clearQuery() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _query = '');
    _fetchProducts(
      query: '',
      fetchBase: true,
      fetchDisplay: true,
      fetchCatalog: true,
      forceRefresh: false,
    );
  }

  void _openFilterSheet() {
    final minPrice = _minPrice;
    final maxPrice = _maxPrice;
    final clampedInitialRange = _priceRangeFilter ?? RangeValues(minPrice, maxPrice);
    final availableCategories = _catalogProducts
        .map((p) => p.category)
        .whereType<String>()
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        RangeValues tempRange = RangeValues(
          clampedInitialRange.start.clamp(minPrice, maxPrice),
          clampedInitialRange.end.clamp(minPrice, maxPrice),
        );
        _SearchSortBy tempSortBy = _sortBy;
        bool tempAscending = _sortAscending;
        String? tempCategory = _categoryFilter;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Filters',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempRange = RangeValues(minPrice, maxPrice);
                            tempSortBy = _SearchSortBy.name;
                            tempAscending = true;
                            tempCategory = null;
                          });
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: Color(0xFF6CC51D),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (availableCategories.isNotEmpty) ...[
                    const Text(
                      'Category',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: tempCategory == null || tempCategory!.trim().isEmpty,
                          onSelected: (_) => setModalState(() {
                            tempCategory = null;
                          }),
                          selectedColor: const Color(0xFF6CC51D)
                              .withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: tempCategory == null ||
                                    tempCategory!.trim().isEmpty
                                ? const Color(0xFF6CC51D)
                                : Colors.black,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ...availableCategories.map(
                          (c) => ChoiceChip(
                            label: Text(c),
                            selected: tempCategory == c,
                            onSelected: (_) => setModalState(() {
                              tempCategory = c;
                            }),
                            selectedColor: const Color(0xFF6CC51D)
                                .withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: tempCategory == c
                                  ? const Color(0xFF6CC51D)
                                  : Colors.black,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Price range: \$${tempRange.start.toStringAsFixed(2)} - \$${tempRange.end.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  RangeSlider(
                    values: tempRange,
                    min: minPrice,
                    max: maxPrice,
                    divisions: (maxPrice - minPrice) <= 0 ? null : 50,
                    activeColor: const Color(0xFF6CC51D),
                    inactiveColor: const Color(0xFFE0E0E0),
                    labels: RangeLabels(
                      tempRange.start.toStringAsFixed(2),
                      tempRange.end.toStringAsFixed(2),
                    ),
                    onChanged: (values) => setModalState(() {
                      tempRange = values;
                    }),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sort by',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ChoiceChip(
                        label: const Text('Name'),
                        selected: tempSortBy == _SearchSortBy.name,
                        onSelected: (_) => setModalState(() {
                          tempSortBy = _SearchSortBy.name;
                        }),
                        selectedColor:
                            const Color(0xFF6CC51D).withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: tempSortBy == _SearchSortBy.name
                              ? const Color(0xFF6CC51D)
                              : Colors.black,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Price'),
                        selected: tempSortBy == _SearchSortBy.price,
                        onSelected: (_) => setModalState(() {
                          tempSortBy = _SearchSortBy.price;
                        }),
                        selectedColor:
                            const Color(0xFF6CC51D).withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: tempSortBy == _SearchSortBy.price
                              ? const Color(0xFF6CC51D)
                              : Colors.black,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: tempAscending,
                    activeColor: const Color(0xFF6CC51D),
                    title: Text(
                      tempAscending ? 'Ascending' : 'Descending',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    onChanged: (v) => setModalState(() {
                      tempAscending = v;
                    }),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final categoryChanged = (_categoryFilter?.trim().toLowerCase() ?? '') !=
                            (tempCategory?.trim().toLowerCase() ?? '');
                        setState(() {
                          final isFullRange =
                              tempRange.start <= minPrice && tempRange.end >= maxPrice;
                          _priceRangeFilter = isFullRange ? null : tempRange;
                          _categoryFilter = tempCategory;
                          _sortBy = tempSortBy;
                          _sortAscending = tempAscending;
                        });
                        Navigator.pop(context);
                        _fetchProducts(
                          query: _query,
                          fetchBase: categoryChanged,
                          fetchDisplay: true,
                          fetchCatalog: false,
                        );
                      },
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchHistorySuggestions() {
    if (!_historyLoaded || _recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    final trimmedQuery = _query.trim();
    final lower = trimmedQuery.toLowerCase();

    final suggestions = trimmedQuery.isEmpty
        ? _recentSearches.take(8).toList()
        : _recentSearches
            .where((q) => q.toLowerCase().contains(lower))
            .take(6)
            .toList();

    if (suggestions.isEmpty) return const SizedBox.shrink();

    final label = trimmedQuery.isEmpty ? 'Recent' : 'Suggestions';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF868889),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                final q = suggestions[i];
                return ActionChip(
                  label: Text(q, style: const TextStyle(fontFamily: 'Poppins')),
                  backgroundColor: const Color(0xFFF4F5F9),
                  onPressed: () => _selectSuggestion(q),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemCount: suggestions.length,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoriteIds = ref.watch(favoritesProvider);

    final allProducts = _filtered;
    final visibleLimit = _itemsLimit.clamp(0, allProducts.length);
    final products = allProducts.take(visibleLimit).toList();

    final hasActiveFilters = _priceRangeFilter != null ||
        (_categoryFilter != null && _categoryFilter!.trim().isNotEmpty) ||
        _sortBy != _SearchSortBy.name ||
        !_sortAscending;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onQueryChanged,
                  onSubmitted: (v) => _commitSearch(v),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: const TextStyle(
                      color: Color(0xFF868889),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.black),
                    suffixIcon: SizedBox(
                      width: 96,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_query.trim().isNotEmpty)
                            IconButton(
                              onPressed: _clearQuery,
                              icon: const Icon(Icons.close, color: Colors.black),
                              tooltip: 'Clear',
                            )
                          else
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.mic_none, color: Colors.black),
                            tooltip: 'Voice',
                          ),
                          IconButton(
                            onPressed: _openFilterSheet,
                            icon: Icon(
                              Icons.tune,
                              color: hasActiveFilters
                                  ? const Color(0xFF6CC51D)
                                  : Colors.black,
                            ),
                            tooltip: 'Filters',
                          ),
                        ],
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
            ),
            _buildSearchHistorySuggestions(),
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    color: const Color(0xFF6CC51D),
                    onRefresh: () => _fetchProducts(
                      query: _query,
                      forceRefresh: true,
                      fetchBase: true,
                      fetchDisplay: true,
                      fetchCatalog: true,
                    ),
                    child: _error != null && allProducts.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            children: [
                              const SizedBox(height: 60),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF868889),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 14),
                              Center(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => _fetchProducts(
                                    query: _query,
                                    forceRefresh: true,
                                    fetchBase: true,
                                    fetchDisplay: true,
                                    fetchCatalog: true,
                                  ),
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : (allProducts.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 120),
                                  Center(
                                    child: Text(
                                      'No results',
                                      style: TextStyle(
                                        color: Color(0xFF868889),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : GridView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 0.82,
                                ),
                                itemCount: products.length,
                                itemBuilder: (context, i) {
                                  final p = products[i];
                                  final id = p.id;
                                  final name = p.name;
                                  final unit = p.unit;
                                  final price = p.price;
                                  final image = p.imagePath;

                                  final isFav = favoriteIds.contains(id);

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: const Color(0xFFEDEDED)),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProductDetailPage(
                                              id: id,
                                              name: name,
                                              unit: unit,
                                              price: price,
                                              imagePath: image,
                                            ),
                                          ),
                                        );
                                        if (mounted) setState(() {});
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Spacer(),
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(
                                                    minWidth: 30,
                                                    minHeight: 30,
                                                  ),
                                                  onPressed: () {
                                                    ref
                                                        .read(favoritesProvider
                                                            .notifier)
                                                        .toggle(id);
                                                  },
                                                  icon: Icon(
                                                    isFav
                                                        ? Icons.favorite
                                                        : Icons
                                                            .favorite_border,
                                                    color: isFav
                                                        ? const Color(
                                                            0xFF6CC51D)
                                                        : const Color(
                                                            0xFF868889),
                                                    size: 20,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Image.asset(
                                                  image,
                                                  fit: BoxFit.contain,
                                                  errorBuilder:
                                                      (_, __, ___) =>
                                                          const Icon(
                                                    Icons.image,
                                                    color: Color(0xFFBDBDBD),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              name,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              unit,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFF868889),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Text(
                                                  '\$${price.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                                const Spacer(),
                                                InkWell(
                                                  onTap: () {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'Added $name')),
                                                    );
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12),
                                                  child: Container(
                                                    width: 34,
                                                    height: 34,
                                                    decoration: BoxDecoration(
                                                      color: Colors.black,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: const Icon(
                                                      Icons.add,
                                                      size: 18,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )),
                  ),
                  if (_loading)
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: true,
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.35),
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.6),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  Widget _buildCustomBottomNavBar() {
    final navItems = [
      {'icon': Icons.storefront_outlined, 'label': 'Shop'},
      {'icon': Icons.explore_outlined, 'label': 'Explore'},
      {'icon': Icons.shopping_cart_outlined, 'label': 'Cart'},
      {'icon': Icons.favorite_border, 'label': 'Favourite'},
      {'icon': Icons.person_outline, 'label': 'Account'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              navItems.length,
              (index) => Expanded(
                child: _buildNavItem(
                  navItems[index]['icon'] as IconData,
                  navItems[index]['label'] as String,
                  index,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (index == _currentIndex) return;

        _navAnimationControllers[_currentIndex].reverse();
        setState(() {
          _currentIndex = index;
        });
        _navAnimationControllers[index].forward();

        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StoreHomePage()),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ExplorePage()),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CartPage()),
          );
        } else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const FavouritePage()),
          );
        } else if (index == 4) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AccountPage()),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _navScaleAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: isActive ? _navScaleAnimations[index].value : 1.0,
                child: Icon(
                  icon,
                  size: 24,
                  color: isActive ? const Color(0xFF6CC51D) : Colors.black,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isActive ? const Color(0xFF6CC51D) : Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

