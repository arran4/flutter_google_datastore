import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_google_datastore/entity.dart';
import 'package:flutter_google_datastore/kind.dart';
import 'package:googleapis/datastore/v1.dart' as dsv1;
import 'widget_test_utils.dart';

void main() {
  testWidgets(
    'PropertyAddEditDeleteDialog allows editing GeoPoint without overflow',
    (WidgetTester tester) async {
      setDisplaySize(tester, const Size(390, 844));

      final entityRow = EntityRow(
        entity: dsv1.Entity(
          key: dsv1.Key(
            path: [dsv1.PathElement(kind: 'TestKind', id: '123')],
          ),
        ),
      );

      // Helper to launch the dialog and get the result
      dsv1.Value? resultValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (context) =>
                        PropertyAddEditDeleteDialog(null, entityRow),
                  );
                  if (result is MapEntry<String, dsv1.Value?>) {
                    resultValue = result.value;
                  }
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Select 'geoPoint' from dropdown
      await tester.tap(find.text('string'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('geoPoint').last);
      await tester.pumpAndSettle();

      // Find by Key
      final latFinder = find.byKey(const Key('geoPoint_lat'));
      final longFinder = find.byKey(const Key('geoPoint_long'));

      expect(latFinder, findsOneWidget);
      expect(longFinder, findsOneWidget);

      // Enter values
      await tester.enterText(latFinder, '-37.422');
      await tester.enterText(longFinder, '-122.084');

      await tester.enterText(
        find.widgetWithText(TextField, 'Property Name'),
        'myLocation',
      );

      // Assert no overflow
      expect(tester.takeException(), isNull);

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(resultValue, isNotNull);
      expect(resultValue!.geoPointValue, isNotNull);
      expect(resultValue!.geoPointValue!.latitude, -37.422);
      expect(resultValue!.geoPointValue!.longitude, -122.084);
    },
  );
}
