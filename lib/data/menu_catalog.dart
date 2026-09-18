import 'package:flutter/material.dart';

import '../models/menu_product.dart';

/// Shared café menu fallback when Supabase is unavailable (e.g. widget tests).
abstract final class MenuCatalog {
  static const categories = [
    'Coffee',
    'Breakfast',
    'Drinks',
    'Desserts',
  ];

  static const coffee = <MenuProduct>[
    MenuProduct(
      name: 'Coffee Ice Cream',
      description:
          'Smooth coffee-flavored ice cream with a rich roasted aroma.',
      priceMad: 28,
      imageAsset: 'assets/images/Coffee Ice Cream.png',
      category: 'Coffee',
    ),
    MenuProduct(
      name: 'Espresso',
      description: 'Rich and intense espresso with a deep roasted flavor.',
      priceMad: 18,
      imageAsset: 'assets/images/Espresso.png',
      category: 'Coffee',
      isPopular: true,
    ),
    MenuProduct(
      name: 'Hot Milk',
      description: 'Warm steamed milk with a smooth and creamy texture.',
      priceMad: 15,
      imageAsset: 'assets/images/Hot Milk.png',
      category: 'Coffee',
    ),
    MenuProduct(
      name: 'Milk Coffee',
      description: 'Fresh brewed coffee blended with warm creamy milk.',
      priceMad: 22,
      imageAsset: 'assets/images/Milk Coffee.png',
      category: 'Coffee',
    ),
    MenuProduct(
      name: 'Latte',
      description:
          'Smooth espresso combined with steamed milk and a light layer of foam.',
      priceMad: 25,
      imageAsset: 'assets/images/Latte.png',
      category: 'Coffee',
    ),
  ];

  static const breakfast = <MenuProduct>[
    MenuProduct(
      name: 'Muffin',
      description:
          'Soft and freshly baked muffin, perfect with your morning coffee.',
      priceMad: 25,
      imageAsset: 'assets/images/Muffin.jpg',
      category: 'Breakfast',
      gradient: [Color(0xFF8D6E63), Color(0xFF5D4037)],
      isPopular: true,
    ),
    MenuProduct(
      name: 'Chicken Salad',
      description:
          'Fresh salad with grilled chicken, vegetables, and a light dressing.',
      priceMad: 25,
      imageAsset: 'assets/images/Chicken Salad.jpg',
      category: 'Breakfast',
      gradient: [Color(0xFF689F38), Color(0xFF33691E)],
    ),
    MenuProduct(
      name: 'Eggs & Toast',
      description:
          'Fresh eggs served with crispy toast for a simple classic breakfast.',
      priceMad: 15,
      imageAsset: 'assets/images/Eggs & Toast.jpg',
      category: 'Breakfast',
      gradient: [Color(0xFFFFB74D), Color(0xFFF57C00)],
    ),
    MenuProduct(
      name: 'Pancakes',
      description:
          'Fluffy pancakes served with a sweet topping for a delicious breakfast.',
      priceMad: 15,
      imageAsset: 'assets/images/Pancakes.jpg',
      category: 'Breakfast',
      gradient: [Color(0xFFD4A574), Color(0xFF8D6E63)],
    ),
    MenuProduct(
      name: 'Avocado Toast',
      description:
          'Toasted bread topped with creamy fresh avocado and light seasoning.',
      priceMad: 25,
      imageAsset: 'assets/images/Avocado Toast.jpg',
      category: 'Breakfast',
      gradient: [Color(0xFF81C784), Color(0xFF388E3C)],
      isPopular: true,
    ),
  ];

  static const drinks = <MenuProduct>[
    MenuProduct(
      name: 'Orange Juice',
      description: 'Freshly squeezed orange juice served chilled.',
      priceMad: 25,
      imageAsset: 'assets/images/Orange Juice.jpg',
      category: 'Drinks',
    ),
    MenuProduct(
      name: 'Lemonade',
      description: 'Refreshing homemade lemonade with bright .',
      priceMad: 18,
      imageAsset: 'assets/images/Lemonade.jpg',
      category: 'Drinks',
    ),
    MenuProduct(
      name: 'Mango Smoothie',
      description: 'Creamy mango smoothie made with fresh mango.',
      priceMad: 28,
      imageAsset: 'assets/images/Mango Smoothie.jpg',
      category: 'Drinks',
    ),
    MenuProduct(
      name: 'Strawberry Smoothie',
      description: 'Fresh strawberry smoothie with a creamy texture.',
      priceMad: 24,
      imageAsset: 'assets/images/Strawberry Smoothie.jpg',
      category: 'Drinks',
    ),
    MenuProduct(
      name: 'Avocado Smoothie',
      description: 'Creamy avocado smoothie made with fresh avocado.',
      priceMad: 22,
      imageAsset: 'assets/images/Avocado Smoothie.jpg',
      category: 'Drinks',
    ),
    MenuProduct(
      name: 'Matcha',
      description:
          'Creamy matcha latte made with premium Japanese matcha and fresh milk.',
      priceMad: 30,
      imageAsset: 'assets/images/Matcha1.jpg',
      category: 'Drinks',
      isPopular: true,
    ),
  ];

  static const desserts = <MenuProduct>[
    MenuProduct(
      name: 'Lemon Cheesecake',
      description: 'Creamy cheesecake with a fresh and refreshing lemon flavor.',
      priceMad: 30,
      imageAsset: 'assets/images/Lemon Cheesecake.jpg',
      category: 'Desserts',
    ),
    MenuProduct(
      name: 'Strawberry Cheesecake',
      description: 'Creamy cheesecake topped with sweet strawberry flavor.',
      priceMad: 32,
      imageAsset: 'assets/images/Strawberry Cheesecake.jpg',
      category: 'Desserts',
    ),
    MenuProduct(
      name: 'Almond Croissant',
      description:
          'Flaky croissant filled with rich almond cream and topped with almonds.',
      priceMad: 25,
      imageAsset: 'assets/images/Almond Croissant.jpg',
      category: 'Desserts',
    ),
    MenuProduct(
      name: 'Chocolate Brownie',
      description:
          'Rich and fudgy chocolate brownie with a deep chocolate flavor.',
      priceMad: 25,
      imageAsset: 'assets/images/Chocolate Brownie.jpg',
      category: 'Desserts',
    ),
    MenuProduct(
      name: 'Crème Brûlée',
      description:
          'Smooth vanilla custard with a perfectly caramelized sugar crust.',
      priceMad: 30,
      imageAsset: 'assets/images/Crème Brûlée.jpg',
      category: 'Desserts',
    ),
    MenuProduct(
      name: 'Vanilla Cupcake',
      description: 'Soft vanilla cupcake topped with creamy vanilla frosting.',
      priceMad: 22,
      imageAsset: 'assets/images/Vanilla Cupcake.jpg',
      category: 'Desserts',
    ),
  ];

  static List<MenuProduct> forCategory(String category) {
    switch (category) {
      case 'Coffee':
        return coffee;
      case 'Breakfast':
        return breakfast;
      case 'Drinks':
        return drinks;
      case 'Desserts':
        return desserts;
      default:
        return const [];
    }
  }

  static List<MenuProduct> get all => [
        ...coffee,
        ...breakfast,
        ...drinks,
        ...desserts,
      ];
}
