import 'package:flutter_test/flutter_test.dart';
import 'package:order_api/api.dart' as api;
import 'package:order_app/products/products_repository.dart';

/// Ersetzt den generierten Client, ohne Netzwerk.
class _StubProductsApi extends api.ProductsApi {
  _StubProductsApi(this._respond);

  final Future<api.Product?> Function(String sku) _respond;

  @override
  Future<api.Product?> getProduct(String sku, {Future<void>? abortTrigger}) =>
      _respond(sku);
}

ApiProductsRepository _repository(
  Future<api.Product?> Function(String sku) respond,
) => ApiProductsRepository(
  baseUrl: 'http://localhost',
  productsApi: _StubProductsApi(respond),
);

void main() {
  group('ApiProductsRepository.fetchProduct', () {
    test('200 liefert Product mit sku, name und priceCents', () async {
      final repository = _repository(
        (sku) async => api.Product(sku: sku, name: 'Kaffee', priceCents: 1299),
      );

      final product = await repository.fetchProduct('SKU-1');

      expect(product.sku, 'SKU-1');
      expect(product.name, 'Kaffee');
      expect(product.priceCents, 1299);
    });

    test('404 wird zu ProductNotFoundException mit sku', () async {
      final repository = _repository(
        (sku) async => throw api.ApiException(404, 'Not Found'),
      );

      await expectLater(
        repository.fetchProduct('SKU-X'),
        throwsA(
          isA<ProductNotFoundException>().having((e) => e.sku, 'sku', 'SKU-X'),
        ),
      );
    });

    test('500 bleibt als ApiException erhalten', () async {
      final repository = _repository(
        (sku) async => throw api.ApiException(500, 'Server Error'),
      );

      await expectLater(
        repository.fetchProduct('SKU-1'),
        throwsA(isA<api.ApiException>().having((e) => e.code, 'code', 500)),
      );
    });

    test('leere Antwort wirft StateError', () async {
      final repository = _repository((sku) async => null);

      await expectLater(
        repository.fetchProduct('SKU-1'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
