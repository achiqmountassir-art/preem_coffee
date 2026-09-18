import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

import '../data/menu_catalog.dart';
import '../models/menu_product.dart';
import '../services/product_service.dart';
import '../widgets/product_image_view.dart';

/// Premium home screen shown after the welcome flow.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.onOpenMenuCategory,
    this.onAddToCart,
    this.productService,
  });

  /// Switches to the Menu tab and selects a category.
  final void Function(String category)? onOpenMenuCategory;

  /// Adds a popular product to the shared cart.
  final ValueChanged<MenuProduct>? onAddToCart;

  final ProductService? productService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // ── Brand palette ────────────────────────────────────────────────────
  static const Color _cream = Color(0xFFF5E6D3);
  static const Color _espresso = Color(0xFF2C1810);
  static const Color _gold = Color(0xFFC9A227);
  static const String _logoAsset = 'assets/images/logo.png';

  static const List<String> _categories = [
    'Coffee',
    'Breakfast',
    'Drinks',
    'Desserts',
  ];

  static const _popularGradients = <String, List<Color>>{
    'Espresso': [Color(0xFF4E342E), Color(0xFF1B0E0A)],
    'Matcha': [Color(0xFF81C784), Color(0xFF2E7D32)],
    'Muffin': [Color(0xFF8D6E63), Color(0xFF5D4037)],
    'Avocado Toast': [Color(0xFF81C784), Color(0xFF388E3C)],
  };

  late final ProductService _productService;
  List<MenuProduct> _products = const [];
  bool _loading = true;

  late final AnimationController _entryController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )
      ..forward();
    _searchController.addListener(() {
      setState(() =>
      _searchQuery = _searchController.text.trim().toLowerCase());
    });
    _loadPopular();
  }

  Future<void> _loadPopular() async {
    try {
      final cafeProducts = await _productService.fetchPopularAvailable();
      if (!mounted) return;
      setState(() {
        _products = cafeProducts.map((product) {
          final menu = MenuProduct.fromCafeProduct(product);
          final gradient = _popularGradients[product.name];
          if (gradient == null) return menu;
          return MenuProduct(
            id: menu.id,
            name: menu.name,
            description: menu.description,
            priceMad: menu.priceMad,
            imageAsset: menu.imageAsset,
            category: menu.category,
            available: menu.available,
            isPopular: menu.isPopular,
            gradient: gradient,
          );
        }).toList();
        _loading = false;
      });
      _entryController.forward(from: 0);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _products =
            MenuCatalog.all.where((product) => product.isPopular).toList();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<MenuProduct> get _filteredProducts {
    return _products.where((product) {
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery) ||
          product.description.toLowerCase().contains(_searchQuery);
      return matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .sizeOf(context)
        .width;
    final horizontalPadding = screenWidth * 0.06;

    return Scaffold(
      backgroundColor: _cream,
      appBar: _PremiumAppBar(logoAsset: _logoAsset),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    horizontalPadding, 8, horizontalPadding, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WelcomeSection(
                      greetingStyle: GoogleFonts.playfairDisplay(
                        fontSize: (screenWidth * 0.07).clamp(24.0, 32.0),
                        fontWeight: FontWeight.w700,
                        color: _espresso,
                        height: 1.2,
                      ),
                      subtitleStyle: GoogleFonts.poppins(
                        fontSize: (screenWidth * 0.038).clamp(14.0, 16.0),
                        color: _espresso.withValues(alpha: 0.65),
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.06),
                    _SearchBar(
                      controller: _searchController,
                      onClear: () => _searchController.clear(),
                    ),
                    SizedBox(height: screenWidth * 0.06),
                    _CategoryRow(
                      categories: _categories,
                      onSelected: (index) {
                        // Navigate to menu and select category
                        widget.onOpenMenuCategory?.call(_categories[index]);
                      },
                    ),
                    SizedBox(height: screenWidth * 0.06),
                    Text(
                      'Popular Products',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: (screenWidth * 0.055).clamp(20.0, 24.0),
                        fontWeight: FontWeight.w700,
                        color: _espresso,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 48,
                      height: 3,
                      decoration: BoxDecoration(
                        color: _gold,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.04),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              sliver: _loading
                  ? const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    )
                  : _filteredProducts.isEmpty
                  ? SliverToBoxAdapter(
                child: _EmptyResults(onReset: () => _searchController.clear()),
              )
                  : SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: screenWidth > 600 ? 3 : 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final product = _filteredProducts[index];
                    final animation = CurvedAnimation(
                      parent: _entryController,
                      curve: Interval(
                        (index * 0.12).clamp(0.0, 0.7),
                        ((index * 0.12) + 0.5).clamp(0.3, 1.0),
                        curve: Curves.easeOutCubic,
                      ),
                    );

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(animation),
                        child: _CoffeeCard(
                          product: product,
                          onAdd: () => _handleAddToCart(product),
                        ),
                      ),
                    );
                  },
                  childCount: _filteredProducts.length,
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: screenWidth * 0.04)),
          ],
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

