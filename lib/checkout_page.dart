import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'data/cart_provider.dart';
import 'data/product_provider.dart';
import 'payment_methods_page.dart';
import 'delivery_address_page.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  bool _isProcessing = false;

  void _processPayment() async {
    setState(() => _isProcessing = true);
    // Simulate payment gateway processing
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isProcessing = false);
    
    // Clear cart upon successful "payment"
    final cartRaw = ref.read(cartProvider);
    for (final id in cartRaw.keys.toList()) {
      ref.read(cartProvider.notifier).remove(id);
    }
    
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, a1, a2, child) {
        final curve = CurvedAnimation(parent: a1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.all(32),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6CC51D).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Color(0xFF6CC51D), size: 72)
                      .animate()
                      .scale(duration: 500.ms, curve: Curves.easeOutBack)
                      .fadeIn(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Order Placed!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    fontFamily: 'Poppins',
                    color: Colors.black,
                  ),
                ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms).fadeIn(),
                const SizedBox(height: 8),
                const Text(
                  'Your order has been placed successfully. For more details, check your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14, 
                    fontFamily: 'Poppins',
                    color: Color(0xFF868889),
                    height: 1.5,
                  ),
                ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 100.ms).fadeIn(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6CC51D),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // dialog
                      Navigator.pop(context); // checkout
                    },
                    child: const Text(
                      'Return to Home', 
                      style: TextStyle(
                        color: Colors.white, 
                        fontFamily: 'Poppins', 
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ).animate().scale(duration: 400.ms, delay: 200.ms).fadeIn(),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartRaw = ref.watch(cartProvider);
    final productsAsync = ref.watch(allProductsProvider);
    
    double totalAmount = 0;
    List<Map<String, dynamic>> cartItems = [];
    
    productsAsync.maybeWhen(
      data: (products) {
        for (var entry in cartRaw.entries) {
          final p = products.where((p) => p.id == entry.key).firstOrNull;
          if (p != null) {
            totalAmount += p.price * entry.value;
            cartItems.add({
              'product': p,
              'quantity': entry.value,
            });
          }
        }
      },
      orElse: () {},
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9), // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: _isProcessing 
        ? _buildProcessingView()
        : Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    _buildStepIndicator().animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
                    const SizedBox(height: 30),
                    
                    if (cartItems.isNotEmpty) ...[
                      _buildSectionTitle('Order Summary').animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 12),
                      _buildOrderSummary(cartItems).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
                      const SizedBox(height: 24),
                    ],
                    
                    _buildSectionTitle('Delivery Address').animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 12),
                    _buildAddressCard().animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 24),
                    _buildSectionTitle('Payment Method').animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 12),
                    _buildPaymentCard().animate().fadeIn(delay: 600.ms).slideX(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 32),
                    _buildReceipt(totalAmount).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              _buildBottomAction(totalAmount).animate().slideY(begin: 1.0, end: 0, duration: 600.ms, curve: Curves.easeOutExpo),
            ],
          ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6CC51D).withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ]
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF6CC51D),
              strokeWidth: 3,
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          ),
          const SizedBox(height: 32),
          const Text(
            'Processing Payment...', 
            style: TextStyle(
              fontFamily: 'Poppins', 
              fontSize: 18,
              fontWeight: FontWeight.w600, 
              color: Colors.black
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          const Text(
            'Please do not close the app.', 
            style: TextStyle(
              fontFamily: 'Poppins', 
              fontSize: 14,
              color: Color(0xFF868889)
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(List<Map<String, dynamic>> items) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = items[index]['product'];
          final qty = items[index]['quantity'];
          return Container(
            width: 80,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Image.asset(
                    product.imagePath,
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6CC51D),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      '$qty',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddressCard() {
    return _buildCustomCard(
      icon: Icons.location_on_rounded,
      iconColor: const Color(0xFFFF9800),
      iconBgColor: const Color(0xFFFF9800).withValues(alpha: 0.1),
      title: 'Home Address',
      subtitle: '123 Green Ave, Fresh City',
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const DeliveryAddressPage()));
      },
    );
  }

  Widget _buildPaymentCard() {
    return _buildCustomCard(
      icon: Icons.credit_card_rounded,
      iconColor: const Color(0xFF1A237E),
      iconBgColor: const Color(0xFF1A237E).withValues(alpha: 0.1),
      title: '**** **** **** 4978',
      subtitle: 'Expires 10/24',
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentMethodsPage()));
      },
    );
  }

  Widget _buildCustomCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF868889),
                      fontFamily: 'Poppins',
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC7C7C7), size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildReceipt(double totalAmount) {
    const double deliveryFee = 5.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        children: [
          _buildReceiptRow('Subtotal', '\$${totalAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          _buildReceiptRow('Delivery fee', '\$${deliveryFee.toStringAsFixed(2)}'),
          const SizedBox(height: 20),
          _buildDashedDivider(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total', 
                style: TextStyle(
                  color: Colors.black, 
                  fontFamily: 'Poppins', 
                  fontWeight: FontWeight.w700, 
                  fontSize: 16
                )
              ),
              Text(
                '\$${(totalAmount + deliveryFee).toStringAsFixed(2)}', 
                style: const TextStyle(
                  color: Color(0xFF6CC51D), 
                  fontFamily: 'Poppins', 
                  fontWeight: FontWeight.w800, 
                  fontSize: 20
                )
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label, 
          style: const TextStyle(
            color: Color(0xFF868889), 
            fontFamily: 'Poppins', 
            fontSize: 14,
            fontWeight: FontWeight.w500,
          )
        ),
        Text(
          amount, 
          style: const TextStyle(
            color: Colors.black, 
            fontFamily: 'Poppins', 
            fontWeight: FontWeight.w600, 
            fontSize: 15
          )
        ),
      ],
    );
  }

  Widget _buildDashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFEBEBEB)),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStep(Icons.shopping_bag_rounded, 'Cart', true),
        _buildStepDivider(true),
        _buildStep(Icons.local_shipping_rounded, 'Delivery', true),
        _buildStepDivider(true),
        _buildStep(Icons.payment_rounded, 'Payment', true),
      ],
    );
  }

  Widget _buildStep(IconData icon, String label, bool isActive) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6CC51D) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? const Color(0xFF6CC51D) : const Color(0xFFEBEBEB),
              width: 2,
            ),
          ),
          child: Icon(icon, color: isActive ? Colors.white : const Color(0xFFC7C7C7), size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : const Color(0xFF868889),
            fontSize: 10,
            fontFamily: 'Poppins',
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? const Color(0xFF6CC51D) : const Color(0xFFEBEBEB),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title, 
      style: const TextStyle(
        fontSize: 16, 
        fontWeight: FontWeight.w700, 
        fontFamily: 'Poppins', 
        color: Colors.black
      )
    );
  }

  Widget _buildBottomAction(double totalAmount) {
    const double deliveryFee = 5.0;
    final total = totalAmount + deliveryFee;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ]
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security_rounded, color: Color(0xFF6CC51D), size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Payments are secure and encrypted',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF868889),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6CC51D),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _processPayment,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pay Now', 
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 16, 
                        fontWeight: FontWeight.w700, 
                        fontFamily: 'Poppins'
                      )
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
