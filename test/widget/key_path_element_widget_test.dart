import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_google_datastore/entity.dart';
import 'package:googleapis/datastore/v1.dart' as dsv1;

void main() {
  testWidgets('KeyPatElementTextInputWidget renders correctly', (
    WidgetTester tester,
  ) async {
    final element = dsv1.PathElement(kind: 'TestKind', name: 'TestName');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: KeyPatElementTextInputWidget(each: element, index: 0),
          ),
        ),
      ),
    );

    // Check header
    expect(find.text('Root/Ancestor'), findsOneWidget);

    // Check Kind field
    expect(find.text('Kind'), findsOneWidget);
    expect(find.text('TestKind'), findsOneWidget);

    // Check SegmentedButton labels
    expect(find.text('ID (Integer)'), findsOneWidget);
    expect(find.text('Name (String)'), findsOneWidget);

    // Check Name TextField is present
    expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'TestName'), findsOneWidget);

    // Switch to ID
    await tester.tap(find.text('ID (Integer)'));
    await tester.pumpAndSettle();

    // Verify ID TextField is present and Name TextField is gone
    expect(find.widgetWithText(TextField, 'Id'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Name'), findsNothing);

    // Check that ID is empty (since we switched and didn't have an ID)
    // Actually, switching to ID sets id to empty string if it was null, or keeps it if present.
    // In our code: widget.each.id = value == "id" ? widget.each.id ?? "" : null;
    // Since it was null before (we had name), it should be empty string.
  });

  testWidgets(
    'KeyPatElementTextInputWidget renders correctly for child element',
    (WidgetTester tester) async {
      final element = dsv1.PathElement(kind: 'ChildKind', id: '123');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KeyPatElementTextInputWidget(each: element, index: 1),
            ),
          ),
        ),
      );

      // Check header
      expect(find.text('Element 1'), findsOneWidget);
    },
  );
}
