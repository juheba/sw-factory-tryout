import 'package:order_api/api.dart' as api;

enum OrderStatus { created, cancelled }

/// Frontend-eigenes Modell. Entkoppelt die UI vom generierten Client:
/// Ändert sich die Spec, muss nur diese Datei angepasst werden.
class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.customerId,
    required this.itemCount,
    required this.status,
  });

  final String id;
  final String customerId;
  final int itemCount;
  final OrderStatus status;
}

abstract class OrdersRepository {
  Future<List<OrderSummary>> list();

  Future<OrderSummary> create({
    required String customerId,
    required String sku,
    required int quantity,
  });

  Future<OrderSummary> cancel(String id);
}

/// Implementierung auf Basis des aus openapi.yaml generierten Clients.
class ApiOrdersRepository implements OrdersRepository {
  ApiOrdersRepository({required String baseUrl})
    : _api = api.OrdersApi(api.ApiClient(basePath: baseUrl));

  final api.OrdersApi _api;

  @override
  Future<List<OrderSummary>> list() async {
    final orders = await _api.listOrders() ?? <api.Order>[];
    return orders.map(_toSummary).toList();
  }

  @override
  Future<OrderSummary> create({
    required String customerId,
    required String sku,
    required int quantity,
  }) async {
    final request = api.CreateOrderRequest(
      customerId: customerId,
      items: [api.OrderItem(sku: sku, quantity: quantity)],
    );
    final created = await _api.createOrder(request);
    if (created == null) {
      throw StateError('Der Service hat keine Bestellung zurückgegeben.');
    }
    return _toSummary(created);
  }

  @override
  Future<OrderSummary> cancel(String id) async {
    final cancelled = await _api.cancelOrder(id);
    if (cancelled == null) {
      throw StateError('Der Service hat keine Bestellung zurückgegeben.');
    }
    return _toSummary(cancelled);
  }

  OrderSummary _toSummary(api.Order order) => OrderSummary(
    id: order.id,
    customerId: order.customerId,
    itemCount: order.items.length,
    status: order.status == api.OrderStatus.CANCELLED
        ? OrderStatus.cancelled
        : OrderStatus.created,
  );
}
