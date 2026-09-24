import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_google_datastore/database.dart';
import 'package:flutter_google_datastore/datastoremain.dart';
import 'package:flutter_google_datastore/kind.dart';
import 'package:googleapis/datastore/v1.dart' as dsv1;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class _PendingProjectsResource implements dsv1.ProjectsResource {
  final queryCompleter = Completer<dsv1.RunQueryResponse>();
  int queryCallCount = 0;

  @override
  Future<dsv1.RunQueryResponse> runQuery(
    dsv1.RunQueryRequest request,
    String projectId, {
    String? $fields,
  }) {
    queryCallCount++;
    return queryCompleter.future;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PendingDatastoreApi implements dsv1.DatastoreApi {
  _PendingDatastoreApi(this.projects);

  @override
  final dsv1.ProjectsResource projects;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('kind paging controller is disposed while query is in flight', (
    WidgetTester tester,
  ) async {
    final projects = _PendingProjectsResource();
    final api = _PendingDatastoreApi(projects);
    final project = Project(
      id: 1,
      endpointUrl: 'http://localhost:8081',
      projectId: 'test-project',
      authMode: 'none',
      googleCliProfile: null,
      databaseId: '',
      created: DateTime.utc(2026),
      updated: DateTime.utc(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: KindContentsPage(
          project: project,
          dsApi: api,
          kind: Kind('Task', null),
        ),
      ),
    );
    await tester.pump();
    expect(projects.queryCallCount, 1);
    expect(projects.queryCompleter.isCompleted, isFalse);

    // Capture the actual controller owned by the real production page.
    final controller = tester
        .widget<PagingListener<int, EntityRow>>(
          find.byType(PagingListener<int, EntityRow>),
        )
        .controller;

    // Unmount while the Datastore request is still unresolved.
    await tester.pumpWidget(const SizedBox.shrink());
    expect(() => controller.addListener(() {}), throwsFlutterError);

    // A late response must not update disposed page state or its controller.
    projects.queryCompleter.complete(
      dsv1.RunQueryResponse(
        batch: dsv1.QueryResultBatch(
          entityResults: [],
          endCursor: 'cursor1',
          moreResults: 'NO_MORE_RESULTS',
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
