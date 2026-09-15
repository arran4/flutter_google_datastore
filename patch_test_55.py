import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

search = r'''      // Tap Delete
      await tester\.tap\(find\.text\('Delete'\)\.last\);'''
replace = r'''      // Tap Delete
      await tester.tap(find.text('Delete').first);'''

content = re.sub(search, replace, content)

search2 = r'''      // Confirm
      await tester\.tap\(find\.text\('Delete'\)\);'''
replace2 = r'''      // Confirm
      await tester.tap(find.text('Delete').first);'''

content = re.sub(search2, replace2, content)


with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
