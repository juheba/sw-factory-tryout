import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:order_app/main.dart';
import 'package:order_app/orders/orders_repository.dart';
import 'package:order_app/products/products_repository.dart';

class FakeOrdersRepository implements OrdersRepository {
  FakeOrdersRepository({
    this.failCancel = false,
    this.failCreate = false,
    this.createError,
    this.failList = false,
  });

  final bool failList;
  final bool failCancel;
  final bool failCreate;
  final Exception? createError;
  final List<OrderSummary> orders = [];

  @override
  Future<List<OrderSummary>> list({
    OrderStatus? status,
    OrderSort? sort,
  }) async {
    if (failList) {
      // Wie bei echtem I/O: Der Fehler kommt erst nach dem Aufbau des Frames.
      await Future<void>.delayed(const Duration(milliseconds: 1));
      throw StateError('interner Fehlerdetail-Text');
    }
    final filtered = orders
        .where((order) => status == null || order.status == status)
        .toList();
    // `orders` ist in Anlegereihenfolge (älteste zuerst) gespeichert.
    return sort == OrderSort.newestFirst
        ? filtered.reversed.toList()
        : filtered;
  }

  @override
  Future<OrderSummary> create({
    required String customerId,
    required String sku,
    required int quantity,
  }) async {
    if (createError != null) throw createError!;
    if (failCreate) {
      throw StateError('Unbekannte Artikelnummer: $sku');
    }
    final order = OrderSummary(
      id: 'id-${orders.length + 1}',
      customerId: customerId,
      itemCount: 1,
      status: OrderStatus.created,
      items: [OrderLine(sku: sku, quantity: quantity)],
    );
    orders.add(order);
    return order;
  }

