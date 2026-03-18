import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/cart_provider.dart';
import 'data/product_provider.dart';
import 'checkout_page.dart';
import 'explore_page.dart';
import 'favourite_page.dart';
import 'store_home_page.dart';
import 'account_page.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> with TickerProviderStateMixin {
  int _currentIndex = 2; // Cart is index 2
  late List<AnimationController> _navAnimationControllers;
  late List<Animation<double>> _navScaleAnimations;

  // Free delivery threshold
  final double _freeDeliveryThreshold = 15.00;

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
      return Tween<double>(
        begin: 1.0,
        end: 1.2,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    }).toList();
    // Start with cart item animated
    _navAnimationControllers[2].forward();
  }

  @override
  void dispose() {
    for (var controller in _navAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  double _getTotalAmount(List<Map<String, dynamic>> items) {
    return items.fold(
      0.0,
      (sum, item) => sum + (item['price'] as double) * (item['quantity'] as int),
    );
  }

  double _getAmountUntilFreeDelivery(double total) {
    final remaining = _freeDeliveryThreshold - total;
    return remaining > 0 ? remaining : 0;
  }

  double _getDeliveryProgress(double total) {
    final progress = total / _freeDeliveryThreshold;
    return progress > 1.0 ? 1.0 : progress;
  }

  void _increaseQuantity(String id) {
    ref.read(cartProvider.notifier).increase(id);
  }

  void _decreaseQuantity(String id) {
    ref.read(cartProvider.notifier).decrease(id);
  }

  void _removeItem(String id) {
    ref.read(cartProvider.notifier).remove(id);
  }

  @override
  Widget build(BuildContext context) {
    final cartRaw = ref.watch(cartProvider);
    final productsAsync = ref.watch(allProductsProvider);
    
    final cartItems = productsAsync.maybeWhen(
      data: (products) {
        return cartRaw.entries.map((entry) {
          final productOpt = products.where((p) => p.id == entry.key).firstOrNull;
          if (productOpt == null) return null;
          return {
            'id': productOpt.id,
            'image': productOpt.imagePath,
            'name': productOpt.name,
            'price': productOpt.price,
            'description': productOpt.unit,
            'quantity': entry.value,
          };
        }).where((e) => e != null).cast<Map<String, dynamic>>().toList();
      },
      orElse: () => <Map<String, dynamic>>[],
    );
    
    final _totalAmount = _getTotalAmount(cartItems);
    final _amountUntilFreeDelivery = _getAmountUntilFreeDelivery(_totalAmount);
    final _deliveryProgress = _getDeliveryProgress(_totalAmount);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Center(
                child: Text(
                  'My Cart',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),

            // Delivery Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This shows after they purchased once cuz their address is saved.',
                    style: TextStyle(
                      color: Color(0xFF868889),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Before free delivery \$${_amountUntilFreeDelivery.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Row with car icon on left and progress bar on right
                  Row(
                    children: [
                      // Car icon on the left
                      const Icon(
                        Icons.local_shipping_outlined,
                        size: 22,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 12),
                      // Progress bar on the right
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _deliveryProgress,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFF4F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF6CC51D).withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(
                    height: 1,
                    color: Color(0xFFEDEDED),
                    thickness: 1,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Cart Items List
            Expanded(
              child: cartItems.isEmpty
                  ? const Center(
                      child: Text(
                        'Your cart is empty',
                        style: TextStyle(
                          color: Color(0xFF868889),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return Column(
                          children: [
                            _buildCartItem(item, index),
                            if (index < cartItems.length - 1)
                              const Divider(
                                height: 1,
                                color: Color(0xFFEDEDED),
                                thickness: 1,
                              ),
                          ],
                        );
                      },
                    ),
            ),

            // Checkout Button
            if (cartItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CheckoutPage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Checkout',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '\$${_totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              item['image'] as String,
              width: 64,
              height: 64,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 64,
                  height: 64,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] as String,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['description'] as String,
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
                    // Remove Button - positioned at top right
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _removeItem(item['id'] as String),
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: Color(0xFF868889),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity Selector
                    Row(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _decreaseQuantity(item['id'] as String),
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                  width: 1,
                                ),
                                shape: BoxShape.circle,
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
                          item['quantity'].toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _increaseQuantity(item['id'] as String),
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFF6CC51D),
                                  width: 1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 16,
                                color: Color(0xFF6CC51D),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Price
                    Text(
                      '\$${((item['price'] as double) * (item['quantity'] as int)).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StoreHomePage()),
          );
          return;
        }
        if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ExplorePage()),
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
