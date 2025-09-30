import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as ppath;
import 'dart:io';

class DB {
  static DB? _instance;

  DB._();

  factory DB() => _instance ??= DB._();

  final String filename = 'google-datastore${kDebugMode ? "-debug" : ""}.db';

  late Future<Database> _db = getBuildDb();

  Future<String> filepath() async {
    final String dbPath;
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      dbPath = '';
    } else if (Platform.isAndroid) {
      dbPath = await getDatabasesPath();
    } else if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      dbPath = (await ppath.getApplicationSupportDirectory()).path;
    } else {
      dbPath = await getDatabasesPath();
    }
    String fullFn = p.join(dbPath, filename);
    return fullFn;
  }

  Future<Project> createNewProject(String? endpointUrl, String projectId, String authMode, String? googleCliProfile) async {
    Database db = await _db;
    Map<String, Object?> values = <String, Object?>{};
    if (endpointUrl != null) {
      values["endpointUrl"] = endpointUrl;
    }
    if (googleCliProfile != null) {
      values["googleCliProfile"] = googleCliProfile;
    }
    values["projectId"] = projectId;
    values["authMode"] = authMode;
    int cid = await db.insert(Project.name, values);
    return getProject(cid);
  }

  Future<List<Project>> get getProjects async {
    Database db = await _db;
    List<Map<String, Object?>> projectResults = await db.query(Project.name, where: "DELETED IS NULL", whereArgs: <Object?>[], columns: Project.columns, distinct: true, limit: 100, orderBy: "created ASC");
    List<Project> projects = projectResults.fold<List<Project>>(List<Project>.empty(growable: true), (List<Project> result, Map<String, Object?> each) {
      if (Project.validRow(each)) {
        result.add(Project.fromRow(each));
      }
      return result;
    });
    return projects;
  }

  Future<Project> getProject(int id, [bool ignoreDeleted = false]) async {
    Database db = await _db;
    List<Map<String, Object?>> projectResult = await db.query(Project.name, where: ignoreDeleted ? "id=?" : "DELETED IS NULL AND id=?", whereArgs: <Object?>[id], columns: Project.columns, limit: 1, distinct: true);
    if (projectResult.isEmpty) {
      throw ErrorDescription("empty");
    }
    Project project = Project.fromRow(projectResult.first);
    return project;
  }

  Future<void> deleteEntireDatabase() async {
    String fn = await filepath();
    Database db = await _db;
    await db.close();
    await File(fn).delete();
    _db = getBuildDb();
    await getProjects;
  }

  Future<Database> getBuildDb() async {
    String fullFn = await filepath();
    return await openDatabase(
      fullFn,
      version: 2,
      onCreate: (Database db, int version) async {
        await db.execute(Project.createSql);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        switch (oldVersion) {
          case 0:
          // await db.execute();
          case 1:
          await db.execute(Project.dbV1toV2);
        }
      },
    );
  }

  Future<Project> deleteProject(int id) async {
    Database db = await _db;
    await db.execute("UPDATE ${Project.name} SET deleted=CURRENT_TIMESTAMP WHERE id=?", <Object?>[id]);
    return getProject(id, true);
  }

  Future<void> removeProject(int id) async {
    Database db = await _db;
    await db.execute("DELETE FROM ${Project.name} WHERE id=?", <Object?>[id]);
    return;
  }

  Future<Project> updateProject(int id, String? endpointUrl, String? projectId, String? authMode, String? googleCliProfile) async {
    Database db = await _db;
    Map<String, Object?> values = <String, Object?>{};
    if (endpointUrl != null) {
      values["endpointUrl"] = endpointUrl;
    }
    if (googleCliProfile != null) {
      values["googleCliProfile"] = googleCliProfile;
    }
    if (projectId != null) {
      values["projectId"] = projectId;
    }
    if (authMode != null) {
      values["authMode"] = authMode;
    }
    await db.update(Project.name, values, where: "id=?", whereArgs: <Object?>[id]);
    return await getProject(id);
  }
}

class Project {
  final int id;
  final String? endpointUrl;
  final String projectId;
  final String authMode;
  final String? googleCliProfile;
  DateTime created;
  DateTime updated;
  DateTime? deleted;

  static const name = "Project";
  static const createSql = '''
          CREATE TABLE ${Project.name} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
            updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
            deleted TIMESTAMP DEFAULT NULL,
            endpointUrl STRING DEFAULT NULL,
            googleCliProfile STRING DEFAULT NULL,
            authMode STRING DEFAULT "none" NOT NULL,
            projectId STRING NOT NULL
          );
      ''';
  static const dbV1toV2 = '''
    ALTER TABLE ${Project.name} ADD COLUMN authMode STRING DEFAULT "none" NOT NULL;
  ''';
  static const dbV2toV3 = '''
    ALTER TABLE ${Project.name} ADD COLUMN googleCliProfile STRING DEFAULT NULL;
  ''';
  static const List<String> columns = <String>["id", "created", "updated", "deleted", "endpointUrl", "projectId", "authMode", "googleCliProfile"];
  static const List<String> required = <String>["id", "projectId"];

  Project({required this.id, required this.created, required this.updated, this.deleted, required this.endpointUrl, required this.projectId, required this.authMode, required this.googleCliProfile});

  Project.fromRow(Map<String, Object?> each)
      : id = int.parse(each["id"].toString()),
        created = DateTime.tryParse(each["created"].toString()) ?? DateTime.timestamp(),
        updated = DateTime.tryParse(each["updated"].toString()) ?? DateTime.timestamp(),
        deleted = each["deleted"] != null ? DateTime.tryParse(each["deleted"].toString()) : null,
        endpointUrl = each.containsKey("endpointUrl") && each["endpointUrl"] != null ? each["endpointUrl"].toString() : null,
        googleCliProfile = each.containsKey("googleCliProfile") && each["googleCliProfile"] != null ? each["googleCliProfile"].toString() : null,
        authMode = each["authMode"].toString() ?? "none",
        projectId = each["projectId"].toString();

  String get key => "$projectId @ ${endpointUrl ?? "default"}";

  String get databaseId => ""; // TODO

  static bool validRow(Map<String, Object?> each) {
    for (String column in required) {
      if (!each.containsKey(column) || each[column] == null) {
        return false;
      }
    }
    return true;
  }
}
