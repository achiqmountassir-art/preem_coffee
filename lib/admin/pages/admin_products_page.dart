import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/cafe_product.dart';
import '../../services/product_service.dart';
import '../../widgets/product_image_view.dart';
import '../admin_colors.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key, this.productService});

  final ProductService? productService;

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  static const _categoryOrder = ['Coffee', 'Breakfast', 'Drinks', 'Desserts'];

  late final ProductService _productService;
  List<CafeProduct>? _products;
  String? _error;
  bool _loading = true;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await _productService.fetchAll();
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? const Color(0xFFA33B2B) : AdminColors.coffeeBrown,
      ),
    );
  }

  Future<void> _runBusy(String id, Future<void> Function() action) async {
    setState(() => _busyIds.add(id));
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<void> _openEditor({CafeProduct? existing}) async {
    final result = await showDialog<_ProductFormResult>(
      context: context,
      builder: (context) => _ProductEditorDialog(existing: existing),
    );
    if (result == null) return;
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: AdminColors.coffeeBrown),
          ),
        ),
      ),
    );

    try {
      var imageUrl = result.existingImageUrl;
      final bytes = result.imageBytes;
      if (bytes != null) {
        imageUrl = await _productService.uploadProductImage(
          bytes: bytes,
          contentType: result.imageContentType ?? 'image/jpeg',
          extension: result.imageExtension ?? 'jpg',
        );
      }

      if (existing == null) {
        await _productService.create(
          name: result.name,
          description: result.description,
          priceMad: result.priceMad,
          category: result.category,
          available: result.available,
          isPopular: result.isPopular,
          imageUrl: imageUrl,
        );
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        _snack('Product added');
      } else {
        final previousUrl = existing.imageUrl;
        await _productService.update(
          existing.copyWith(
            name: result.name,
            description: result.description,
            priceMad: result.priceMad,
            category: result.category,
            available: result.available,
            isPopular: result.isPopular,
            imageUrl: imageUrl,
            clearImageUrl: imageUrl == null || imageUrl.isEmpty,
          ),
        );
        if (bytes != null &&
            previousUrl != null &&
            previousUrl != imageUrl) {
          await _productService.deleteStoredImageIfOwned(previousUrl);
        }
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        _snack('Product updated');
      }
      await _load();
    } catch (error) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      _snack(error.toString(), error: true);
    }
  }

  Future<void> _toggleAvailable(CafeProduct product) async {
    await _runBusy(product.id, () async {
      try {
        await _productService.setAvailable(product.id, !product.available);
        _snack(product.available ? 'Marked unavailable' : 'Marked available');
        await _load();
      } catch (error) {
        _snack(error.toString(), error: true);
      }
    });
  }

  Future<void> _togglePopular(CafeProduct product) async {
    await _runBusy(product.id, () async {
      try {
        await _productService.setPopular(product.id, !product.isPopular);
        _snack(product.isPopular ? 'Removed from popular' : 'Marked popular');
        await _load();
      } catch (error) {
        _snack(error.toString(), error: true);
      }
    });
  }

  Future<void> _delete(CafeProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Delete “${product.name}” from the menu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _runBusy(product.id, () async {
      try {
        await _productService.delete(product.id, imageUrl: product.imageUrl);
        _snack('Product deleted');
        await _load();
      } catch (error) {
        _snack(error.toString(), error: true);
      }
    });
  }

  List<String> _categoriesFor(List<CafeProduct> products) {
    final present = <String>{};
    for (final product in products) {
      present.add(product.category);
    }
    final ordered = [
      for (final category in _categoryOrder)
        if (present.contains(category)) category,
    ];
    for (final category in present) {
      if (!ordered.contains(category)) ordered.add(category);
    }
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 700 ? 32.0 : 20.0;
          final products = _products ?? const <CafeProduct>[];
          final categories = _categoriesFor(products);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 8),
                sliver: SliverToBoxAdapter(
                  child: constraints.maxWidth < 640
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PageTitle(count: products.length),
                            const SizedBox(height: 16),
                            _AddProductButton(onPressed: () => _openEditor()),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _PageTitle(count: products.length)),
                            const SizedBox(width: 12),
                            _AddProductButton(onPressed: () => _openEditor()),
                          ],
                        ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AdminColors.coffeeBrown,
                    ),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFA33B2B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                for (final category in categories) ...[
                  SliverPadding(
                    padding:
                        EdgeInsets.fromLTRB(horizontal, 20, horizontal, 8),
                    sliver: SliverToBoxAdapter(
                      child: _CategoryHeader(
                        category: category,
                        count: products
                            .where((product) => product.category == category)
                            .length,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: horizontal),
                    sliver: SliverList.separated(
                      itemCount: products
                          .where((product) => product.category == category)
                          .length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final categoryProducts = products
                            .where((product) => product.category == category)
                            .toList();
                        final product = categoryProducts[index];
                        return _ProductRow(
                          product: product,
                          busy: _busyIds.contains(product.id),
                          onEdit: () => _openEditor(existing: product),
                          onDelete: () => _delete(product),
                          onToggleAvailable: () => _toggleAvailable(product),
                          onTogglePopular: () => _togglePopular(product),
                        );
                      },
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu / Products',
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AdminColors.espresso,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$count products across the café menu',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AdminColors.muted,
          ),
        ),
      ],
    );
  }
}

