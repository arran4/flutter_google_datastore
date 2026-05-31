import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_google_datastore/entity.dart';
import 'package:flutter_google_datastore/kind.dart';
import 'package:googleapis/datastore/v1.dart' as dsv1;

void main() {
  testWidgets('PropertyAddEditDeleteDialog allows editing GeoPoint', (
    WidgetTester tester,
  ) async {
    final entityRow = EntityRow(
      entity: dsv1.Entity(
        key: dsv1.Key(path: [dsv1.PathElement(kind: 'TestKind', id: '123')]),
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
                  builder:
                      (context) => PropertyAddEditDeleteDialog(null, entityRow),
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
    // The dropdown shows 'string' by default.
    await tester.tap(find.text('string'));
    await tester.pumpAndSettle();

    // Find 'geoPoint' in the dropdown menu
    await tester.tap(find.text('geoPoint').last);
    await tester.pumpAndSettle();

    // Verify Latitude and Longitude fields are present
    // These assertions should fail initially
    expect(find.widgetWithText(TextField, 'Latitude'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Longitude'), findsOneWidget);

    // Enter values (using negative values to test signed input support)
    await tester.enterText(
      find.widgetWithText(TextField, 'Latitude'),
      '-37.422',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Longitude'),
      '-122.084',
    );

    // Also set a name for the property
    await tester.enterText(
      find.widgetWithText(TextField, 'Property Name'),
      'myLocation',
    );

    // Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify result
    expect(resultValue, isNotNull);
    expect(resultValue!.geoPointValue, isNotNull);
    expect(resultValue!.geoPointValue!.latitude, -37.422);
    expect(resultValue!.geoPointValue!.longitude, -122.084);
  });
}
