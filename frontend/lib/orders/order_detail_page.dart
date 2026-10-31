import 'package:flutter/material.dart';

import '../products/product_detail_page.dart';
import '../products/products_repository.dart';
import 'orders_repository.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.repository,
    required this.orderId,
    this.productsRepository,
  });

  final OrdersRepository repository;
  final String orderId;

  /// Katalog für Produktnamen; ohne Katalog wird nur die Artikelnummer gezeigt.
  final ProductsRepository? productsRepository;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late final Future<OrderSummary> _order = widget.repository.get(
    widget.orderId,
  );

  late final Future<Map<String, String>> _names =
      widget.productsRepository?.namesBySku() ?? Future.value(const {});

  String _errorText(Object? error) => error is OrderNotFoundException
      ? 'Die Bestellung wurde nicht gefunden. '
            'Möglicherweise existiert sie nicht mehr.'
      : 'Die Bestellung konnte nicht geladen werden: $error';

  void _openProduct(String sku) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProductDetailPage(repository: widget.productsRepository!, sku: sku),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bestellung')),
      body: FutureBuilder<OrderSummary>(
        future: _order,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(_errorText(snapshot.error)));
          }
          final order = snapshot.requireData;
          return FutureBuilder<Map<String, String>>(
            future: _names,
            builder: (context, namesSnapshot) {
              if (namesSnapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final names = namesSnapshot.data ?? const <String, String>{};
              return _buildDetails(order, names);
            },
          );
        },
      ),
    );
  }

  Widget _buildDetails(OrderSummary order, Map<String, String> names) {
    return ListView(
      children: [
        ListTile(title: const Text('Bestell-ID'), subtitle: Text(order.id)),
        ListTile(
          title: const Text('Kunden-ID'),
          subtitle: Text(order.customerId),
        ),
        ListTile(
          title: const Text('Status'),
          subtitle: Text(
            order.status == OrderStatus.cancelled ? 'Storniert' : 'Aktiv',
          ),
        ),
        for (final line in order.items) ...[
          if (names[line.sku] case final name?)
            ListTile(title: const Text('Produkt'), subtitle: Text(name)),
          ListTile(
            title: const Text('Artikelnummer'),
            subtitle: Text(line.sku),
            trailing: widget.productsRepository == null
                ? null
                : const Icon(Icons.chevron_right),
            onTap: widget.productsRepository == null
                ? null
                : () => _openProduct(line.sku),
          ),
          ListTile(
            title: const Text('Menge'),
            subtitle: Text('${line.quantity}'),
          ),
        ],
      ],
    );
  }
}
