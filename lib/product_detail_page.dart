import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/cart_provider.dart';
import 'data/favorites_provider.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.imagePath,
    this.description,
    this.nutritionLabel = '100g',
    this.rating = 4.5,
  });

  final String id;
  final String name;
  final String unit;
  final double price;
  final String imagePath;
  final String? description;
  final String nutritionLabel;
  final double rating;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  int _qty = 1;
  bool _detailExpanded = true;

  @override
  void initState() {
    super.initState();
  }

  void _decQty() {
    setState(() {
      if (_qty > 1) _qty -= 1;
    });
  }

  void _incQty() {
    setState(() {
      _qty += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share coming soon')),
                      );
                    },
                    icon: const Icon(Icons.ios_share, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F5F9),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          widget.imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.image, color: Color(0xFFBDBDBD)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.name,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.unit}, Price',
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
                        Consumer(builder: (context, ref, child) {
                          final isFav = ref.watch(favoritesProvider).contains(widget.id);
                          return IconButton(
                            onPressed: () {
                              ref.read(favoritesProvider.notifier).toggle(widget.id);
                            },
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? const Color(0xFF6CC51D) : Colors.black,
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        InkWell(
                          onTap: _decQty,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                            ),
                            child: const Icon(Icons.remove, size: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          '$_qty',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(width: 14),
                        InkWell(
                          onTap: _incQty,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF6CC51D)),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 18,
                              color: Color(0xFF6CC51D),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '\$${widget.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFEDEDED)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => setState(() => _detailExpanded = !_detailExpanded),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Product Detail',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            Icon(
                              _detailExpanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_right,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_detailExpanded)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          widget.description ??
                              '${widget.name} is a fresh product. Apples are nutritious and can be part of a healthy diet.',
                          style: const TextStyle(
                            color: Color(0xFF868889),
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    const Divider(height: 1, color: Color(0xFFEDEDED)),
                    _infoRow(
                      title: 'Nutritions',
                      trailing: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.nutritionLabel,
                          style: const TextStyle(
                            color: Color(0xFF868889),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: Color(0xFFEDEDED)),
                    _infoRow(
                      title: 'Review',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(5, (i) {
                            final filled = widget.rating >= (i + 1);
                            return Icon(
                              filled ? Icons.star : Icons.star_border,
                              size: 16,
                              color: const Color(0xFFF8A44C),
                            );
                          }),
                        ],
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      ref.read(cartProvider.notifier).addWithQty(widget.id, _qty);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added $_qty to basket')),
                      );
                    },
                    child: const Text(
                      'Add To Basket',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            trailing,
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

