import 'package:flutter/material.dart';

import 'products_repository.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.repository,
    required this.sku,
  });

  final ProductsRepository repository;
  final String sku;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final Future<Product> _product = widget.repository.fetchProduct(
    widget.sku,
  );

  String _errorText(Object? error) => error is ProductNotFoundException
      ? 'Das Produkt ${widget.sku} wurde nicht gefunden.'
      : 'Das Produkt konnte nicht geladen werden: $error';

  String _formatPrice(int cents) {
    final euros = cents ~/ 100;
    final rest = (cents % 100).toString().padLeft(2, '0');
    return '$euros,$rest €';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produkt')),
      body: FutureBuilder<Product>(
        future: _product,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(_errorText(snapshot.error)));
          }
          final product = snapshot.requireData;
          return ListView(
            children: [
              ListTile(
                title: const Text('Artikelnummer'),
                subtitle: Text(product.sku),
              ),
              ListTile(title: const Text('Name'), subtitle: Text(product.name)),
              ListTile(
                title: const Text('Preis'),
                subtitle: Text(_formatPrice(product.priceCents)),
              ),
            ],
          );
        },
      ),
    );
  }
}
