import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

# Replace the specific finder logic for tap
search = r'''      // Tap Delete in the PopupMenu
      await tester\.tap\(find\.byType\(PopupMenuButton<String>\)\.first\);
      await tester\.pumpAndSettle\(\);
      await tester\.tap\(find\.text\('Delete'\)\);'''
replace = r'''      // Wait, there's a different PopupMenuButton on the screen. Let's explicitly look for the one in the main action bar,
      // or we can just invoke the callback directly, but since it's a widget test let's find the correct button.
      // Alternatively, find the key 'delete_entity' which might not exist.
      // The Delete action is added in _ViewEntityState.build:
      // IconButton(icon: const Icon(Icons.delete), onPressed: () => deleteEntity(context))
      // It's likely a direct IconButton!
      await tester.tap(find.byIcon(Icons.delete).first);'''

content = re.sub(search, replace, content)

with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
