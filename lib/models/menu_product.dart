import 'package:flutter/material.dart';

import 'cafe_product.dart';

/// Customer-facing menu product (from Supabase `products` or catalog fallback).
class MenuProduct {
  const MenuProduct({
    required this.name,
    required this.description,
    required this.priceMad,
    required this.imageAsset,
    required this.category,
    this.gradient,
    this.available = true,
    this.isPopular = false,
    this.id,
  });

  final String? id;
  final String name;
  final String description;
  final double priceMad;
  final String imageAsset;
  final String category;
  final List<Color>? gradient;
  final bool available;
  final bool isPopular;

  factory MenuProduct.fromCafeProduct(CafeProduct product) {
    final image = product.imageUrl;
    return MenuProduct(
      id: product.id,
      name: product.name,
      description: product.description,
      priceMad: product.priceMad,
      imageAsset: (image == null || image.isEmpty)
          ? 'assets/images/logo.png'
          : image,
      category: product.category,
      available: product.available,
      isPopular: product.isPopular,
    );
  }
}
