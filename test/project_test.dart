import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_google_datastore/database.dart';

void main() {
  group('Project model', () {
    test('validRow returns true when required fields present', () {
      final row = {
        'id': 1,
        'projectId': 'proj',
      };
      expect(Project.validRow(row), isTrue);
    });

    test('validRow returns false when required fields missing', () {
      final row = {
        'id': 1,
      };
      expect(Project.validRow(row), isFalse);
    });

    test('fromRow maps values correctly', () {
      final now = DateTime.now().toUtc();
      final row = {
        'id': 10,
        'created': now.toIso8601String(),
        'updated': now.toIso8601String(),
        'endpointUrl': 'http://localhost',
        'projectId': 'myproj',
        'authMode': 'none',
        'googleCliProfile': 'default',
      };

      final project = Project.fromRow(row);
      expect(project.id, 10);
      expect(project.endpointUrl, 'http://localhost');
      expect(project.projectId, 'myproj');
      expect(project.authMode, 'none');
      expect(project.googleCliProfile, 'default');
      expect(project.key, 'myproj @ http://localhost');
    });
  });
}
