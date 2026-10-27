import 'package:order_api/api.dart' as api;

/// Ein Produkt des Katalogs (Preis in Cent).
class Product {
  const Product({
    required this.sku,
    required this.name,
    required this.priceCents,
  });

  final String sku;
  final String name;
  final int priceCents;
}

abstract class ProductsRepository {
  /// Liefert alle Produkte des Katalogs.
  Future<List<Product>> listAll();

  /// Liefert die Produktnamen nach Artikelnummer. Ist der Katalog nicht
  /// ladbar, ist das Ergebnis leer, damit Aufrufer auf die Artikelnummer
  /// zurückfallen können.
  Future<Map<String, String>> namesBySku() async {
    try {
      final products = await listAll();
      return {for (final product in products) product.sku: product.name};
    } catch (_) {
      return const {};
    }
  }
}

/// Implementierung auf Basis des aus openapi.yaml generierten Clients.
class ApiProductsRepository extends ProductsRepository {
  ApiProductsRepository({required String baseUrl})
    : _api = api.ProductsApi(api.ApiClient(basePath: baseUrl));

  final api.ProductsApi _api;

  @override
  Future<List<Product>> listAll() async {
    final products = await _api.listProducts() ?? <api.Product>[];
    return products
        .map(
          (product) => Product(
            sku: product.sku,
            name: product.name,
            priceCents: product.priceCents,
          ),
        )
        .toList();
  }
}
