import 'dart:async';
import 'package:flutter/material.dart';
import 'products_page.dart';
import 'cart_page.dart';
import 'explore_page.dart';
import 'product_detail_page.dart';
import 'favourite_page.dart';
import 'search_page.dart';
import 'account_page.dart';
import 'data/product.dart';
import 'data/product_repository.dart';
import 'category_page.dart';

enum _HomeSortBy { name, price }

class StoreHomePage extends StatefulWidget {
  const StoreHomePage({super.key});

  @override
  State<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends State<StoreHomePage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _currentSliderIndex = 0;
  final PageController _sliderController = PageController();
  Timer? _autoScrollTimer;
  late List<AnimationController> _navAnimationControllers;
  late List<Animation<double>> _navScaleAnimations;

  // Product cart state
  final Map<String, int> _productQuantities = <String, int>{};

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  RangeValues? _priceRangeFilter;
  _HomeSortBy _sortBy = _HomeSortBy.name;
  bool _sortAscending = true;

  final ProductRepository _repo = ProductRepository();
  List<Product> _specialOffers = const <Product>[];
  bool _offersLoading = false;
  String? _offersError;

  @override
  void initState() {
    super.initState();
    _sliderController.addListener(() {
      setState(() {
        _currentSliderIndex = _sliderController.page?.round() ?? 0;
      });
    });
    _startAutoScroll();
    _initializeNavAnimations();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    setState(() {
      _offersLoading = true;
      _offersError = null;
    });
    try {
      final items = await _repo.searchProducts(query: '');
      if (!mounted) return;
      setState(() {
        _specialOffers = items;
        _offersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _specialOffers = const <Product>[];
        _offersLoading = false;
        _offersError = e.toString();
      });
    }
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
      return Tween<double>(
        begin: 1.0,
        end: 1.2,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    }).toList();
    // Start with first item animated
    _navAnimationControllers[0].forward();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_sliderController.hasClients) {
        int nextIndex =
            (_currentSliderIndex + 1) %
            3; // 3 is the number of slider images - loops back to 0
        _sliderController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _sliderController.dispose();
    _searchController.dispose();
    for (var controller in _navAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _minOfferPrice {
    if (_specialOffers.isEmpty) return 0;
    return _specialOffers
        .map((e) => e.price)
        .reduce((a, b) => a < b ? a : b);
  }

  double get _maxOfferPrice {
    if (_specialOffers.isEmpty) return 0;
    return _specialOffers
        .map((e) => e.price)
        .reduce((a, b) => a > b ? a : b);
  }

  List<Product> get _filteredSpecialOffers {
    final q = _searchQuery.trim().toLowerCase();
    final priceRange = _priceRangeFilter;

    final filtered = _specialOffers.where((p) {
      final name = p.name.toLowerCase();
      final matchesQuery = q.isEmpty ? true : name.contains(q);
      if (!matchesQuery) return false;

      if (priceRange != null) {
        if (p.price < priceRange.start || p.price > priceRange.end) return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case _HomeSortBy.name:
          cmp = a.name.compareTo(b.name);
          break;
        case _HomeSortBy.price:
          cmp = a.price.compareTo(b.price);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return filtered;
  }

  void _addToCart(String productId) {
    setState(() {
      _productQuantities[productId] = 1;
    });
  }

  void _decreaseQuantity(String productId) {
    setState(() {
      if (_productQuantities.containsKey(productId)) {
        int currentQty = _productQuantities[productId]!;
        if (currentQty > 1) {
          _productQuantities[productId] = currentQty - 1;
        } else {
          _productQuantities.remove(productId);
        }
      }
    });
  }

  void _increaseQuantity(String productId) {
    setState(() {
      if (_productQuantities.containsKey(productId)) {
        _productQuantities[productId] = _productQuantities[productId]! + 1;
      }
    });
  }

  void _openHomeFilterSheet() {
    if (_specialOffers.isEmpty) return;

    final minPrice = _minOfferPrice;
    final maxPrice = _maxOfferPrice;
    final clampedInitialRange =
        _priceRangeFilter ?? RangeValues(minPrice, maxPrice);

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
        _HomeSortBy tempSortBy = _sortBy;
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
                            tempSortBy = _HomeSortBy.name;
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
                    onChanged: (values) {
                      setModalState(() {
                        tempRange = values;
                      });
                    },
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
                        selected: tempSortBy == _HomeSortBy.name,
                        onSelected: (_) => setModalState(() {
                          tempSortBy = _HomeSortBy.name;
                        }),
                        selectedColor:
                            const Color(0xFF6CC51D).withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: tempSortBy == _HomeSortBy.name
                              ? const Color(0xFF6CC51D)
                              : Colors.black,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Price'),
                        selected: tempSortBy == _HomeSortBy.price,
                        onSelected: (_) => setModalState(() {
                          tempSortBy = _HomeSortBy.price;
                        }),
                        selectedColor:
                            const Color(0xFF6CC51D).withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: tempSortBy == _HomeSortBy.price
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
                          final isFullRange = tempRange.start <= minPrice &&
                              tempRange.end >= maxPrice;
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

  @override
  Widget build(BuildContext context) {
    final filteredOffers = _filteredSpecialOffers;
    final hasActiveFilters = _priceRangeFilter != null ||
        _sortBy != _HomeSortBy.name ||
        !_sortAscending;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                children: [
                  // Logo
                  Center(child: Image.asset('images/logo.png', height: 40)),
                  const SizedBox(height: 16),
                  // Welcome Back text
                  const Center(
                    child: Text(
                      'Welcome Back',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: Color(0xFF4C4F4D),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Via Francesco Rismondo, 11-13-17, 52100 Arezzo AR, Italy',
                          style: TextStyle(
                            color: Color(0xFF4C4F4D),
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Box
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F5F9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SearchPage(initialQuery: _searchQuery),
                          ),
                        );
                      },
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search keywords...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF868889),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(Icons.search, color: Color(0xFF868889)),
                        ),
                        suffixIcon: SizedBox(
                          width: _searchQuery.trim().isNotEmpty ? 96 : 48,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (_searchQuery.trim().isNotEmpty)
                                IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    color: Color(0xFF868889),
                                  ),
                                  tooltip: 'Clear',
                                ),
                              IconButton(
                                onPressed: _openHomeFilterSheet,
                                icon: Icon(
                                  Icons.tune,
                                  color: hasActiveFilters
                                      ? const Color(0xFF6CC51D)
                                      : const Color(0xFF868889),
                                ),
                                tooltip: 'Filters',
                              ),
                            ],
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Slider Section
                    SizedBox(
                      height: 200,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _sliderController,
                            itemCount: 3, // Assuming 3 slider images
                            onPageChanged: (index) {
                              setState(() {
                                _currentSliderIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: Colors.grey[300],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.asset(
                                    'images/f.png', // Placeholder, replace with actual slider images
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Slider Indicators
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                3,
                                (index) => Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentSliderIndex == index
                                        ? const Color(0xFF32C95F)
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Offers Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Special Offers',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProductsPage(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: const Text(
                                'See all',
                                style: TextStyle(
                                  color: Color(0xFF6CC51D),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Scrollable Offers Products
                    SizedBox(
                      height: 260,
                      child: _offersLoading
                          ? const Center(child: CircularProgressIndicator())
                          : (_offersError != null
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Text(
                                      _offersError!,
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
                              : (filteredOffers.isEmpty
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
                                  : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredOffers.length,
                        itemBuilder: (context, index) {
                          final product = filteredOffers[index];
                          final productId = product.id;
                          int quantity = _productQuantities[productId] ?? 0;
                          final price = product.price;
                          final name = product.name;
                          final unit = product.unit;
                          final image = product.imagePath;

                          return Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha:0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailPage(
                                      id: productId,
                                      name: name,
                                      unit: unit,
                                      price: price,
                                      imagePath: image,
                                    ),
                                  ),
                                );
                              },
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Product Image
                                      ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(30),
                                          topRight: Radius.circular(30),
                                        ),
                                        child: Image.asset(
                                          image,
                                          width: double.infinity,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            // Price
                                            Text(
                                              '\$${price.toStringAsFixed(2)}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Color(0xFF6CC51D),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            // Product Name
                                            Text(
                                              name,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            // Unit
                                            Text(
                                              unit,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Color(0xFF868889),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            // Divider
                                            const Divider(
                                              height: 1,
                                              color: Color(0xFFE0E0E0),
                                            ),
                                            const SizedBox(height: 8),
                                            // Add to Cart or Quantity Controls
                                            if (quantity == 0)
                                              InkWell(
                                                onTap: () =>
                                                    _addToCart(productId),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: [
                                                      const Icon(
                                                        Icons.add_shopping_cart_outlined,
                                                        size: 16,
                                                        color: Colors.black,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      const Text(
                                                        'Add to cart',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            else
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: () =>
                                                          _decreaseQuantity(
                                                            productId,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                      child: Container(
                                                        width: 24,
                                                        height: 24,
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border.all(
                                                            color:
                                                                const Color(
                                                              0xFFE0E0E0,
                                                            ),
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            4,
                                                          ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.remove,
                                                          size: 16,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    quantity.toString(),
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: () =>
                                                          _increaseQuantity(
                                                            productId,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        4,
                                                      ),
                                                      child: Container(
                                                        width: 24,
                                                        height: 24,
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border.all(
                                                            color:
                                                                const Color(
                                                              0xFFE0E0E0,
                                                            ),
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            4,
                                                          ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.add,
                                                          size: 16,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Heart Icon
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: const Icon(
                                      Icons.favorite_border,
                                      size: 20,
                                      color: Color(0xFF868889),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ))),
                    ),

                    const SizedBox(height: 30),

                    // Categories Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Categories',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              // Handle See all tap for Categories
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: const Text(
                                'See all',
                                style: TextStyle(
                                  color: Color(0xFF6CC51D),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Categories Icons
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: 6,
                        itemBuilder: (context, index) {
                          List<Map<String, String>> categories = [
                            {
                              'icon': 'images/veggies.png',
                              'label': 'Vegetables',
                            },
                            {'icon': 'images/fruits.png', 'label': 'Fruits'},
                            {'icon': 'images/juice.png', 'label': 'Beverages'},
                            {'icon': 'images/grocery.png', 'label': 'Grocery'},
                            {'icon': 'images/oil.png', 'label': 'Edible Oil'},
                            {'icon': 'images/hh.png', 'label': 'Household'},
                          ];

                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      final label =
                                          categories[index]['label'] ?? '';
                                      if (label.isEmpty) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CategoryPage(category: label),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(30),
                                    splashColor: Colors.grey[300],
                                    highlightColor: Colors.grey[200],
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Image.asset(
                                          categories[index]['icon']!,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  categories[index]['label']!,
                                  style: const TextStyle(
                                    color: Color(0xFF868889),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Poppins',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Find Products Section
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Find Products',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Find Products Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SearchPage(initialQuery: 'Fruits'),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: _buildProductCategoryCard(
                                'images/fv.png',
                                'Fresh Fruits\n& Vegetable',
                                const Color(0xFF53B175).withValues(alpha:0.1),
                                const Color(0xFF53B175).withValues(alpha:0.7),
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SearchPage(initialQuery: 'Oil'),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: _buildProductCategoryCard(
                                'images/og.png',
                                'Cooking Oil\n& Ghee',
                                const Color(0xFFF8A44C).withValues(alpha:0.1),
                                const Color(0xFFF8A44C).withValues(alpha:0.7),
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SearchPage(initialQuery: 'Meat'),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: _buildProductCategoryCard(
                                'images/mf.png',
                                'Meat & Fish',
                                const Color(0xFFF7A593).withValues(alpha:0.25),
                                const Color(0xFFF7A593),
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SearchPage(
                                      initialQuery: 'Bakery',
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: _buildProductCategoryCard(
                                'images/bs.png',
                                'Bakery & Snacks',
                                const Color(0xFFD3B0E0).withValues(alpha:0.25),
                                const Color(0xFFD3B0E0),
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SearchPage(initialQuery: 'Egg'),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: _buildProductCategoryCard(
                                'images/de.png',
                                'Dairy & Eggs',
                                const Color(0xFFFDE598).withValues(alpha:0.25),
                                const Color(0xFFFDE598),
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SearchPage(
                                      initialQuery: 'Beverages',
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: _buildProductCategoryCard(
                                'images/bb.png',
                                'Beverages',
                                const Color(0xFFB7DFF5).withValues(alpha:0.25),
                                const Color(0xFFB7DFF5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  Widget _buildProductCategoryCard(
    String imagePath,
    String title,
    Color fillColor,
    Color strokeColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: strokeColor, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, width: 80, height: 80, fit: BoxFit.contain),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
            color: Colors.grey.withValues(alpha:0.2),
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

        // Navigate for major tabs
        if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ExplorePage()),
          );
          return;
        }
        if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CartPage()),
          );
          return;
        }
        if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const FavouritePage()),
          );
          return;
        }
        if (index == 4) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AccountPage()),
          );
          return;
        }

        // Animate previous item out
        _navAnimationControllers[_currentIndex].reverse();
        // Update index
        setState(() {
          _currentIndex = index;
        });
        // Animate new item in
        _navAnimationControllers[index].forward();
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
