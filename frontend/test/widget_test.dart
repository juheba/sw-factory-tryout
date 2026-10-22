import 'package:flutter_test/flutter_test.dart';
import 'package:order_app/main.dart';
import 'package:order_app/orders/orders_repository.dart';

class FakeOrdersRepository implements OrdersRepository {
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
    );
    orders.add(order);
    return order;
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
}
