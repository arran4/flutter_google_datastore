import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

# Replace the specific finder logic for tap
search = r'''                    content: const Text\("Are you sure you want to delete the entity '123 IN TestKind'\?"\),'''
replace = r'''                    content: "Are you sure you want to delete the entity '123 IN TestKind'?",'''

content = re.sub(search, replace, content)

with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
