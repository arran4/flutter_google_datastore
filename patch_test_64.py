import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

# Replace the specific finder logic for tap
search = r'''      // Let's directly invoke popupRowItemSelected\('delete'\) instead of dealing with the popup menus overlapping and causing saveFile ArgumentError
      final viewEntityState = tester\.state<dynamic>\(find\.byType\(ViewEntity\)\.first\);
      viewEntityState\.popupRowItemSelected\('delete'\);
      await tester\.pumpAndSettle\(\);'''
replace = r'''      // Let's directly tap the appbar's PopupMenuButton, ensuring we use the one matching the text 'Delete'.
      // Wait, there's an ArgumentError regarding `saveFile`. That comes from downloading properties.
      // So some other popup menu item is firing!

      // We can open the menu by finding the more_vert icon inside an AppBar.
      await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.more_vert)));
      await tester.pumpAndSettle();

      // Tap Delete
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();'''

content = re.sub(search, replace, content)

with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
