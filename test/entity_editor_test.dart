import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_google_datastore/entity.dart';
import 'package:flutter_google_datastore/kind.dart';
import 'package:flutter_google_datastore/datastoremain.dart';
import 'package:flutter_google_datastore/database.dart';

import 'widget_test_utils.dart';
import 'package:googleapis/datastore/v1.dart' as dsv1;
import 'package:http/http.dart' as http;

class MockClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw UnimplementedError();
  }
}

void main() {
  group('Entity Details and Properties View', () {
    final project = Project(
      id: 1,
      projectId: 'test-project',
      endpointUrl: 'http://localhost',
      created: DateTime.now(),
      updated: DateTime.now(),
      authMode: 'none',
      googleCliProfile: '',
      databaseId: '',
    );
    final dsApi = dsv1.DatastoreApi(MockClient());
    final kind = Kind('TestKind', null);

    final entityRow = EntityRow(
      entity: dsv1.Entity(
        key: dsv1.Key(
          path: [dsv1.PathElement(kind: 'TestKind', id: '123')],
          partitionId: dsv1.PartitionId(databaseId: 'test-db'),
        ),
        properties: {
          'prop1': dsv1.Value(
            stringValue:
                'Long string value to test horizontal wrapping or layout boundaries.',
          ),
          'prop2': dsv1.Value(integerValue: '42'),
          'prop3': dsv1.Value(booleanValue: true),
        },
      ),
    );

    testWidgets('Compact layout is single column without overflow', (
      WidgetTester tester,
    ) async {
      setDisplaySize(tester, const Size(390, 844));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ViewEntity(project, dsApi, kind, entityRow),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final leftFinder = find.text('Details');
      final rightFinder = find.text('Properties');

      expect(leftFinder, findsOneWidget);
      expect(rightFinder, findsOneWidget);

      final leftRect = tester.getRect(leftFinder);
      final rightRect = tester.getRect(rightFinder);

      expect(leftRect.bottom, lessThan(rightRect.top));
    });

    testWidgets('Expanded layout uses horizontal space', (
      WidgetTester tester,
    ) async {
      setDisplaySize(tester, const Size(1024, 768));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ViewEntity(project, dsApi, kind, entityRow),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final leftFinder = find.text('Details');
      final rightFinder = find.text('Properties');

      expect(leftFinder, findsOneWidget);
      expect(rightFinder, findsOneWidget);

      final leftRect = tester.getRect(leftFinder);
      final rightRect = tester.getRect(rightFinder);

      expect(leftRect.right, lessThan(rightRect.left));
    });
  });

  group('PropertyAddEditDeleteDialog', () {
    testWidgets('Edit "me" value populates text field', (
      WidgetTester tester,
    ) async {
      final entity = dsv1.Entity(
        key: dsv1.Key(
          path: [dsv1.PathElement(kind: 'TestKind', name: 'TestName')],
        ),
      );
      final entityRow = EntityRow(entity: entity);
      final value = dsv1.Value(meaning: 42);

      await tester.pumpWidget(
        MaterialApp(
          home: PropertyAddEditDeleteDialog(
            MapEntry('testProp', value),
            entityRow,
          ),
        ),
      );

      expect(find.text('Meaning (Integer)'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('Save "me" value returns correct Value', (
      WidgetTester tester,
    ) async {
      final entity = dsv1.Entity(
        key: dsv1.Key(
          path: [dsv1.PathElement(kind: 'TestKind', name: 'TestName')],
        ),
      );
      final entityRow = EntityRow(entity: entity);
      MapEntry<String, dsv1.Value?>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showDialog(
                    context: context,
                    builder: (context) =>
                        PropertyAddEditDeleteDialog(null, entityRow),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Select "me" type
      // The dropdown value is initially "string".
      await tester.tap(find.text('string'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('me').last);
      await tester.pumpAndSettle();

      // Verify input field appears
      expect(find.text('Meaning (Integer)'), findsOneWidget);

      // Enter value
      await tester.enterText(
        find.widgetWithText(TextField, 'Meaning (Integer)'),
        '123',
      );

      // Enter name
      await tester.enterText(
        find.widgetWithText(TextField, 'Property Name'),
        'newProp',
      );

      // Click Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.key, 'newProp');
      expect(result!.value!.meaning, 123);
    });
  });
}
