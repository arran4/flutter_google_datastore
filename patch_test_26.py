import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

search = r'''      final kind = Kind\(dsv1\.Entity\(
          key: dsv1\.Key\(
              path: \[dsv1\.PathElement\(kind: '__kind__', name: 'TestKind'\)\]\)\), null\);'''
replace = r'''      final kind = Kind.fromEntityWithNamespace(dsv1.Entity(
          key: dsv1.Key(
              path: [dsv1.PathElement(kind: '__kind__', name: 'TestKind')])), null);'''

content = re.sub(search, replace, content)

with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
