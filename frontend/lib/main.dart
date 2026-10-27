import 'package:flutter/material.dart';

import 'orders/orders_page.dart';
import 'orders/orders_repository.dart';
import 'products/products_repository.dart';

/// Basis-URL des Services. Überschreibbar, z. B. für den Android-Emulator:
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

void main() {
  runApp(
    OrderApp(
      repository: ApiOrdersRepository(baseUrl: _apiBaseUrl),
      productsRepository: ApiProductsRepository(baseUrl: _apiBaseUrl),
    ),
  );
}

class OrderApp extends StatelessWidget {
  const OrderApp({
    super.key,
    required this.repository,
    this.productsRepository,
  });

  final OrdersRepository repository;
  final ProductsRepository? productsRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Order App',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: OrdersPage(
        repository: repository,
        productsRepository: productsRepository,
      ),
    );
  }
}
