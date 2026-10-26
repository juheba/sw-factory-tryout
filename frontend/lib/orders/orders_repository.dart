import 'package:order_api/api.dart' as api;

enum OrderStatus { created, cancelled }

/// Sortierung nach Anlegedatum.
enum OrderSort { newestFirst, oldestFirst }

/// Eine Position einer Bestellung (Artikelnummer und Menge).
class OrderLine {
  const OrderLine({required this.sku, required this.quantity});

  final String sku;
  final int quantity;
}

/// Wird von [OrdersRepository.get] geworfen, wenn es die Bestellung nicht gibt.
class OrderNotFoundException implements Exception {
  const OrderNotFoundException(this.id);

  final String id;

  @override
  String toString() => 'Bestellung $id nicht gefunden';
}

/// Frontend-eigenes Modell. Entkoppelt die UI vom generierten Client:
/// Ändert sich die Spec, muss nur diese Datei angepasst werden.
class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.customerId,
    required this.itemCount,
    required this.status,
    this.items = const [],
  });

  final String id;
  final String customerId;
  final int itemCount;
  final OrderStatus status;
  final List<OrderLine> items;
}

abstract class OrdersRepository {
  /// Liefert alle Bestellungen, mit [status] nur die mit diesem Status.
  /// Ohne [sort] bleibt die Reihenfolge des Anlegens.
  Future<List<OrderSummary>> list({OrderStatus? status, OrderSort? sort});

  Future<OrderSummary> create({
    required String customerId,
    required String sku,
    required int quantity,
  });

  Future<OrderSummary> cancel(String id);

  /// Liefert die Bestellung [id] oder wirft [OrderNotFoundException].
  Future<OrderSummary> get(String id);
}

/// Implementierung auf Basis des aus openapi.yaml generierten Clients.
class ApiOrdersRepository implements OrdersRepository {
  ApiOrdersRepository({required String baseUrl})
    : _api = api.OrdersApi(api.ApiClient(basePath: baseUrl));

  final api.OrdersApi _api;

  @override
  Future<List<OrderSummary>> list({
    OrderStatus? status,
    OrderSort? sort,
  }) async {
    final orders =
        await _api.listOrders(
          status: _toApiStatus(status),
          sort: _toApiSort(sort),
        ) ??
        <api.Order>[];
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

  @override
  Future<OrderSummary> get(String id) async {
    final api.Order? order;
    try {
      order = await _api.getOrder(id);
    } on api.ApiException catch (error) {
      if (error.code == 404) throw OrderNotFoundException(id);
      rethrow;
    }
    if (order == null) {
      throw StateError('Der Service hat keine Bestellung zurückgegeben.');
    }
    return _toSummary(order);
  }

  api.OrderStatus? _toApiStatus(OrderStatus? status) => switch (status) {
    null => null,
    OrderStatus.created => api.OrderStatus.CREATED,
    OrderStatus.cancelled => api.OrderStatus.CANCELLED,
  };

  api.OrderSort? _toApiSort(OrderSort? sort) => switch (sort) {
    null => null,
    OrderSort.newestFirst => api.OrderSort.createdAtDesc,
    OrderSort.oldestFirst => api.OrderSort.createdAtAsc,
  };

  OrderSummary _toSummary(api.Order order) => OrderSummary(
    id: order.id,
    customerId: order.customerId,
    itemCount: order.items.length,
    status: order.status == api.OrderStatus.CANCELLED
        ? OrderStatus.cancelled
        : OrderStatus.created,
    items: order.items
        .map((item) => OrderLine(sku: item.sku, quantity: item.quantity))
        .toList(),
  );
}
