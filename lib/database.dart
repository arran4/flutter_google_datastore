import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class DB {
  static DB? _instance;

  DB._();

  factory DB() => _instance ??= DB._();

  final String filename = 'google-datastore.db';

  late Future<Database> _db = getBuildDb();

  Future<String> dbFn() async {
    final String dbPath;
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      dbPath = '';
    } else if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      dbPath = await getDatabasesPath();
    } else {
      dbPath = await getDatabasesPath();
    }
    String fullFn = p.join(dbPath, filename);
    return fullFn;
  }

  Future<Project> createNewProject(String? endpointUrl, String projectId) async {
    Database db = await _db;
    Map<String, Object?> values = <String, Object?>{};
    if (endpointUrl != null) {
      values["endpointUrl"] = endpointUrl;
    }
    values["projectId"] = projectId;
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

  Future<Project> getProject(int id) async {
    Database db = await _db;
    List<Map<String, Object?>> projectResult = await db.query(Project.name, where: "DELETED IS NULL AND id=?", whereArgs: <Object?>[id], columns: Project.columns, limit: 1, distinct: true);
    if (projectResult.isEmpty) {
      throw ErrorDescription("empty");
    }
    Project project = Project.fromRow(projectResult.first);
    return project;
  }

  void deleteEntireDatabase() async {
    String fn = await dbFn();
    Database db = await _db;
    await db.close();
    await File(fn).delete();
    _db = getBuildDb();
    await getProjects;
  }

  Future<Database> getBuildDb() async {
    String fullFn = await dbFn();
    return await openDatabase(
      fullFn,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(Project.createSql);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        switch (oldVersion) {
          case 0:
          // await db.execute();
        }
      },
    );
  }
}

class Project {
  final int id;
  final String? endpointUrl;
  final String projectId;
  DateTime created;
  DateTime updated;
  DateTime? deleted;

  static const name = "Project";
  static const createSql = '''
          CREATE TABLE ${Project.name}(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
            updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
            deleted TIMESTAMP DEFAULT NULL,
            endpointUrl STRING DEFAULT NULL,
            projectId STRING NOT NULL
          );
      ''';
  static const List<String> columns = <String>["id", "created", "updated", "deleted", "endpointUrl", "projectId"];
  static const List<String> required = <String>["id", "projectId"];

  Project({required this.id, required this.created, required this.updated, this.deleted, required this.endpointUrl, required this.projectId});

  Project.fromRow(Map<String, Object?> each)
      : id = int.parse(each["id"].toString()),
        created = DateTime.tryParse(each["created"].toString()) ?? DateTime.timestamp(),
        updated = DateTime.tryParse(each["updated"].toString()) ?? DateTime.timestamp(),
        deleted = each["deleted"] != null ? DateTime.tryParse(each["deleted"].toString()) : null,
        endpointUrl = each.containsKey("endpointUrl") && each["endpointUrl"] != null ? each["endpointUrl"].toString() : null,
        projectId = each["projectId"].toString();

  static bool validRow(Map<String, Object?> each) {
    for (String column in required) {
      if (!each.containsKey(column) || each[column] == null) {
        return false;
      }
    }
    return true;
  }
}
