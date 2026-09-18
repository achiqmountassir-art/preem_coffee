import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/supabase_tables.dart';
import '../models/cafe_product.dart';

class ProductService {
  ProductService({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  static const productImagesBucket = 'product-images';
  static const _maxImageBytes = 5 * 1024 * 1024;

  Future<List<CafeProduct>> fetchAll() async {
    final response = await _supabase
        .from(SupabaseTables.products)
        .select()
        .order('category')
        .order('name');

    final rows = List<Map<String, dynamic>>.from(response as List);
    return rows.map(CafeProduct.fromJson).toList();
  }

  /// Customer menu: available products only.
  Future<List<CafeProduct>> fetchAvailable() async {
    final products = await fetchAll();
    return products.where((product) => product.available).toList();
  }

  /// Home popular strip.
  Future<List<CafeProduct>> fetchPopularAvailable() async {
    final products = await fetchAvailable();
    return products.where((product) => product.isPopular).toList();
  }

  Future<CafeProduct> create({
    required String name,
    required String description,
    required double priceMad,
    required String category,
    required bool available,
    required bool isPopular,
    String? imageUrl,
  }) async {
    final response = await _supabase
        .from(SupabaseTables.products)
        .insert({
          'name': name.trim(),
          'description': description.trim(),
          'price': priceMad,
          'category': category,
          'available': available,
          'is_popular': isPopular,
          'image_url': _nullableTrim(imageUrl),
        })
        .select()
        .single();

    return CafeProduct.fromJson(Map<String, dynamic>.from(response));
  }

  Future<CafeProduct> update(CafeProduct product) async {
    final response = await _supabase
        .from(SupabaseTables.products)
        .update({
          'name': product.name.trim(),
          'description': product.description.trim(),
          'price': product.priceMad,
          'category': product.category,
          'available': product.available,
          'is_popular': product.isPopular,
          'image_url': _nullableTrim(product.imageUrl),
        })
        .eq('id', product.id)
        .select()
        .single();

    return CafeProduct.fromJson(Map<String, dynamic>.from(response));
  }

  Future<CafeProduct> setAvailable(String id, bool available) async {
    final response = await _supabase
        .from(SupabaseTables.products)
        .update({'available': available})
        .eq('id', id)
        .select()
        .single();

    return CafeProduct.fromJson(Map<String, dynamic>.from(response));
  }

  Future<CafeProduct> setPopular(String id, bool isPopular) async {
    final response = await _supabase
        .from(SupabaseTables.products)
        .update({'is_popular': isPopular})
        .eq('id', id)
        .select()
        .single();

    return CafeProduct.fromJson(Map<String, dynamic>.from(response));
  }

  /// Uploads bytes to Storage and returns the public URL.
  Future<String> uploadProductImage({
    required Uint8List bytes,
    required String contentType,
    required String extension,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('Selected image is empty.');
    }
    if (bytes.lengthInBytes > _maxImageBytes) {
      throw Exception('Image must be 5 MB or smaller.');
    }

    final ext = extension.toLowerCase().replaceAll('.', '');
    final allowed = {'jpg', 'jpeg', 'png', 'webp'};
    if (!allowed.contains(ext)) {
      throw Exception('Use JPG, PNG, or WEBP images only.');
    }

    final mime = contentType.toLowerCase();
    if (!mime.startsWith('image/')) {
      throw Exception('Selected file is not an image.');
    }

    final path =
        '${DateTime.now().millisecondsSinceEpoch}_${_supabase.auth.currentUser?.id ?? 'anon'}_${bytes.hashCode.abs()}.$ext';

    await _supabase.storage.from(productImagesBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );

    return _supabase.storage.from(productImagesBucket).getPublicUrl(path);
  }

  /// Deletes a Storage object when [imageUrl] belongs to our bucket.
  Future<void> deleteStoredImageIfOwned(String? imageUrl) async {
    final path = storagePathFromPublicUrl(imageUrl);
    if (path == null) return;
    try {
      await _supabase.storage.from(productImagesBucket).remove([path]);
    } catch (_) {
      // Best-effort cleanup; product row is already updated/deleted.
    }
  }

  String? storagePathFromPublicUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    final marker = '/object/public/$productImagesBucket/';
    final index = imageUrl.indexOf(marker);
    if (index < 0) return null;
    return Uri.decodeComponent(imageUrl.substring(index + marker.length));
  }

  /// Nulls order_items.product_id first so FK does not block delete.
  Future<void> delete(String id, {String? imageUrl}) async {
    await _supabase
        .from(SupabaseTables.orderItems)
        .update({'product_id': null})
        .eq('product_id', id);

    await _supabase.from(SupabaseTables.products).delete().eq('id', id);
    await deleteStoredImageIfOwned(imageUrl);
  }

  String? _nullableTrim(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
