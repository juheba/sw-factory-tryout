import 'package:flutter_test/flutter_test.dart';
import 'package:order_app/main.dart';
import 'package:order_app/orders/orders_repository.dart';

class FakeOrdersRepository implements OrdersRepository {
  FakeOrdersRepository({this.failCancel = false});

  final bool failCancel;
  final List<OrderSummary> orders = [];

  @override
  Future<List<OrderSummary>> list() async => List.of(orders);

  @override
  Future<OrderSummary> create({
    required String customerId,
    required String sku,
    required int quantity,
  }) async {
    final order = OrderSummary(
      id: 'id-${orders.length + 1}',
      customerId: customerId,
      itemCount: 1,
      status: OrderStatus.created,
    );
    orders.add(order);
    return order;
  }

  @override
  Future<OrderSummary> cancel(String id) async {
    if (failCancel) {
      throw StateError('Bestellung ist bereits storniert');
    }
    final index = orders.indexWhere((order) => order.id == id);
    final previous = orders[index];
    final cancelled = OrderSummary(
      id: previous.id,
      customerId: previous.customerId,
      itemCount: previous.itemCount,
      status: OrderStatus.cancelled,
    );
    orders[index] = cancelled;
    return cancelled;
  }
}

void main() {
  testWidgets('zeigt Hinweis bei leerer Liste', (tester) async {
    await tester.pumpWidget(OrderApp(repository: FakeOrdersRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Bestellungen.'), findsOneWidget);
  });

  testWidgets('legt Demo-Bestellung an und zeigt sie', (tester) async {
    await tester.pumpWidget(OrderApp(repository: FakeOrdersRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Demo-Bestellung anlegen'));
    await tester.pumpAndSettle();

    expect(find.text('demo-customer'), findsOneWidget);
    expect(find.text('Noch keine Bestellungen.'), findsNothing);
  });

  testWidgets('storniert eine Bestellung und zeigt den Status', (tester) async {
    await tester.pumpWidget(OrderApp(repository: FakeOrdersRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Demo-Bestellung anlegen'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bestellung stornieren'));
    await tester.pumpAndSettle();

    expect(find.text('Storniert'), findsOneWidget);
    expect(find.byTooltip('Bestellung stornieren'), findsNothing);
  });

  testWidgets('zeigt Fehlermeldung, wenn Stornieren fehlschlägt', (
    tester,
  ) async {
    final repository = FakeOrdersRepository(failCancel: true);
    await tester.pumpWidget(OrderApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Demo-Bestellung anlegen'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bestellung stornieren'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Stornieren fehlgeschlagen'), findsOneWidget);
    expect(find.text('Storniert'), findsNothing);
  });
}
