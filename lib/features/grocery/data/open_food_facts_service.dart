import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';
import 'package:http/http.dart' as http;

final openFoodFactsServiceProvider = Provider<OpenFoodFactsService>((Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return OpenFoodFactsService(client);
});

class OpenFoodFactsException implements Exception {
  const OpenFoodFactsException(this.message);

  final String message;

  @override
  String toString() => 'OpenFoodFactsException($message)';
}

class OpenFoodFactsService {
  const OpenFoodFactsService(this._client);

  final http.Client _client;

  Future<OpenFoodProduct?> lookupBarcode(String barcode) async {
    final normalizedBarcode = barcode.trim();
    if (normalizedBarcode.isEmpty) {
      return null;
    }
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/api/v0/product/$normalizedBarcode.json',
    );
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const OpenFoodFactsException(
          'Product lookup is unavailable right now.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const OpenFoodFactsException('Unexpected product response.');
      }
      if ((decoded['status'] as num?)?.toInt() == 0) {
        return null;
      }
      final product = decoded['product'];
      if (product is! Map<String, dynamic>) {
        throw const OpenFoodFactsException('Product details were incomplete.');
      }
      final categoryTags =
          (product['categories_tags'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .toList();
      final name =
          (product['product_name'] as String?)?.trim().isNotEmpty == true
          ? (product['product_name'] as String).trim()
          : ((product['product_name_en'] as String?)?.trim() ?? '');
      if (name.isEmpty) {
        throw const OpenFoodFactsException('Product name was unavailable.');
      }
      return OpenFoodProduct(
        name: name,
        brand: (product['brands'] as String?)?.trim() ?? '',
        quantityString: (product['quantity'] as String?)?.trim() ?? '',
        inferredSection: _inferSection(categoryTags),
        imageUrl: (product['image_url'] as String?)?.trim().isEmpty ?? true
            ? null
            : (product['image_url'] as String).trim(),
      );
    } on TimeoutException {
      throw const OpenFoodFactsException(
        'The product lookup took too long. Try again.',
      );
    } on http.ClientException {
      throw const OpenFoodFactsException(
        'Could not reach the product database.',
      );
    } on FormatException {
      throw const OpenFoodFactsException('Product data could not be read.');
    }
  }

  ShoppingSection _inferSection(List<String> tags) {
    final flat = tags.join(' ').toLowerCase();
    if (flat.contains('dairy') ||
        flat.contains('milk') ||
        flat.contains('cheese') ||
        flat.contains('yogurt')) {
      return ShoppingSection.dairy;
    }
    if (flat.contains('meat') ||
        flat.contains('beef') ||
        flat.contains('chicken') ||
        flat.contains('fish') ||
        flat.contains('seafood')) {
      return ShoppingSection.meat;
    }
    if (flat.contains('bread') ||
        flat.contains('bakery') ||
        flat.contains('pastry')) {
      return ShoppingSection.bakery;
    }
    if (flat.contains('frozen')) {
      return ShoppingSection.frozen;
    }
    if (flat.contains('beverage') ||
        flat.contains('drink') ||
        flat.contains('juice') ||
        flat.contains('water') ||
        flat.contains('soda')) {
      return ShoppingSection.beverages;
    }
    if (flat.contains('fruit') ||
        flat.contains('vegetable') ||
        flat.contains('produce')) {
      return ShoppingSection.produce;
    }
    if (flat.contains('household') ||
        flat.contains('cleaning') ||
        flat.contains('laundry')) {
      return ShoppingSection.household;
    }
    if (flat.contains('personal') ||
        flat.contains('hygiene') ||
        flat.contains('cosmetic')) {
      return ShoppingSection.personal;
    }
    if (flat.contains('canned') ||
        flat.contains('preserved') ||
        flat.contains('tin')) {
      return ShoppingSection.canned;
    }
    return ShoppingSection.other;
  }
}
