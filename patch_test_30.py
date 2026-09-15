import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

search = r'''      // Tap Delete
      await tester\.tap\(find\.text\('Delete'\)\.last\);
      await tester\.pumpAndSettle\(\);'''
replace = r'''      // Tap Delete
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Delete'));
      await tester.pumpAndSettle();'''

content = re.sub(search, replace, content)

with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
