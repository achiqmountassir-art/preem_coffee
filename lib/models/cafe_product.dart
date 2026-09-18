class CafeProduct {
  const CafeProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.priceMad,
    required this.category,
    required this.available,
    required this.isPopular,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final double priceMad;
  final String category;
  final bool available;
  final bool isPopular;
  final String? imageUrl;

  CafeProduct copyWith({
    String? id,
    String? name,
    String? description,
    double? priceMad,
    String? category,
    bool? available,
    bool? isPopular,
    String? imageUrl,
    bool clearImageUrl = false,
  }) {
    return CafeProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      priceMad: priceMad ?? this.priceMad,
      category: category ?? this.category,
      available: available ?? this.available,
      isPopular: isPopular ?? this.isPopular,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
    );
  }

  factory CafeProduct.fromJson(Map<String, dynamic> json) {
    return CafeProduct(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      priceMad: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      available: json['available'] as bool? ?? true,
      isPopular: json['is_popular'] as bool? ?? false,
      imageUrl: json['image_url'] as String?,
    );
  }
}
