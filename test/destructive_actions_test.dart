import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_google_datastore/ui/confirmation_dialog.dart';
import 'widget_test_utils.dart';

void main() {
  testWidgets(
      'DestructiveConfirmationDialog shows title, content, and styled button',
      (WidgetTester tester) async {
    setDisplaySize(tester, const Size(400, 800));

    bool confirmPressed = false;
    bool cancelPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => DestructiveConfirmationDialog(
                    title: 'Delete Data?',
                    content: 'This will delete the selected data.',
                    onCancel: () {
                      cancelPressed = true;
                      Navigator.of(context).pop();
                    },
                    onConfirm: () {
                      confirmPressed = true;
                      Navigator.of(context).pop();
                    },
                  ),
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

    expect(find.text('Delete Data?'), findsOneWidget);
    expect(find.text('This will delete the selected data.'), findsOneWidget);

    final cancelBtn = find.text('Cancel');
    final deleteBtn = find.text('Delete');

    expect(cancelBtn, findsOneWidget);
    expect(deleteBtn, findsOneWidget);

    // Test Cancel
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();

    expect(cancelPressed, isTrue);
    expect(confirmPressed, isFalse);

    // Reopen and test Confirm
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(confirmPressed, isTrue);
  });

  testWidgets('Entity deletion confirmation path', (WidgetTester tester) async {
    setDisplaySize(tester, const Size(400, 800));
    bool deleteCalled = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => DestructiveConfirmationDialog(
                  title: 'Delete entity',
                  content: "Are you sure you want to delete the entity '123' in 'TestKind'?",
                  onConfirm: () {
                    deleteCalled = true;
                    Navigator.of(context).pop();
                  },
                  onCancel: () {
                    Navigator.of(context).pop();
                  },
                ),
              );
            },
            child: const Text('Show Dialog'),
          ),
        ),
      ),
    ));

    // Open the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Check content
    expect(find.textContaining("delete the entity"), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(deleteCalled, isFalse);

    // Re-open
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Confirm
    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();
    expect(deleteCalled, isTrue);
  });
}
