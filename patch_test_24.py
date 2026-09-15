import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

# Replace the direct dialog instantiation with the actual flows. We already wrote this in test 16/17 but it got wiped out. Let's write the three flows.
test_content = r'''import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_google_datastore/ui/confirmation_dialog.dart';
import 'package:flutter_google_datastore/main.dart';
import 'package:flutter_google_datastore/settings.dart';
import 'package:flutter_google_datastore/entity.dart';
import 'package:flutter_google_datastore/database.dart';
import 'package:flutter_google_datastore/kind.dart';
import 'package:googleapis/datastore/v1.dart' as dsv1;
import 'widget_test_utils.dart';
import 'package:http/http.dart' as http;

class MockEntityActions extends EntityActions {
  bool deleteCalled = false;

  @override
  Future<void> deleteEntity(int index, dsv1.Entity entity) async {
    deleteCalled = true;
  }

  @override
  Future<dsv1.Entity?> refreshEntity(dsv1.Key key) async => null;
  @override
  Future<EntityRow?> replaceEntity(int index, dsv1.Entity newEntity) async => null;
}

class MockClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw UnimplementedError();
  }
}

void main() {
  group('Destructive Confirmation Tests', () {
    testWidgets('DestructiveConfirmationDialog shows title, content, and styled button', (WidgetTester tester) async {
      setDisplaySize(tester, const Size(400, 800));

      bool confirmPressed = false;
      bool cancelPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => DestructiveConfirmationDialog(
                      title: 'Delete Data?',
                      content: 'This will delete the selected data.',
                      onCancel: () {
                        cancelPressed = true;
                        Navigator.of(context).pop();
                      },
                      onConfirm: () {
                        confirmPressed = true;
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Data?'), findsOneWidget);
      expect(find.text('This will delete the selected data.'), findsOneWidget);

      final cancelBtn = find.text('Cancel');
      final deleteBtn = find.text('Delete');

      expect(cancelBtn, findsOneWidget);
      expect(deleteBtn, findsOneWidget);

      // Test Cancel
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      expect(cancelPressed, isTrue);
      expect(confirmPressed, isFalse);

      // Reopen and test Confirm
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(confirmPressed, isTrue);
    });

    testWidgets('Entity deletion confirmation path', (WidgetTester tester) async {
      setDisplaySize(tester, const Size(400, 800));

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
            partitionId: dsv1.PartitionId(databaseId: 'test-db')
          ),
          properties: {}
        ),
      );

      final mockActions = MockEntityActions();

      await tester.pumpWidget(
        MaterialApp(
          home: ViewEntityPage(
            project,
            dsApi,
            kind,
            entityRow,
            0,
            mockActions,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open PopupMenu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap Delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Expect dialog
      expect(find.byType(DestructiveConfirmationDialog), findsOneWidget);
      expect(find.text("Are you sure you want to delete the entity '123 IN TestKind'?"), findsOneWidget);

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(mockActions.deleteCalled, isFalse);

      // Open again
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(mockActions.deleteCalled, isTrue);
      // Dialog closed
      expect(find.byType(DestructiveConfirmationDialog), findsNothing);
    });
  });
}
'''
with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(test_content)
