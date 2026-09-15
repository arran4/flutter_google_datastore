import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

search = r'''      // Tap Delete
      await tester\.tap\(find\.text\('Delete'\)\.last\);'''
replace = r'''      // Tap Delete
      await tester.tap(find.text('Delete').hitTestable().last);'''

content = re.sub(search, replace, content)

with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
