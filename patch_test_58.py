import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

# Replace the specific finder logic for tap
search = r'''      // Assuming 'Delete' is inside a popup menu
      await tester\.tap\(find\.byIcon\(Icons\.more_vert\)\.first\);
      await tester\.pumpAndSettle\(\);
      await tester\.tap\(find\.text\('Delete'\)\.first\);'''
replace = r'''      // Wait, there's actually a direct delete icon button for Entity on the page, or it's in the popup menu.
      // Let's look for the actual widget that triggers delete.
      await tester.tap(find.byKey(const Key('entity_delete_button')));'''

content = re.sub(search, replace, content)

with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
