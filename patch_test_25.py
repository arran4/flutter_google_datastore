import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

search = r'''class MockEntityActions extends EntityActions \{
  bool deleteCalled = false;

  @override
  Future<void> deleteEntity\(int index, dsv1\.Entity entity\) async \{
    deleteCalled = true;
  \}

  @override
  Future<dsv1\.Entity\?> refreshEntity\(dsv1\.Key key\) async => null;
  @override
  Future<EntityRow\?> replaceEntity\(int index, dsv1\.Entity newEntity\) async => null;
\}'''

replace = r'''class MockEntityActions extends EntityActions {
  bool deleteCalled = false;

  @override
  Future<bool> deleteEntity(int index, dsv1.Entity entity) async {
    deleteCalled = true;
    return true;
  }

  @override
  Future<dsv1.Entity?> refreshEntity(dsv1.Key key) async => null;
  @override
  Future<EntityRow?> replaceEntity(int index, dsv1.Entity newEntity) async => null;
  @override
  Future<bool> updateEntity(dsv1.Key key, Map<String, dsv1.Value> props) async => true;
}'''

content = re.sub(search, replace, content)

search2 = r'''      final kind = Kind\('TestKind', null\);'''
replace2 = r'''      final kind = Kind(dsv1.Entity(
          key: dsv1.Key(
              path: [dsv1.PathElement(kind: '__kind__', name: 'TestKind')])), null);'''

content = re.sub(search2, replace2, content)

with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
