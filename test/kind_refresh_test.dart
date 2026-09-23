import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_google_datastore/database.dart';
import 'package:flutter_google_datastore/datastoremain.dart';
import 'package:flutter_google_datastore/kind.dart';
import 'package:googleapis/datastore/v1.dart' as dsv1;

class MockDatastoreApi implements dsv1.DatastoreApi {
  @override
  late final dsv1.ProjectsResource projects = MockProjectsResource();
}

class MockProjectsResource implements dsv1.ProjectsResource {
  Completer<dsv1.LookupResponse>? lookupCompleter;

  @override
  Future<dsv1.LookupResponse> lookup(
    dsv1.LookupRequest request,
    String projectId, {
    String? $fields,
  }) {
    if (lookupCompleter != null) {
      return lookupCompleter!.future;
    }
    return Future.value(
      dsv1.LookupResponse(
        found: [
          dsv1.EntityResult(entity: dsv1.Entity(key: request.keys?.first)),
        ],
      ),
    );
  }

  @override
  Future<dsv1.RunQueryResponse> runQuery(
    dsv1.RunQueryRequest request,
    String projectId, {
    String? $fields,
  }) {
    return Future.value(
      dsv1.RunQueryResponse(
        batch: dsv1.QueryResultBatch(
          entityResults: [
            dsv1.EntityResult(
              entity: dsv1.Entity(
                key: dsv1.Key(
                  path: [dsv1.PathElement(kind: 'Task', name: 'task1')],
                ),
              ),
            ),
          ],
          endCursor: 'cursor1',
          moreResults: 'NO_MORE_RESULTS',
        ),
      ),
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'replaceEntity does not throw when unmounted via popupRowItemSelected',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      final mockApi = MockDatastoreApi();
      final mockProjects = mockApi.projects as MockProjectsResource;
      mockProjects.lookupCompleter = Completer<dsv1.LookupResponse>();

      final project = Project(
        id: 1,
        endpointUrl: 'http://localhost:8081',
        projectId: 'test-project',
        authMode: 'none',
        googleCliProfile: null,
        databaseId: '',
        created: DateTime.now(),
        updated: DateTime.now(),
      );
      final kind = Kind('Task', null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KindContentsPage(
              project: project,
              dsApi: mockApi,
              kind: kind,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The text to find might be 'Task/task1' or something else
      // We can just find the ListTile instead to verify it loaded
      expect(find.byType(ListTile), findsWidgets);

      // Open popup menu for the row and select Refresh
      await tester.tap(find.byType(PopupMenuButton<String>).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Refresh').last);
      await tester.pump();

      // Now, while the refresh (lookup) is pending, remove the widget from the tree
      await tester.pumpWidget(Container());

      // Complete the lookup
      mockProjects.lookupCompleter!.complete(
        dsv1.LookupResponse(
          found: [
            dsv1.EntityResult(
              entity: dsv1.Entity(
                key: dsv1.Key(
                  path: [dsv1.PathElement(kind: 'Task', name: 'task1')],
                ),
              ),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final exception = tester.takeException();
      if (exception != null) {
        throw exception;
      }
    },
  );
}
