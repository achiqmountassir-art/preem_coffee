import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/menu_catalog.dart';
import '../models/menu_product.dart';
import '../services/product_service.dart';
import '../widgets/menu_category_chip.dart';
import '../widgets/menu_product_card.dart';

/// Full menu screen with category tabs and scrollable product list.
class MenuPage extends StatefulWidget {
  const MenuPage({
    super.key,
    this.initialCategory,
    this.embedded = false,
    this.showAllSections = false,
    this.onCartTap,
    this.onAddToCart,
    this.cartItemCount = 0,
    this.productService,
  });

  /// Category to select on first build (e.g. `'Coffee'`).
  final String? initialCategory;

  /// When true, hides the back button (used inside [MainShell]).
  final bool embedded;

  /// When true, shows every category section in one vertical scroll.
  final bool showAllSections;

  /// Switches to the Cart tab when embedded in [MainShell].
  final VoidCallback? onCartTap;

  final ValueChanged<MenuProduct>? onAddToCart;

  /// Shown on the header cart icon when greater than zero.
  final int cartItemCount;

  final ProductService? productService;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  static const Color _cream = Color(0xFFF5E6D3);
  static const Color _espresso = Color(0xFF2C1810);
  static const Color _gold = Color(0xFFC9A227);

  static const List<String> _categories = MenuCatalog.categories;

  late final ProductService _productService;
  List<MenuProduct> _products = const [];
  bool _loading = true;
  String? _error;