class _AddProductButton extends StatelessWidget {
  const _AddProductButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AdminColors.coffeeBrown,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: Text(
        'Add Product',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category, required this.count});

  final String category;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              category,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AdminColors.espresso,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AdminColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 2,
          width: 56,
          decoration: BoxDecoration(
            color: AdminColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailable,
    required this.onTogglePopular,
  });

  final CafeProduct product;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailable;
  final VoidCallback onTogglePopular;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AdminColors.espresso.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _ProductImage(imageUrl: imageUrl),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.espresso,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    height: 1.4,
                    color: AdminColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${product.priceMad.toStringAsFixed(0)} MAD',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.coffeeBrown,
                      ),
                    ),
                    InkWell(
                      onTap: busy ? null : onToggleAvailable,
                      child: _StatusPill(
                        label: product.available ? 'Available' : 'Unavailable',
                        ok: product.available,
                      ),
                    ),
                    InkWell(
                      onTap: busy ? null : onTogglePopular,
                      child: Text(
                        product.isPopular ? '⭐ Popular' : 'Not Popular',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: product.isPopular
                              ? AdminColors.coffeeBrown
                              : AdminColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Wrap(
              spacing: 6,
              children: [
                TextButton(
                  onPressed: onEdit,
                  child: Text(
                    'Edit',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AdminColors.coffeeBrown,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onDelete,
                  child: Text(
                    'Delete',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFA33B2B),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: Color(0xFF5D4037),
      child: SizedBox(
        width: 84,
        height: 84,
        child: Icon(Icons.coffee, color: Colors.white70),
      ),
    );

    return ProductImageView(
      source: imageUrl,
      width: 84,
      height: 84,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Text(
      ok ? '$label ✓' : '$label ✕',
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: ok ? const Color(0xFF3D7A4A) : const Color(0xFFA33B2B),
      ),
    );
  }
}

class _ProductFormResult {
  const _ProductFormResult({
    required this.name,
    required this.description,
    required this.priceMad,
    required this.category,
    required this.available,
    required this.isPopular,
    this.existingImageUrl,
    this.imageBytes,
    this.imageContentType,
    this.imageExtension,
  });

  final String name;
  final String description;
  final double priceMad;
  final String category;
  final bool available;
  final bool isPopular;
  final String? existingImageUrl;
  final Uint8List? imageBytes;
  final String? imageContentType;
  final String? imageExtension;
}

class _ProductEditorDialog extends StatefulWidget {
  const _ProductEditorDialog({this.existing});

  final CafeProduct? existing;

  @override
  State<_ProductEditorDialog> createState() => _ProductEditorDialogState();
}

class _ProductEditorDialogState extends State<_ProductEditorDialog> {
  static const _categories = ['Coffee', 'Breakfast', 'Drinks', 'Desserts'];
  static const _allowedExt = {'jpg', 'jpeg', 'png', 'webp'};

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late String _category;
  late bool _available;
  late bool _isPopular;
  String? _existingImageUrl;
  Uint8List? _pickedBytes;
  String? _pickedContentType;
  String? _pickedExtension;
  bool _picking = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _price = TextEditingController(
      text: existing == null ? '' : existing.priceMad.toStringAsFixed(0),
    );
    _category = existing?.category ?? _categories.first;
    _available = existing?.available ?? true;
    _isPopular = existing?.isPopular ?? false;
    _existingImageUrl = existing?.imageUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() {
      _picking = true;
      _validationError = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (file == null) return;

      final name = file.name.toLowerCase();
      final mime = (file.mimeType ?? '').toLowerCase();
      var ext = '';
      if (name.contains('.')) {
        ext = name.split('.').last;
      } else if (mime.contains('/')) {
        ext = mime.split('/').last;
      }
      if (ext == 'jpg') ext = 'jpeg';

      final isImageMime = mime.isEmpty || mime.startsWith('image/');
      final isAllowedExt = _allowedExt.contains(ext) ||
          mime == 'image/jpeg' ||
          mime == 'image/png' ||
          mime == 'image/webp' ||
          mime == 'image/jpg';

      if (!isImageMime || !isAllowedExt) {
        setState(() {
          _validationError = 'Please choose a JPG, PNG, or WEBP image.';
        });
        return;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        setState(() => _validationError = 'Selected image is empty.');
        return;
      }
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        setState(() => _validationError = 'Image must be 5 MB or smaller.');
        return;
      }

      setState(() {
        _pickedBytes = bytes;
        _pickedContentType = mime.isNotEmpty
            ? mime
            : (ext == 'png'
                ? 'image/png'
                : ext == 'webp'
                    ? 'image/webp'
                    : 'image/jpeg');
        _pickedExtension = ext == 'jpeg' ? 'jpg' : ext;
      });
    } catch (error) {
      setState(() => _validationError = error.toString());
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _save() {
    final name = _name.text.trim();
    final description = _description.text.trim();
    final price = double.tryParse(_price.text.trim().replaceAll(',', '.'));
    if (name.isEmpty) {
      setState(() => _validationError = 'Name is required.');
      return;
    }
    if (price == null || price < 0) {
      setState(() => _validationError = 'Enter a valid price.');
      return;
    }
    Navigator.pop(
      context,
      _ProductFormResult(
        name: name,
        description: description,
        priceMad: price,
        category: _category,
        available: _available,
        isPopular: _isPopular,
        existingImageUrl: _existingImageUrl,
        imageBytes: _pickedBytes,
        imageContentType: _pickedContentType,
        imageExtension: _pickedExtension,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final hasImage =
        _pickedBytes != null || (_existingImageUrl?.isNotEmpty ?? false);

    return AlertDialog(
      title: Text(isEdit ? 'Edit Product' : 'Add Product'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Price (MAD)'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: [
                  for (final category in _categories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  hasImage ? 'Current Image' : 'Product Image Preview',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.espresso,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: _pickedBytes != null
                      ? Image.memory(
                          _pickedBytes!,
                          fit: BoxFit.cover,
                        )
                      : (_existingImageUrl?.isNotEmpty ?? false)
                          ? ProductImageView(
                              source: _existingImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const ColoredBox(
                                color: Color(0xFF5D4037),
                                child: Center(
                                  child:
                                      Icon(Icons.coffee, color: Colors.white70),
                                ),
                              ),
                            )
                          : const ColoredBox(
                              color: Color(0xFF5D4037),
                              child: Center(
                                child:
                                    Icon(Icons.coffee, color: Colors.white70),
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _picking ? null : _pickImage,
                  icon: _picking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          hasImage
                              ? Icons.photo_camera_back_outlined
                              : Icons.add_a_photo_outlined,
                        ),
                  label: Text(hasImage ? 'Change Photo' : '+ Add Photo'),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available'),
                value: _available,
                onChanged: (value) => setState(() => _available = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('⭐ Popular'),
                value: _isPopular,
                onChanged: (value) => setState(() => _isPopular = value),
              ),
              if (_validationError != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _validationError!,
                    style: const TextStyle(color: Color(0xFFA33B2B)),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: AdminColors.coffeeBrown,
          ),
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
