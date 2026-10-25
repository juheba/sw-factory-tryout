import 'package:flutter/material.dart';

import 'orders_repository.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, required this.repository});

  final OrdersRepository repository;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<OrderSummary>> _orders;
  OrderStatus? _filter;
  OrderSort _sort = OrderSort.oldestFirst;

  @override
  void initState() {
    super.initState();
    _orders = widget.repository.list(status: _filter, sort: _sort);
  }

  void _reload() {
    setState(() {
      _orders = widget.repository.list(status: _filter, sort: _sort);
    });
  }

  void _setSort(OrderSort sort) {
    _sort = sort;
    _reload();
  }

  void _setFilter(OrderStatus? status) {
    _filter = status;
    _reload();
  }

  Future<void> _createDemoOrder() async {
    await widget.repository.create(
      customerId: 'demo-customer',
      sku: 'DEMO-1',
      quantity: 1,
    );
    _reload();
  }

  Future<void> _cancel(OrderSummary order) async {
    try {
      await widget.repository.cancel(order.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stornieren fehlgeschlagen: $error')),
      );
    }
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<List<OrderSummary>>(
          future: _orders,
          builder: (context, snapshot) {
            final orders = snapshot.data;
            final done = snapshot.connectionState == ConnectionState.done;
            return Text(
              done && !snapshot.hasError && orders != null
                  ? 'Bestellungen (${orders.length})'
                  : 'Bestellungen',
            );
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: SegmentedButton<OrderStatus?>(
              segments: const [
                ButtonSegment(value: null, label: Text('Alle')),
                ButtonSegment(value: OrderStatus.created, label: Text('Aktiv')),
                ButtonSegment(
                  value: OrderStatus.cancelled,
                  label: Text('Storniert'),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (selection) => _setFilter(selection.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SegmentedButton<OrderSort>(
              segments: const [
                ButtonSegment(
                  value: OrderSort.newestFirst,
                  label: Text('Neueste zuerst'),
                ),
                ButtonSegment(
                  value: OrderSort.oldestFirst,
                  label: Text('Älteste zuerst'),
                ),
              ],
              selected: {_sort},
              onSelectionChanged: (selection) => _setSort(selection.first),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<OrderSummary>>(
              future: _orders,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Fehler: ${snapshot.error}'));
                }
                final orders = snapshot.data ?? const <OrderSummary>[];
                if (orders.isEmpty) {
                  return const Center(child: Text('Noch keine Bestellungen.'));
                }
                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final cancelled = order.status == OrderStatus.cancelled;
                    return ListTile(
                      title: Text(
                        order.customerId,
                        style: cancelled
                            ? const TextStyle(
                                decoration: TextDecoration.lineThrough,
                              )
                            : null,
                      ),
                      subtitle: Text(
                        '${order.itemCount} Position(en) · ${order.id}',
                      ),
                      trailing: cancelled
                          ? const Chip(label: Text('Storniert'))
                          : IconButton(
                              icon: const Icon(Icons.cancel_outlined),
                              tooltip: 'Bestellung stornieren',
                              onPressed: () => _cancel(order),
                            ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createDemoOrder,
        tooltip: 'Demo-Bestellung anlegen',
        child: const Icon(Icons.add),
      ),
    );
  }
}
