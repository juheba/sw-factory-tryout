import 'package:flutter/material.dart';

import 'orders_repository.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.repository,
    required this.orderId,
  });

  final OrdersRepository repository;
  final String orderId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late final Future<OrderSummary> _order = widget.repository.get(
    widget.orderId,
  );

  String _errorText(Object? error) => error is OrderNotFoundException
      ? 'Die Bestellung wurde nicht gefunden. '
            'Möglicherweise existiert sie nicht mehr.'
      : 'Die Bestellung konnte nicht geladen werden: $error';

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
          return ListView(
            children: [
              ListTile(
                title: const Text('Bestell-ID'),
                subtitle: Text(order.id),
              ),
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
                ListTile(
                  title: const Text('Artikelnummer'),
                  subtitle: Text(line.sku),
                ),
                ListTile(
                  title: const Text('Menge'),
                  subtitle: Text('${line.quantity}'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
