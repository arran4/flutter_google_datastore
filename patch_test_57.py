import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

search = r'''      // Tap Delete
      // Assuming 'Delete' is inside a popup menu
      await tester\.tap\(find\.byIcon\(Icons\.more_vert\)\);'''
replace = r'''      // Tap Delete
      // Assuming 'Delete' is inside a popup menu
      await tester.tap(find.byIcon(Icons.more_vert).first);'''

content = re.sub(search, replace, content)

with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