class _PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PremiumAppBar({required this.logoAsset});

  final String logoAsset;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF5E6D3),
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Hero(
            tag: 'preem_logo',
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                    color: const Color(0xFFC9A227).withValues(alpha: 0.5),
                    width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  logoAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.coffee, color: Color(0xFF8B4513)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PREEM', style: GoogleFonts.playfairDisplay(fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C1810),
                  letterSpacing: 2)),
              Text('COFFEE', style: GoogleFonts.poppins(fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8B4513),
                  letterSpacing: 3)),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {},
              child: const Padding(padding: EdgeInsets.all(10),
                  child: Icon(
                      Icons.person_outline_rounded, color: Color(0xFF2C1810),
                      size: 22)),
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection(
      {required this.greetingStyle, required this.subtitleStyle});

  final TextStyle greetingStyle;
  final TextStyle subtitleStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Good Morning ☕', style: greetingStyle),
        const SizedBox(height: 6),
        Text('What would you like to drink today?', style: subtitleStyle),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onClear});

  final TextEditingController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: const Color(0xFF8B4513).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(
            color: const Color(0xFF2C1810), fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search popular...',
          hintStyle: GoogleFonts.poppins(
              color: const Color(0xFF2C1810).withValues(alpha: 0.4),
              fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded,
              color: const Color(0xFF8B4513).withValues(alpha: 0.7)),
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

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.categories, required this.onSelected});

  final List<String> categories;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return _CategoryChip(
            label: categories[index],
            onTap: () => onSelected(index),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 1,
      shadowColor: const Color(0xFF8B4513).withValues(alpha: 0.25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.transparent, width: 1.5),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C1810)),
          ),
        ),
      ),
    );
  }
}

class _CoffeeCard extends StatefulWidget {
  const _CoffeeCard({required this.product, required this.onAdd});

  final MenuProduct product;
  final VoidCallback onAdd;

  @override
  State<_CoffeeCard> createState() => _CoffeeCardState();
}

class _CoffeeCardState extends State<_CoffeeCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFF2C1810).withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.product.gradient ??
                        const [Color(0xFF4E342E), Color(0xFF1B0E0A)],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ProductImageView(
                    source: widget.product.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildIconPlaceholder(),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.product.name, maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2C1810))),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(widget.product.description, maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 11,
                              height: 1.35,
                              color: const Color(0xFF2C1810).withValues(
                                  alpha: 0.55))),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text('${widget.product.priceMad.toStringAsFixed(
                              0)} MAD',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF8B4513))),
                        ),
                        const SizedBox(width: 8),
                        _AddButton(
                          key: ValueKey('add-${widget.product.name}'),
                          onTap: widget.onAdd,
                          onPressChanged: (pressed) =>
                              setState(() => _isPressed = pressed),
                        ),
                      ],
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

  Widget _buildIconPlaceholder() {
    return Stack(
      children: [
        Positioned(right: -8,
            bottom: -8,
            child: Icon(Icons.coffee_rounded, size: 72,
                color: Colors.white.withValues(alpha: 0.12))),
        Center(child: Icon(Icons.local_cafe_rounded, size: 44,
            color: Colors.white.withValues(alpha: 0.85))),
      ],
    );
  }
}

class _AddButton extends StatefulWidget {
  const _AddButton({
    super.key,
    required this.onTap,
    required this.onPressChanged,
  });

  final VoidCallback onTap;
  final ValueChanged<bool> onPressChanged;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 200),
        lowerBound: 0.0,
        upperBound: 0.08);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    widget.onPressChanged(true);
    await _pulseController.forward();
    await _pulseController.reverse();
    widget.onTap();
    widget.onPressChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) =>
          Transform.scale(scale: 1.0 - _pulseController.value, child: child),
      child: Material(
        color: const Color(0xFF8B4513),
        borderRadius: BorderRadius.circular(12),
        elevation: 3,
        shadowColor: const Color(0xFF8B4513).withValues(alpha: 0.4),
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(12),
          child: const SizedBox(width: 36,
              height: 36,
              child: Icon(Icons.add_rounded, color: Colors.white, size: 22)),
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 48),
        Icon(Icons.coffee_outlined, size: 48,
            color: const Color(0xFF8B4513).withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text('No products found', style: GoogleFonts.playfairDisplay(
            fontSize: 18, color: const Color(0xFF2C1810))),
        const SizedBox(height: 8),
        TextButton(onPressed: onReset,
            child: Text('Clear search', style: GoogleFonts.poppins(
                color: const Color(0xFF8B4513), fontWeight: FontWeight.w600))),
      ],
    );
  }
}


