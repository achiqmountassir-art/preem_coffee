import 'package:flutter/material.dart';

/// Renders a product image from a network URL or local asset path.
class ProductImageView extends StatelessWidget {
  const ProductImageView({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  final String? source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  bool get _isNetwork {
    final value = source;
    return value != null &&
        (value.startsWith('http://') || value.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    final value = source;
    if (value == null || value.isEmpty) {
      return errorBuilder?.call(context, 'missing', StackTrace.empty) ??
          SizedBox(width: width, height: height);
    }

    if (_isNetwork) {
      return Image.network(
        value,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }

    return Image.asset(
      value,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }
}
