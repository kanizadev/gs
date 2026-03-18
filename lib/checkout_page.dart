import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Color(0xFF6CC51D), size: 60),
        content: const Text(
          'Order Placed Successfully!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6CC51D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.pop(context); // dialog
                Navigator.pop(context); // checkout
              },
              child: const Text('Continue Shopping', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartRaw = ref.watch(cartProvider);
    final productsAsync = ref.watch(allProductsProvider);
    
    double totalAmount = 0;
    productsAsync.maybeWhen(
      data: (products) {
        for (var entry in cartRaw.entries) {
          final p = products.where((p) => p.id == entry.key).firstOrNull;
          if (p != null) totalAmount += p.price * entry.value;
        }
      },
      orElse: () {},
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isProcessing 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF6CC51D)),
                  SizedBox(height: 20),
                  Text('Processing Payment...', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: Colors.black)),
                ],
              ),
            )
          : ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Colors.black)),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: Color(0xFFF4F5F9), child: Icon(Icons.location_on, color: Color(0xFF6CC51D))),
              title: const Text('Home', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 14)),
              subtitle: const Text('123 Green Ave, Fresh City', style: TextStyle(color: Color(0xFF868889), fontFamily: 'Poppins', fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF868889)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DeliveryAddressPage()));
              },
            ),
            const SizedBox(height: 20),
            const Text('Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Colors.black)),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: Color(0xFF1A237E), child: Icon(Icons.credit_card, color: Colors.white)),
              title: const Text('**** **** **** 4978', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 14)),
              subtitle: const Text('Expires 10/24', style: TextStyle(color: Color(0xFF868889), fontFamily: 'Poppins', fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF868889)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentMethodsPage()));
              },
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(color: Color(0xFF868889), fontFamily: 'Poppins', fontSize: 14)),
                      Text('\$${totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black, fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery fee', style: TextStyle(color: Color(0xFF868889), fontFamily: 'Poppins', fontSize: 14)),
                      const Text('\$5.00', style: TextStyle(color: Colors.black, fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(color: Colors.black, fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('\$${(totalAmount + 5.0).toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF6CC51D), fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6CC51D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _processPayment,
                child: const Text('Confirm Payment', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