  late int _selectedCategoryIndex;
  late bool _showAllCategories;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
    _selectedCategoryIndex = _indexForCategory(widget.initialCategory);
    _showAllCategories =
        widget.showAllSections && widget.initialCategory == null;
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cafeProducts = await _productService.fetchAvailable();
      if (!mounted) return;
      setState(() {
        _products = cafeProducts.map(MenuProduct.fromCafeProduct).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      // Offline / widget tests without Supabase: use local catalog.
      setState(() {
        _products = MenuCatalog.all;
        _loading = false;
        _error = null;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _indexForCategory(String? category) {
    if (category == null) return 0;
    final normalized = category == 'Dessert' ? 'Desserts' : category;
    final index = _categories.indexOf(normalized);
    return index >= 0 ? index : 0;
  }

  String get _selectedCategory => _categories[_selectedCategoryIndex];

  List<MenuProduct> _byCategory(String category) =>
      _products.where((product) => product.category == category).toList();

  List<MenuProduct> get _coffeeProducts => _byCategory('Coffee');
  List<MenuProduct> get _breakfastProducts => _byCategory('Breakfast');
  List<MenuProduct> get _drinksProducts => _byCategory('Drinks');
  List<MenuProduct> get _dessertProducts => _byCategory('Desserts');

  List<MenuProduct> get _filteredCoffeeProducts =>
      _filterProducts(_coffeeProducts);

  List<MenuProduct> get _filteredBreakfastProducts =>
      _filterProducts(_breakfastProducts);

  List<MenuProduct> get _filteredDrinksProducts =>
      _filterProducts(_drinksProducts);

  List<MenuProduct> get _filteredDessertsProducts =>
      _filterProducts(_dessertProducts);

  List<MenuProduct> _filterProducts(List<MenuProduct> products) {
    if (_searchQuery.isEmpty) return products;
    return products.where((product) {
      return product.name.toLowerCase().contains(_searchQuery) ||
          product.description.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width * 0.06;

    return ColoredBox(
      color: _cream,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MenuHeader(
              showBackButton: !widget.embedded,
              onCartTap: widget.onCartTap ?? _onCartTapPlaceholder,
              cartItemCount: widget.cartItemCount,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                0,
              ),
              child: _MenuSearchBar(
                controller: _searchController,
                hintText: widget.showAllSections
                    ? 'Search menu...'
                    : (_selectedCategory == 'Coffee'
                        ? 'Search coffee...'
                        : 'Search menu...'),
                onClear: () => _searchController.clear(),
              ),
            ),
            const SizedBox(height: 16),
            _CategorySelector(
              categories: _categories,
              selectedIndex: _selectedCategoryIndex,
              onSelected: (index) {
                setState(() {
                  _selectedCategoryIndex = index;
                  _showAllCategories = false;
                  if (!widget.showAllSections) {
                    _searchController.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8B4513),
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: TextButton(
                            onPressed: _loadProducts,
                            child: Text(_error!),
                          ),
                        )
                      : widget.showAllSections
                          ? _buildFullMenuScroll(horizontalPadding)
                          : _buildSingleCategoryContent(horizontalPadding),
            ),
          ],
        ),
      ),
    );
  }

  /// One vertical scroll with every category section (Menu tab).
  Widget _buildFullMenuScroll(double horizontalPadding) {
    final coffeeProducts = _filteredCoffeeProducts;
    final breakfastProducts = _filteredBreakfastProducts;
    final drinksProducts = _filteredDrinksProducts;
    final dessertsProducts = _filteredDessertsProducts;

    final showCoffee = _shouldShowSection('Coffee', coffeeProducts);
    final showBreakfast = _shouldShowSection('Breakfast', breakfastProducts);
    final showDrinks = _shouldShowSection('Drinks', drinksProducts);
    final showDesserts = _shouldShowSection('Desserts', dessertsProducts);

    if (!showCoffee && !showBreakfast && !showDrinks && !showDesserts) {
      return _PlaceholderContent(
        icon: Icons.search_off_rounded,
        message: 'No items match your search.',
        actionLabel: 'Clear search',
        onAction: () => _searchController.clear(),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 24),
      children: [
        if (showCoffee) ...[
          _SectionTitle(category: 'Coffee'),
          const SizedBox(height: 12),
          ...coffeeProducts.map(
            (product) => MenuProductCard(
              product: product,
              onAdd: () => _handleAddToCart(product),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (showBreakfast) ...[
          _SectionTitle(category: 'Breakfast'),
          const SizedBox(height: 12),
          ...breakfastProducts.map(
            (product) => MenuProductCard(
              product: product,
              onAdd: () => _handleAddToCart(product),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (showDrinks) ...[
          _SectionTitle(category: 'Drinks'),
          const SizedBox(height: 12),
          ...drinksProducts.map(
            (product) => MenuProductCard(
              product: product,
              onAdd: () => _handleAddToCart(product),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (showDesserts) ...[
          _SectionTitle(category: 'Desserts'),
          const SizedBox(height: 12),
          ...dessertsProducts.map(
            (product) => MenuProductCard(
              product: product,
              onAdd: () => _handleAddToCart(product),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  bool _shouldShowSection(String category, List<MenuProduct> products) {
    if (_searchQuery.isNotEmpty) {
      if (category == 'Coffee' || category == 'Breakfast' || category == 'Drinks' || category == 'Desserts') {
        return products.isNotEmpty;
      }
      return category.toLowerCase().contains(_searchQuery);
    }

    if (widget.showAllSections && _showAllCategories) return true;
    return _categories[_selectedCategoryIndex] == category;
  }

  Widget _buildSingleCategoryContent(double horizontalPadding) {
    switch (_selectedCategory) {
      case 'Coffee':
        return _buildCategoryProductList(
          horizontalPadding: horizontalPadding,
          category: _selectedCategory,
          products: _filteredCoffeeProducts,
          emptyIcon: Icons.coffee_outlined,
          emptyMessage: 'No coffee matches your search.',
        );
      case 'Breakfast':
        return _buildCategoryProductList(
          horizontalPadding: horizontalPadding,
          category: _selectedCategory,
          products: _filteredBreakfastProducts,
          emptyIcon: Icons.breakfast_dining_rounded,
          emptyMessage: 'No breakfast items match your search.',
        );
      case 'Drinks':
        return _buildCategoryProductList(
          horizontalPadding: horizontalPadding,
          category: _selectedCategory,
          products: _filteredDrinksProducts,
          emptyIcon: Icons.local_drink_outlined,
          emptyMessage: 'No drinks match your search.',
        );
      case 'Desserts':
        return _buildCategoryProductList(
          horizontalPadding: horizontalPadding,
          category: _selectedCategory,
          products: _filteredDessertsProducts,
          emptyIcon: Icons.icecream_outlined,
          emptyMessage: 'No desserts match your search.',
        );
      default:
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            24,
          ),
          children: [
            _SectionTitle(category: _selectedCategory),
            const SizedBox(height: 24),
            _PlaceholderContent(
              icon: Icons.restaurant_menu_rounded,
              message: '$_selectedCategory menu coming soon.',
              subtitle: 'This section will be available in a future update.',
            ),
          ],
        );
    }
  }

  Widget _buildCategoryProductList({
    required double horizontalPadding,
    required String category,
    required List<MenuProduct> products,
    required IconData emptyIcon,
    required String emptyMessage,
  }) {
    if (products.isEmpty) {
      return _PlaceholderContent(
        icon: emptyIcon,
        message: emptyMessage,
        actionLabel: 'Clear search',
        onAction: () => _searchController.clear(),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        8,
        horizontalPadding,
        24,
      ),
      itemCount: products.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SectionTitle(category: category),
          );
        }
        final product = products[index - 1];
        return MenuProductCard(
          product: product,
          onAdd: () => _handleAddToCart(product),
        );
      },
    );
  }

  void _onCartTapPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _espresso,
        content: Text(
          'Cart coming soon',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );
  }

  void _handleAddToCart(MenuProduct product) {
    widget.onAddToCart?.call(product);
    _showAddedSnackBar(product.name);
  }

  void _showAddedSnackBar(String name) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _espresso,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: _gold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$name added to cart',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({
    required this.showBackButton,
    required this.onCartTap,
    this.cartItemCount = 0,
  });

  final bool showBackButton;
  final VoidCallback onCartTap;
  final int cartItemCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(showBackButton ? 8 : 16, 8, 16, 0),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: const Color(0xFF2C1810),
            )
          else
            const SizedBox(width: 8),
          Expanded(
            child: Text(
              'PREEM COFFEE',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2C1810),
                letterSpacing: 1.2,
              ),
            ),
          ),
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onCartTap,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Badge(
                  isLabelVisible: cartItemCount > 0,
                  backgroundColor: const Color(0xFFC9A227),
                  textColor: const Color(0xFF2C1810),
                  label: Text(
                    cartItemCount > 99 ? '99+' : '$cartItemCount',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFF8B4513),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSearchBar extends StatelessWidget {
  const _MenuSearchBar({
    required this.controller,
    required this.hintText,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B4513).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(
          color: const Color(0xFF2C1810),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF2C1810).withValues(alpha: 0.4),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: const Color(0xFF8B4513).withValues(alpha: 0.7),
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                color: const Color(0xFF2C1810).withValues(alpha: 0.5),
                onPressed: onClear,
              );
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width * 0.06;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return MenuCategoryChip(
            label: categories[index],
            isSelected: index == selectedIndex,
            onTap: () => onSelected(index),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C1810),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 48,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFFC9A227),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderContent extends StatelessWidget {
  const _PlaceholderContent({
    required this.icon,
    required this.message,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 56,
              color: const Color(0xFF8B4513).withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                color: const Color(0xFF2C1810),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF2C1810).withValues(alpha: 0.55),
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF8B4513),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
