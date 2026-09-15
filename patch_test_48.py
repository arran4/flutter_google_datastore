import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

search = r'''      // Tap Delete
      await tester\.tap\(find\.text\('Delete'\)\.hitTestable\(\)\);'''
replace = r'''      // Tap Delete
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Delete').last);'''

content = re.sub(search, replace, content)

search2 = r'''      // Confirm
      await tester\.tap\(find\.text\('Delete'\)\.hitTestable\(\)\);'''
replace2 = r'''      // Confirm
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));'''

content = re.sub(search2, replace2, content)

with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
