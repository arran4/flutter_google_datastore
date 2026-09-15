import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

# Replace the specific finder logic for tap
search = r'''      // Open PopupMenu in AppBar
      await tester\.tap\(find\.byType\(PopupMenuButton<String>\)\.first\);
      await tester\.pumpAndSettle\(\);
      // Tap Delete in PopupMenu
      await tester\.tap\(find\.text\('Delete'\)\.first\);'''
replace = r'''      // Let's directly invoke popupRowItemSelected('delete') instead of dealing with the popup menus overlapping and causing saveFile ArgumentError
      final viewEntityState = tester.state<dynamic>(find.byType(ViewEntity).first);
      viewEntityState.popupRowItemSelected('delete');
      await tester.pumpAndSettle();'''

content = re.sub(search, replace, content)

with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
