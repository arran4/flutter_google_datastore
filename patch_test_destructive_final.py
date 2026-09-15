import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

# Replace the fake dialog test with the actual ViewEntity UI test.
search = r'''  testWidgets\('Entity deletion confirmation path', \(WidgetTester tester\) async \{
    setDisplaySize\(tester, const Size\(400, 800\)\);
    bool deleteCalled = false;

    await tester\.pumpWidget\(MaterialApp\(
      home: Scaffold\(
        body: Builder\(
          builder: \(context\) => ElevatedButton\(
            onPressed: \(\) \{
              showDialog\(
                context: context,
                builder: \(context\) => DestructiveConfirmationDialog\(
                  title: 'Delete entity',
                  content: "Are you sure you want to delete the entity '123 IN TestKind'\?",
                  onConfirm: \(\) \{
                    deleteCalled = true;
                    Navigator\.of\(context\)\.pop\(\);
                  \},
                  onCancel: \(\) \{
                    Navigator\.of\(context\)\.pop\(\);
                  \},
                \),
              \);
            \},
            child: const Text\('Show Dialog'\),
          \),
        \),
      \),
    \)\);

    // Open the dialog
    await tester\.tap\(find\.text\('Show Dialog'\)\);
    await tester\.pumpAndSettle\(\);

    // Check content
    expect\(find\.textContaining\("delete the entity"\), findsOneWidget\);

    // Tap Cancel
    await tester\.tap\(find\.text\('Cancel'\)\);
    await tester\.pumpAndSettle\(\);
    expect\(deleteCalled, isFalse\);

    // Re-open
    await tester\.tap\(find\.text\('Show Dialog'\)\);
    await tester\.pumpAndSettle\(\);

    // Confirm
    await tester\.tap\(find\.text\('Delete'\)\.first\);
    await tester\.pumpAndSettle\(\);
    expect\(deleteCalled, isTrue\);
  \}\);'''

replace = r'''  testWidgets('Entity deletion confirmation path', (WidgetTester tester) async {
    setDisplaySize(tester, const Size(400, 800));

    bool deleteCalled = false;

    final entity = dsv1.Entity()
      ..key = (dsv1.Key()..path = [dsv1.PathElement()..kind = 'TestKind'..id = '123']);
    final project = Project(id: 1, projectName: 'test', projectId: 'test', endpointUrl: 'http://localhost', uuid: '123');
    final entityRow = EntityRow(entity: entity);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ViewEntity(
          project,
          entityRow,
          () async { deleteCalled = true; },
          () async {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Trigger the popup menu's delete action programmatically if it's hard to tap
    // Wait, popupRowItemSelected is private or in the State.
    // Instead of calling the state method, let's just tap the PopupMenuButton and then tap 'Delete'.
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();

    // Check content of the dialog
    expect(find.textContaining("delete the entity"), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(deleteCalled, isFalse);

    // Re-open
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();

    // Confirm
    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();
    expect(deleteCalled, isTrue);
  });'''

content = re.sub(search, replace, content)
content = "import 'package:googleapis/datastore/v1.dart' as dsv1;\nimport 'package:flutter_google_datastore/entity.dart';\nimport 'package:flutter_google_datastore/database.dart';\nimport 'package:flutter_google_datastore/kind.dart';\n" + content

with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
