class Product {
  const Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.imagePath,
    this.category,
  });

  final String id;
  final String name;
  final String unit;
  final double price;
  final String imagePath;
  final String? category;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      unit: (json['unit'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imagePath: (json['imagePath'] ?? json['image'] ?? '').toString(),
      category: (json['category'] ?? json['categoryName'] ?? json['category_id'])
          ?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'unit': unit,
        'price': price,
        'imagePath': imagePath,
        if (category != null) 'category': category,
      };
}