  @override
  Future<OrderSummary> get(String id) async {
    final matches = orders.where((order) => order.id == id);
    if (matches.isEmpty) throw OrderNotFoundException(id);
    return matches.first;
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

class FakeProductsRepository extends ProductsRepository {
  FakeProductsRepository(this.products) : fail = false;

  FakeProductsRepository.failing() : products = const [], fail = true;

  final List<Product> products;
  final bool fail;

  @override
  Future<List<Product>> listAll() async {
    if (fail) throw StateError('Katalog nicht erreichbar');
    return products;
  }

  @override
  Future<Product> fetchProduct(String sku) async {
    if (fail) throw StateError('Katalog nicht erreichbar');
    return products.firstWhere(
      (product) => product.sku == sku,
      orElse: () => throw ProductNotFoundException(sku),
    );
  }
}

Future<void> confirmCancelDialog(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Stornieren'),
    ),
  );
  await tester.pumpAndSettle();
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
    await confirmCancelDialog(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(Chip), findsOneWidget);
    expect(find.byTooltip('Bestellung stornieren'), findsNothing);
  });

  testWidgets('Abbrechen im Dialog lässt die Bestellung aktiv', (tester) async {
    await tester.pumpWidget(OrderApp(repository: FakeOrdersRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Demo-Bestellung anlegen'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bestellung stornieren'));
    await tester.pumpAndSettle();

    expect(find.text('Bestellung stornieren?'), findsOneWidget);

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(Chip), findsNothing);
    expect(find.byTooltip('Bestellung stornieren'), findsOneWidget);
  });

  group('Barrierefreiheit der Bestellliste', () {
    Future<void> pumpWithOrder(WidgetTester tester) async {
      await tester.pumpWidget(OrderApp(repository: FakeOrdersRepository()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Demo-Bestellung anlegen'));
      await tester.pumpAndSettle();
    }

    testWidgets('Tap-Ziele haben Beschriftung', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWithOrder(tester);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('Tap-Ziele sind auf Android groß genug', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWithOrder(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('Tap-Ziele sind auf iOS groß genug', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWithOrder(tester);
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('Text hat genug Kontrast', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWithOrder(tester);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });

  testWidgets('zeigt verständlichen Text und lädt erneut, wenn die Liste '
      'nicht ladbar ist', (tester) async {
    await tester.pumpWidget(
      OrderApp(repository: FakeOrdersRepository(failList: true)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Die Bestellungen konnten nicht geladen werden. '
        'Bitte versuche es erneut.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('interner Fehlerdetail-Text'), findsNothing);
    expect(find.textContaining('StateError'), findsNothing);
    expect(find.text('Erneut laden'), findsOneWidget);

    await tester.tap(find.text('Erneut laden'));
    // Erst den Frame bauen (der FutureBuilder hängt sich an), dann warten.
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Erneut laden'), findsOneWidget);
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
    await confirmCancelDialog(tester);

    expect(find.textContaining('Stornieren fehlgeschlagen'), findsOneWidget);
    expect(find.byType(Chip), findsNothing);
  });

  testWidgets('zeigt Fehlermeldung, wenn Anlegen fehlschlägt', (tester) async {
    final repository = FakeOrdersRepository(failCreate: true);
    await tester.pumpWidget(OrderApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Demo-Bestellung anlegen'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Bestellung anlegen fehlgeschlagen'),
      findsOneWidget,
    );
    expect(find.byType(ListTile), findsNothing);
    expect(find.text('Noch keine Bestellungen.'), findsOneWidget);
  });

  testWidgets('zeigt den detail-Text, wenn der Service ablehnt', (
    tester,
  ) async {
    final repository = FakeOrdersRepository(
      createError: const OrderRejectedException(
        'Unbekannte Artikelnummer: X-1',
      ),
    );
    await tester.pumpWidget(OrderApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Demo-Bestellung anlegen'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Bestellung anlegen fehlgeschlagen: Unbekannte Artikelnummer: X-1',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('{'), findsNothing);
  });

  group('parseProblemDetail', () {
    test('liest detail aus einer Problem-JSON', () {
      expect(
        parseProblemDetail(
          '{"status":400,"detail":"Unbekannte Artikelnummer: X-1"}',
        ),
        'Unbekannte Artikelnummer: X-1',
      );
    });

    test('liefert null ohne JSON, ohne detail oder ohne Text', () {
      expect(parseProblemDetail('kein json'), isNull);
      expect(parseProblemDetail('{"status":400}'), isNull);
      expect(parseProblemDetail('{"detail":42}'), isNull);
      expect(parseProblemDetail('[1]'), isNull);
      expect(parseProblemDetail(null), isNull);
    });
  });

  group('Detailansicht', () {
    testWidgets('zeigt alle Felder der Bestellung', (tester) async {
      await tester.pumpWidget(OrderApp(repository: FakeOrdersRepository()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Demo-Bestellung anlegen'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.text('id-1'), findsOneWidget);
      expect(find.text('demo-customer'), findsOneWidget);
      expect(find.text('BOOK-001'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Aktiv'), findsOneWidget);
    });

    testWidgets('zeigt Fehlermeldung bei 404', (tester) async {
      final repository = FakeOrdersRepository();
      await tester.pumpWidget(OrderApp(repository: repository));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Demo-Bestellung anlegen'));
      await tester.pumpAndSettle();
      repository.orders.clear();

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.textContaining('nicht gefunden'), findsOneWidget);
    });
  });

  group('Produktnamen in der Detailansicht', () {
    Future<void> openDetail(
      WidgetTester tester,
      ProductsRepository products,
    ) async {
      await tester.pumpWidget(
        OrderApp(
          repository: FakeOrdersRepository(),
          productsRepository: products,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Demo-Bestellung anlegen'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
    }

    testWidgets('zeigt den Namen zu einer bekannten sku', (tester) async {
      await openDetail(
        tester,
        FakeProductsRepository([
          const Product(sku: 'BOOK-001', name: 'Roman', priceCents: 1299),
        ]),
      );

      expect(find.text('Roman'), findsOneWidget);
      expect(find.text('BOOK-001'), findsOneWidget);
    });

    testWidgets('fällt bei unbekannter sku auf die Artikelnummer zurück', (
      tester,
    ) async {
      await openDetail(
        tester,
        FakeProductsRepository([
          const Product(sku: 'MUG-001', name: 'Kaffeebecher', priceCents: 899),
        ]),
      );

      expect(find.text('Kaffeebecher'), findsNothing);
      expect(find.text('BOOK-001'), findsOneWidget);
    });

    testWidgets('fällt zurück, wenn der Katalog nicht ladbar ist', (
      tester,
    ) async {
      await openDetail(tester, FakeProductsRepository.failing());

      expect(find.text('BOOK-001'), findsOneWidget);
      expect(find.text('Aktiv'), findsOneWidget);
    });
  });

  group('Produktdetail', () {
    Future<void> openProduct(
      WidgetTester tester,
      ProductsRepository products,
    ) async {
      await tester.pumpWidget(
        OrderApp(
          repository: FakeOrdersRepository(),
          productsRepository: products,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Demo-Bestellung anlegen'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('BOOK-001'));
      await tester.pumpAndSettle();
    }

    testWidgets('zeigt Artikelnummer, Name und Preis', (tester) async {
      await openProduct(
        tester,
        FakeProductsRepository([
          const Product(sku: 'BOOK-001', name: 'Roman', priceCents: 1299),
        ]),
      );

      expect(find.text('Produkt'), findsOneWidget);
      expect(find.text('BOOK-001'), findsOneWidget);
      expect(find.text('Roman'), findsOneWidget);
      expect(find.text('12,99 €'), findsOneWidget);
    });

    testWidgets('zeigt Fehlermeldung bei unbekannter sku', (tester) async {
      await openProduct(
        tester,
        FakeProductsRepository([
          const Product(sku: 'MUG-001', name: 'Kaffeebecher', priceCents: 899),
        ]),
      );

      expect(
        find.text('Das Produkt BOOK-001 wurde nicht gefunden.'),
        findsOneWidget,
      );
      expect(find.text('Kaffeebecher'), findsNothing);
    });

    testWidgets('zeigt Fehlermeldung, wenn der Katalog nicht ladbar ist', (
      tester,
    ) async {
      await openProduct(tester, FakeProductsRepository.failing());

      expect(
        find.textContaining('Das Produkt konnte nicht geladen werden'),
        findsOneWidget,
      );
    });
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
      await confirmCancelDialog(tester);
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

  group('Anzahl im Titel', () {
    testWidgets('leere Liste zeigt 0 Bestellungen und Hinweis', (tester) async {
      await tester.pumpWidget(OrderApp(repository: FakeOrdersRepository()));
      await tester.pumpAndSettle();

      expect(find.text('0 Bestellungen'), findsOneWidget);
      expect(find.text('Noch keine Bestellungen.'), findsOneWidget);
    });

    testWidgets('folgt Statusfilter und Anlegen', (tester) async {
      await tester.pumpWidget(OrderApp(repository: FakeOrdersRepository()));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byTooltip('Demo-Bestellung anlegen'));
        await tester.pumpAndSettle();
      }
      expect(find.text('3 Bestellungen'), findsOneWidget);

      await tester.tap(find.byTooltip('Bestellung stornieren').first);
      await tester.pumpAndSettle();
      await confirmCancelDialog(tester);
      expect(find.text('3 Bestellungen'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(SegmentedButton<OrderStatus?>),
          matching: find.text('Storniert'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 Bestellung'), findsOneWidget);

      await tester.tap(find.text('Aktiv'));
      await tester.pumpAndSettle();
      expect(find.text('2 Bestellungen'), findsOneWidget);
    });
  });

  group('Sortierung', () {
    Future<void> pumpWithThreeOrders(WidgetTester tester) async {
      await tester.pumpWidget(OrderApp(repository: FakeOrdersRepository()));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byTooltip('Demo-Bestellung anlegen'));
        await tester.pumpAndSettle();
      }
    }

    List<String> visibleIds(WidgetTester tester) => tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => (tile.subtitle! as Text).data!)
        .map((text) => text.split(' · ').last)
        .toList();

    Future<void> tapLabel(WidgetTester tester, String label) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    testWidgets('Älteste zuerst ist voreingestellt', (tester) async {
      await pumpWithThreeOrders(tester);

      expect(visibleIds(tester), ['id-1', 'id-2', 'id-3']);
    });

    testWidgets('Neueste zuerst kehrt die Reihenfolge um', (tester) async {
      await pumpWithThreeOrders(tester);

      await tapLabel(tester, 'Neueste zuerst');

      expect(visibleIds(tester), ['id-3', 'id-2', 'id-1']);

      await tapLabel(tester, 'Älteste zuerst');

      expect(visibleIds(tester), ['id-1', 'id-2', 'id-3']);
    });

    testWidgets('Sortierung bleibt beim Filterwechsel erhalten', (
      tester,
    ) async {
      await pumpWithThreeOrders(tester);
      await tester.tap(find.byTooltip('Bestellung stornieren').at(1));
      await tester.pumpAndSettle();
      await confirmCancelDialog(tester);
      await tapLabel(tester, 'Neueste zuerst');

      await tapLabel(tester, 'Aktiv');

      expect(visibleIds(tester), ['id-3', 'id-1']);

      await tapLabel(tester, 'Alle');

      expect(visibleIds(tester), ['id-3', 'id-2', 'id-1']);
    });
  });
}
