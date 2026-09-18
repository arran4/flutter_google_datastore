import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/datastore/v1.dart' as dsv1;
import 'package:flutter_google_datastore/database.dart';
import 'package:flutter_google_datastore/entity.dart';
import 'package:flutter_google_datastore/datastoremain.dart' as dsm;
import 'package:flutter_google_datastore/kind.dart';
import 'package:http/http.dart' as http;

class MockClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw UnimplementedError();
  }
}

class FakeEntityActions implements EntityActions {
  final Completer<EntityRow?> replaceCompleter = Completer<EntityRow?>();

  @override
  Future<bool> deleteEntity(int index, dsv1.Entity entity) async {
    return true;
  }

  @override
  Future<dsv1.Entity?> refreshEntity(dsv1.Key key) async {
    return dsv1.Entity();
  }

  @override
  Future<EntityRow?> replaceEntity(int index, dsv1.Entity newEntity) async {
    return replaceCompleter.future;
  }

  @override
  Future<bool> updateEntity(dsv1.Key key, Map<String, dsv1.Value> newProperties) async {
    return true;
  }
}

void main() {
  testWidgets('ViewEntityPage lifecycle test - unmounted during save', (WidgetTester tester) async {
    final actions = FakeEntityActions();
    final entityRow = EntityRow(
      entity: dsv1.Entity(
        key: dsv1.Key(
          path: [dsv1.PathElement(kind: 'TestKind', name: 'TestName')],
        ),
      ),
    );

    final project = Project(id: 1, projectId: 'p', endpointUrl: 'http://e', created: DateTime.now(), updated: DateTime.now(), authMode: 'none', googleCliProfile: 'p', databaseId: '');
    final dsApi = dsv1.DatastoreApi(MockClient());
    final kind = dsm.Kind('TestKind', dsm.Namespace('n'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ViewEntityPage(
            project,
            dsApi,
            kind,
            entityRow,
            0,
            actions,
          ),
        ),
      ),
    );

    // Find the save function passed to ViewEntity
    final viewEntityFinder = find.byType(ViewEntity);
    final ViewEntity viewEntity = tester.widget<ViewEntity>(viewEntityFinder);

    viewEntity.saveEntityPropertyUpdates!({});

    await tester.pump();

    await tester.pumpWidget(Container()); // Dispose widget

    actions.replaceCompleter.complete(entityRow); // Complete future
    await tester.pumpAndSettle(); // Resolve remaining microtasks

    expect(tester.takeException(), isNull); // Should not throw error
  });

  testWidgets('ViewEntityPage lifecycle test - unmounted during refresh', (WidgetTester tester) async {
    final actions = FakeEntityActions();
    final entityRow = EntityRow(
      entity: dsv1.Entity(
        key: dsv1.Key(
          path: [dsv1.PathElement(kind: 'TestKind', name: 'TestName')],
        ),
      ),
    );

    final project = Project(id: 1, projectId: 'p', endpointUrl: 'http://e', created: DateTime.now(), updated: DateTime.now(), authMode: 'none', googleCliProfile: 'p', databaseId: '');
    final dsApi = dsv1.DatastoreApi(MockClient());
    final kind = dsm.Kind('TestKind', dsm.Namespace('n'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ViewEntityPage(
            project,
            dsApi,
            kind,
            entityRow,
            0,
            actions,
          ),
        ),
      ),
    );

    // Call popupRowItemSelected('refresh')
    final state = tester.state<State<ViewEntityPage>>(find.byType(ViewEntityPage));
    (state as dynamic).popupRowItemSelected('refresh');

    await tester.pump();

    await tester.pumpWidget(Container()); // Dispose widget

    actions.replaceCompleter.complete(entityRow); // Complete future
    await tester.pumpAndSettle(); // Resolve remaining microtasks

    expect(tester.takeException(), isNull); // Should not throw error
  });
}
