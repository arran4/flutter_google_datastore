import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_google_datastore/main.dart';
import 'package:flutter_google_datastore/database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Widget createTestWidget() {
    return MaterialApp(home: const AddEditProjectScreen());
  }

  testWidgets(
    'AddEditProjectScreen renders correctly on narrow screen (mobile)',
    (WidgetTester tester) async {
      // Set a narrow screen size (e.g., iPhone 12 width)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify form elements are present
      expect(find.byType(Form), findsOneWidget);
      expect(find.text('Project ID'), findsOneWidget);
      expect(find.text('Database ID (blank for default)'), findsOneWidget);
      expect(find.text('Endpoint URL (blank for default)'), findsOneWidget);
      expect(find.text('Authentication mode'), findsOneWidget);
      expect(
        find.text('Add Project'),
        findsNWidgets(2),
      ); // AppBar title and button

      // Enter empty project ID and verify validation message
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Project ID'),
        '',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Project'));
      await tester.pumpAndSettle();

      expect(find.text('Project ID cannot be empty'), findsOneWidget);

      // Reset view
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    },
  );

  testWidgets('AddEditProjectScreen renders correctly on wide screen (desktop)', (
    WidgetTester tester,
  ) async {
    // Set a wide screen size (e.g., standard desktop)
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify that the layout constraints are applied without RenderFlex errors
    expect(tester.takeException(), isNull);

    // Verify form elements are present
    expect(find.text('Project ID'), findsOneWidget);
    expect(find.text('Endpoint URL (blank for default)'), findsOneWidget);

    // Enter valid details and test form submission visually (we mock DB operations if needed,
    // but just testing validation here is fine)
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Project ID'),
      'my-project',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Project'));
    await tester.pumpAndSettle();

    expect(find.text('Project ID cannot be empty'), findsNothing);

    // Reset view
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
