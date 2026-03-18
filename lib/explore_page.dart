import 'package:flutter/material.dart';

import 'dart:async';

import 'cart_page.dart';
import 'favourite_page.dart';
import 'store_home_page.dart';
import 'product_detail_page.dart';
import 'account_page.dart';
import 'data/product.dart';
import 'data/product_repository.dart';

enum _ExploreSortBy { name, price }

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> with TickerProviderStateMixin {
  int _currentIndex = 1; // Explore is index 1
  late List<AnimationController> _navAnimationControllers;
  late List<Animation<double>> _navScaleAnimations;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;

  final List<String> _tabs = const ['All', 'Spicy', 'Dressings', 'Sweet', 'Roots'];
  int _selectedTabIndex = 0;

  RangeValues? _priceRangeFilter;
  _ExploreSortBy _sortBy = _ExploreSortBy.name;
  bool _sortAscending = true;

  final Map<String, int> _productQuantities = <String, int>{};

  final ProductRepository _repo = ProductRepository();
  List<Product> _products = const <Product>[];
  bool _loading = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initializeNavAnimations();
    _fetchProducts(query: '');
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
    _searchController.dispose();
    for (final c in _navAnimationControllers) {
      c.dispose();
    }
    super.dispose();
  }

  double get _minPrice {
    if (_products.isEmpty) return 0;
    return _products
        .map((e) => e.price)
        .reduce((a, b) => a < b ? a : b);
  }

  double get _maxPrice {
    if (_products.isEmpty) return 0;
    return _products
        .map((e) => e.price)
        .reduce((a, b) => a > b ? a : b);
  }

  List<Product> get _filteredProducts {
    final priceRange = _priceRangeFilter;

    final filtered = _products.where((p) {
      if (priceRange != null) {
        if (p.price < priceRange.start || p.price > priceRange.end) return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case _ExploreSortBy.name:
          cmp = a.name.compareTo(b.name);
          break;
        case _ExploreSortBy.price:
          cmp = a.price.compareTo(b.price);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return filtered;
  }

  Future<void> _fetchProducts({required String query}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repo.searchProducts(query: query);
      if (!mounted) return;
      setState(() {
        _products = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _products = const <Product>[];
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _onExploreQueryChanged(String v) {
    setState(() => _searchQuery = v);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _fetchProducts(query: _searchQuery);
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _openFilterSheet() {
    final minPrice = _minPrice;
    final maxPrice = _maxPrice;
    final clampedInitialRange = _priceRangeFilter ?? RangeValues(minPrice, maxPrice);

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
        _ExploreSortBy tempSortBy = _sortBy;
        bool tempAscending = _sortAscending;

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
                            tempSortBy = _ExploreSortBy.name;
                            tempAscending = true;
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
                        selected: tempSortBy == _ExploreSortBy.name,
                        onSelected: (_) => setModalState(() {
                          tempSortBy = _ExploreSortBy.name;
                        }),
                        selectedColor: const Color(0xFF6CC51D).withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: tempSortBy == _ExploreSortBy.name
                              ? const Color(0xFF6CC51D)
                              : Colors.black,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Price'),
                        selected: tempSortBy == _ExploreSortBy.price,
                        onSelected: (_) => setModalState(() {
                          tempSortBy = _ExploreSortBy.price;
                        }),
                        selectedColor: const Color(0xFF6CC51D).withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: tempSortBy == _ExploreSortBy.price
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
                        setState(() {
                          final isFullRange =
                              tempRange.start <= minPrice && tempRange.end >= maxPrice;
                          _priceRangeFilter = isFullRange ? null : tempRange;
                          _sortBy = tempSortBy;
                          _sortAscending = tempAscending;
                        });
                        Navigator.pop(context);
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

  void _add(String id) {
    setState(() {
      _productQuantities[id] = (_productQuantities[id] ?? 0) + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
    final hasActiveFilters =
        _priceRangeFilter != null || _sortBy != _ExploreSortBy.name || !_sortAscending;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _openFilterSheet,
                    icon: Icon(
                      Icons.tune,
                      color: hasActiveFilters ? const Color(0xFF6CC51D) : Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleSearch,
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Row(
                children: const [
                  Text(
                    'Vegetables',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _searchController,
            onChanged: _onExploreQueryChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search vegetables...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF868889),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Poppins',
                      ),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF868889)),
                      suffixIcon: _searchQuery.trim().isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.close, color: Color(0xFF868889)),
                              tooltip: 'Clear',
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                ),
              ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final selected = _selectedTabIndex == i;
                  return ChoiceChip(
                    label: Text(_tabs[i]),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedTabIndex = i),
                    selectedColor: const Color(0xFF6CC51D).withValues(alpha: 0.15),
                    backgroundColor: const Color(0xFFF4F5F9),
                    side: BorderSide(
                      color: selected ? const Color(0xFF6CC51D) : Colors.transparent,
                    ),
                    labelStyle: TextStyle(
                      color: selected ? const Color(0xFF6CC51D) : Colors.black,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF868889),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        )
                      : (products.isEmpty
                          ? const Center(
                              child: Text(
                                'No results',
                                style: TextStyle(
                                  color: Color(0xFF868889),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            )
                          : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, i) {
                        final p = products[i];
                        final id = p.id;
                        final qty = _productQuantities[id] ?? 0;
                        final price = p.price;
                        final name = p.name;
                        final unit = p.unit;
                        final image = p.imagePath;

                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailPage(
                                    id: id,
                                    name: name,
                                    unit: unit,
                                    price: price,
                                    imagePath: image,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: Image.asset(
                                        image,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.image,
                                          color: Color(0xFFBDBDBD),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '\$${price.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    unit,
                                    style: const TextStyle(
                                      color: Color(0xFF868889),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: InkWell(
                                      onTap: () => _add(id),
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: const Color(0xFFE0E0E0),
                                          ),
                                        ),
                                        child: const Icon(Icons.add, size: 18),
                                      ),
                                    ),
                                  ),
                                  if (qty > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        'In cart: $qty',
                                        style: const TextStyle(
                                          color: Color(0xFF868889),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ))),
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

