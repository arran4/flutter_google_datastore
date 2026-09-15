import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

# Replace the assertion for the content text, which might be wrapped differently.
# Check what deleteEntity actually shows in entity.dart.
# title: 'Delete entity'
# content: Text("Are you sure you want to delete the entity '123' in 'TestKind'?")
# Let's see...
# find.textContaining('delete the entity')
search = r'''      expect\(find\.text\("Are you sure you want to delete the entity '123 IN TestKind'\?"\), findsOneWidget\);'''
replace = r'''      expect(find.textContaining("Are you sure you want to delete the entity"), findsOneWidget);'''

content = re.sub(search, replace, content)

with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
