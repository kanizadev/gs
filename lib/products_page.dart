import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/cart_provider.dart';
import 'product_detail_page.dart';
import 'data/product.dart';
import 'data/product_repository.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final ProductRepository _repo = ProductRepository();

  void _addToCart(String productId) {
    ref.read(cartProvider.notifier).add(productId);
  }

  void _decreaseQuantity(String productId) {
    ref.read(cartProvider.notifier).decrease(productId);
  }

  void _increaseQuantity(String productId) {
    ref.read(cartProvider.notifier).increase(productId);
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Special Offers',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FutureBuilder<List<Product>>(
                  future: _repo.searchProducts(query: ''),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF868889),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      );
                    }

                    final products = snapshot.data ?? const <Product>[];
                    if (products.isEmpty) {
                      return const Center(
                        child: Text(
                          'No products',
                          style: TextStyle(
                            color: Color(0xFF868889),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.70,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final productId = product.id;
                        final quantity = cart[productId] ?? 0;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailPage(
                                id: productId,
                                name: product.name,
                                unit: product.unit,
                                price: product.price,
                                imagePath: product.imagePath,
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
                                    product.imagePath,
                                    width: double.infinity,
                                    height: 140,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Price
                                      Text(
                                        '\$${product.price.toStringAsFixed(2)}',
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
                                        product.name,
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
                                        product.unit,
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
                                          onTap: () => _addToCart(productId),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
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
                                                    fontWeight: FontWeight.w500,
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
                                                onTap: () => _decreaseQuantity(
                                                  productId,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFFE0E0E0,
                                                      ),
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(4),
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
                                                fontWeight: FontWeight.w500,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => _increaseQuantity(
                                                  productId,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFFE0E0E0,
                                                      ),
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(4),
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
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
