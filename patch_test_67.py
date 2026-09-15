import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

# Replace the popupRowItemSelected logic entirely with direct Delete method from the popup list
# We can find the Delete PopupMenuItem specifically.
search = r'''      // Let's call the `deleteEntity` function directly if possible, or trigger the exact popup menu item by value.
      // Flutter test allows calling the onSelected callback directly:
      final popupMenuFinder = find\.descendant\(of: find\.byType\(AppBar\), matching: find\.byType\(PopupMenuButton<String>\)\);
      final popupMenu = tester\.widget<PopupMenuButton<String>>\(popupMenuFinder\);
      popupMenu\.onSelected\?\.call\('delete'\);
      await tester\.pumpAndSettle\(\);'''
replace = r'''      // Directly test the exact delete popup menu item in the AppBar
      final popupMenuFinder = find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(PopupMenuButton<String>)
      );
      await tester.tap(popupMenuFinder.first);
      await tester.pumpAndSettle();

      // Look for the specific PopupMenuItem that has value 'delete'
      final deleteItem = find.byWidgetPredicate((widget) => widget is PopupMenuItem<String> && widget.value == 'delete');
      await tester.tap(deleteItem);
      await tester.pumpAndSettle();'''

content = re.sub(search, replace, content)

with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
