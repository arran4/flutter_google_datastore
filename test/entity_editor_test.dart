import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_google_datastore/entity.dart';
import 'package:flutter_google_datastore/kind.dart';
import 'package:googleapis/datastore/v1.dart' as dsv1;

void main() {
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
                    builder:
                        (context) =>
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
