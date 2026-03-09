import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/features/grocery/data/open_food_facts_service.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('lookupBarcode returns parsed product and infers section', () async {
    final service = OpenFoodFactsService(
      MockClient((request) async {
        expect(
          request.url.toString(),
          'https://world.openfoodfacts.org/api/v0/product/123456.json',
        );
        return http.Response(
          jsonEncode(<String, Object?>{
            'status': 1,
            'product': <String, Object?>{
              'product_name': 'Greek Yogurt',
              'brands': 'Hearth Farms',
              'quantity': '500 g',
              'categories_tags': <String>['en:dairy-products', 'en:yogurts'],
              'image_url': 'https://example.com/yogurt.png',
            },
          }),
          200,
        );
      }),
    );

    final product = await service.lookupBarcode('123456');

    expect(product, isNotNull);
    expect(product?.name, 'Greek Yogurt');
    expect(product?.brand, 'Hearth Farms');
    expect(product?.quantityString, '500 g');
    expect(product?.inferredSection, ShoppingSection.dairy);
    expect(product?.imageUrl, 'https://example.com/yogurt.png');
  });

  test('lookupBarcode returns null when product is not found', () async {
    final service = OpenFoodFactsService(
      MockClient((request) async {
        return http.Response(jsonEncode(<String, Object?>{'status': 0}), 200);
      }),
    );

    final product = await service.lookupBarcode('404');

    expect(product, isNull);
  });

  test('lookupBarcode maps canned and produce heuristics correctly', () async {
    final service = OpenFoodFactsService(
      MockClient((request) async {
        final barcode = request.url.pathSegments[3].split('.').first;
        final response = switch (barcode) {
          'produce' => <String, Object?>{
            'status': 1,
            'product': <String, Object?>{
              'product_name': 'Apples',
              'categories_tags': <String>['en:fruit', 'en:produce'],
            },
          },
          _ => <String, Object?>{
            'status': 1,
            'product': <String, Object?>{
              'product_name': 'Beans',
              'categories_tags': <String>['en:canned-foods', 'en:tin'],
            },
          },
        };
        return http.Response(jsonEncode(response), 200);
      }),
    );

    expect(
      (await service.lookupBarcode('produce'))?.inferredSection,
      ShoppingSection.produce,
    );
    expect(
      (await service.lookupBarcode('canned'))?.inferredSection,
      ShoppingSection.canned,
    );
  });

  test('lookupBarcode throws a friendly exception on timeout', () async {
    final service = OpenFoodFactsService(
      MockClient((request) async {
        await Future<void>.delayed(const Duration(seconds: 6));
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      service.lookupBarcode('slow'),
      throwsA(isA<OpenFoodFactsException>()),
    );
  });

  test(
    'lookupBarcode throws a friendly exception on network failure',
    () async {
      final service = OpenFoodFactsService(
        MockClient((request) async {
          throw http.ClientException('offline');
        }),
      );

      await expectLater(
        service.lookupBarcode('offline'),
        throwsA(isA<OpenFoodFactsException>()),
      );
    },
  );
}
