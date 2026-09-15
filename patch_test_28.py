import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

search = r'''      // Open PopupMenu
      await tester\.tap\(find\.byType\(PopupMenuButton<String>\)\);'''
replace = r'''      // Open PopupMenu
      await tester.tap(find.byType(PopupMenuButton<String>).first);'''

content = re.sub(search, replace, content)

search2 = r'''      // Open again
      await tester\.tap\(find\.byType\(PopupMenuButton<String>\)\);'''
replace2 = r'''      // Open again
      await tester.tap(find.byType(PopupMenuButton<String>).first);'''

content = re.sub(search2, replace2, content)

with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
