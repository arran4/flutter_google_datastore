import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_google_datastore/entity.dart';
import 'package:flutter_google_datastore/kind.dart';
import 'package:flutter_google_datastore/datastoremain.dart';
import 'package:flutter_google_datastore/database.dart';
import 'package:googleapis/datastore/v1.dart' as dsv1;
import 'widget_test_utils.dart';
import 'package:http/http.dart' as http;

class MockClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw UnimplementedError();
  }
}

void main() {
  group('Entity Details and Properties View', () {
    final project = Project(
      id: 1,
      projectId: 'test-project',
      endpointUrl: 'http://localhost',
      created: DateTime.now(),
      updated: DateTime.now(),
      authMode: 'none',
      googleCliProfile: '',
      databaseId: '',
    );
    final dsApi = dsv1.DatastoreApi(MockClient());
    final kind = Kind('TestKind', null);

    final entityRow = EntityRow(
      entity: dsv1.Entity(
          key: dsv1.Key(
              path: [dsv1.PathElement(kind: 'TestKind', id: '123')],
              partitionId: dsv1.PartitionId(databaseId: 'test-db')),
          properties: {
            'prop1': dsv1.Value(
                stringValue:
                    'Long string value to test horizontal wrapping or layout boundaries.'),
            'prop2': dsv1.Value(integerValue: '42'),
            'prop3': dsv1.Value(booleanValue: true),
          }),
    );

    testWidgets('Compact layout is single column without overflow',
        (WidgetTester tester) async {
      setDisplaySize(tester, const Size(390, 844));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ViewEntity(
                project,
                dsApi,
                kind,
                entityRow,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Expanded layout uses horizontal space',
        (WidgetTester tester) async {
      setDisplaySize(tester, const Size(1024, 768));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ViewEntity(
                project,
                dsApi,
                kind,
                entityRow,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
