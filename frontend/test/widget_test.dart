import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_app/main.dart';
import 'package:order_app/orders/orders_repository.dart';

class FakeOrdersRepository implements OrdersRepository {
  FakeOrdersRepository({this.failCancel = false});

  final bool failCancel;
  final List<OrderSummary> orders = [];

  @override
  Future<List<OrderSummary>> list({OrderStatus? status}) async => orders
      .where((order) => status == null || order.status == status)
      .toList();

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

    expect(find.byType(Chip), findsOneWidget);
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
    expect(find.byType(Chip), findsNothing);
  });

  group('Statusfilter', () {
    Future<void> pumpWithOneOfEach(WidgetTester tester) async {
      await tester.pumpWidget(OrderApp(repository: FakeOrdersRepository()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Demo-Bestellung anlegen'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Demo-Bestellung anlegen'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Bestellung stornieren').first);
      await tester.pumpAndSettle();
    }

    Future<void> selectFilter(WidgetTester tester, String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(SegmentedButton<OrderStatus?>),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Storniert zeigt nur stornierte Bestellungen', (tester) async {
      await pumpWithOneOfEach(tester);

      await selectFilter(tester, 'Storniert');

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.byType(Chip), findsOneWidget);
      expect(find.byTooltip('Bestellung stornieren'), findsNothing);
    });

    testWidgets('Aktiv zeigt nur aktive Bestellungen', (tester) async {
      await pumpWithOneOfEach(tester);

      await selectFilter(tester, 'Aktiv');

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.byType(Chip), findsNothing);
      expect(find.byTooltip('Bestellung stornieren'), findsOneWidget);
    });

    testWidgets('Alle zeigt beide Bestellungen', (tester) async {
      await pumpWithOneOfEach(tester);
      await selectFilter(tester, 'Aktiv');

      await selectFilter(tester, 'Alle');

      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.byType(Chip), findsOneWidget);
    });
  });
}
