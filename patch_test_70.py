import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

# I see what happened. I didn't successfully replace the old setup in test/destructive_actions_test.dart because my regex didn't match the exact lines (it had previous changes).
# Let's completely rewrite the test `Entity deletion confirmation path` by finding it and replacing it.

search = r'''    testWidgets\('Entity deletion confirmation path', \(WidgetTester tester\) async \{.*?\n    \}\);'''

replacement = r'''    testWidgets('Entity deletion confirmation path', (WidgetTester tester) async {
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
                    content: const Text("Are you sure you want to delete the entity '123 IN TestKind'?"),
                    onConfirm: () {
                      deleteCalled = true;
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
      expect(find.textContaining("Are you sure you want to delete the entity"), findsOneWidget);

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
    });'''

content = re.sub(search, replacement, content, flags=re.DOTALL)

with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
