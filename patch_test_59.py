import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

# Replace the specific finder logic for tap
search = r'''      // Wait, there's actually a direct delete icon button for Entity on the page, or it's in the popup menu.
      // Let's look for the actual widget that triggers delete.
      await tester\.tap\(find\.byKey\(const Key\('entity_delete_button'\)\)\);'''
replace = r'''      // Tap Delete in the PopupMenu
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));'''

content = re.sub(search, replace, content)

with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
