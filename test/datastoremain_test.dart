import 'dart:io';

import 'package:flutter_google_datastore/datastoremain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // sqfliteFfiInit is needed for the test setup itself (to create the DB)
  // and potentially for the code under test if it wasn't already initialized,
  // but the code under test calls it too.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('GCloudCLICredentialDiscover', () {
    test('can discover credentials in custom directory', () async {
      final tempDir = await Directory.systemTemp.createTemp('gcloud_test_');
      addTearDown(() => tempDir.delete(recursive: true));

      final configDir = path.join(tempDir.path, 'gcloud');
      await Directory(
        path.join(configDir, 'configurations'),
      ).create(recursive: true);

      // Create config_default
      final configFile = File(
        path.join(configDir, 'configurations', 'config_default'),
      );
      await configFile.writeAsString('''
[core]
account = test_account
''');

      // Create credentials.db
      final dbPath = path.join(configDir, 'credentials.db');
      final db = await databaseFactoryFfi.openDatabase(dbPath);
      await db.execute(
        'CREATE TABLE credentials (account_id TEXT PRIMARY KEY, value TEXT)',
      );
      await db.insert('credentials', {
        'account_id': 'test_account',
        'value': '{"client_id": "foo"}',
      });
      await db.close();

      final discover = GCloudCLICredentialDiscover(
        overrideConfigDir: configDir,
      );
      await discover.initFuture;

      final creds = await discover.getJsonCredentials('default');
      expect(creds, '{"client_id": "foo"}');
    });

    test(
        'immediate credential use waits for initialization without LateInitializationError',
        () async {
      final tempDir =
          await Directory.systemTemp.createTemp('gcloud_test_immediate_');
      addTearDown(() => tempDir.delete(recursive: true));

      final configDir = path.join(tempDir.path, 'gcloud');
      await Directory(path.join(configDir, 'configurations'))
          .create(recursive: true);

      // Create config_default
      final configFile =
          File(path.join(configDir, 'configurations', 'config_default'));
      await configFile.writeAsString('''
[core]
account = test_account
''');

      // Create credentials.db
      final dbPath = path.join(configDir, 'credentials.db');
      final db = await databaseFactoryFfi.openDatabase(dbPath);
      await db.execute(
          'CREATE TABLE credentials (account_id TEXT PRIMARY KEY, value TEXT)');
      await db.insert('credentials', {
        'account_id': 'test_account',
        'value': '{"client_id": "bar"}',
      });
      await db.close();

      // We do not await initFuture here to simulate immediate usage
      final discover =
          GCloudCLICredentialDiscover(overrideConfigDir: configDir);
      final creds = await discover.getJsonCredentials('default');

      expect(creds, '{"client_id": "bar"}');
    });

    test(
        'empty configurations directory falls back to default profile successfully',
        () async {
      final tempDir =
          await Directory.systemTemp.createTemp('gcloud_test_empty_');
      addTearDown(() => tempDir.delete(recursive: true));

      final configDir = path.join(tempDir.path, 'gcloud');

      // Create configurations directory but DO NOT create any config_ files
      await Directory(path.join(configDir, 'configurations'))
          .create(recursive: true);

      final discover =
          GCloudCLICredentialDiscover(overrideConfigDir: configDir);
      final result = await discover.initFuture;

      expect(result.profiles, ['default']);
      expect(result.isFallbackDefault, true);
    });

    test(
        'missing configurations directory falls back to default profile and is handled gracefully',
        () async {
      final tempDir =
          await Directory.systemTemp.createTemp('gcloud_test_missing_');
      addTearDown(() => tempDir.delete(recursive: true));

      final configDir = path.join(tempDir.path, 'gcloud');

      // DO NOT create configurations directory
      // await Directory(path.join(configDir, 'configurations')).create(recursive: true);

      final discover =
          GCloudCLICredentialDiscover(overrideConfigDir: configDir);

      try {
        await discover.initFuture;
        fail('Expected an exception for missing directory');
      } catch (e) {
        expect(e.toString(), contains('Failed to load profiles'));
      }
    });
  });
}
