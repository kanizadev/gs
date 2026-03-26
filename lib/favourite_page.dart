import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cart_page.dart';
import 'explore_page.dart';
import 'product_detail_page.dart';
import 'store_home_page.dart';
import 'account_page.dart';
import 'data/favorites_provider.dart';
import 'data/product_provider.dart';

class FavouritePage extends ConsumerStatefulWidget {
  const FavouritePage({super.key});

  @override
  ConsumerState<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends ConsumerState<FavouritePage>
    with TickerProviderStateMixin {
  int _currentIndex = 3; // Favourite is index 3
  late List<AnimationController> _navAnimationControllers;
  late List<Animation<double>> _navScaleAnimations;

  @override
  void initState() {
    super.initState();
    _initializeNavAnimations();
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
    for (final c in _navAnimationControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoriteIds = ref.watch(favoritesProvider);
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Center(
                child: Text(
                  'Favourite',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEDEDED), thickness: 1),
            Expanded(
              child: favoriteIds.isEmpty
                  ? const Center(
                      child: Text(
                        'No favourites yet',
                        style: TextStyle(
                          color: Color(0xFF868889),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    )
                  : productsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (e, st) => Center(
                        child: Text(
                          e.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF868889),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      data: (products) {
                        final items = products
                            .where((p) => favoriteIds.contains(p.id))
                            .toList();
                        return items.isEmpty
                            ? const Center(
                                child: Text(
                                  'No favourites yet',
                                  style: TextStyle(
                                    color: Color(0xFF868889),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  12,
                                  20,
                                  12,
                                ),
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const Divider(
                                  height: 24,
                                  color: Color(0xFFEDEDED),
                                  thickness: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final p = items[index];
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetailPage(
                                            id: p.id,
                                            name: p.name,
                                            unit: p.unit,
                                            price: p.price,
                                            imagePath: p.imagePath,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.asset(
                                            p.imagePath,
                                            width: 58,
                                            height: 58,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                              width: 58,
                                              height: 58,
                                              color: const Color(0xFFF4F5F9),
                                              child: const Icon(
                                                Icons.image,
                                                color: Color(0xFFBDBDBD),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p.name,
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                p.unit,
                                                style: const TextStyle(
                                                  color: Color(0xFF868889),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '\$${p.price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        IconButton(
                                          onPressed: () {
                                            ref
                                                .read(favoritesProvider
                                                    .notifier)
                                                .toggle(p.id);
                                          },
                                          icon: const Icon(
                                            Icons.close,
                                            size: 18,
                                            color: Color(0xFF868889),
                                          ),
                                          tooltip: 'Remove',
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                      },
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

