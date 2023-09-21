import 'dart:math';

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

  final String filename = 'counters.db';

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

  Future<UrlEntry> createNewUrlEntry(String url, String username, String password) async {
    Database db = await _db;
    Map<String, Object?> values = <String, Object?>{};
    values["url"] = url;
    values["username"] = username;
    values["password"] = password;
    int cid = await db.insert(UrlEntry.name, values);
    return getUrlEntry(cid);
  }

  Future<List<UrlEntry>> get getUrlEntries async {
    Database db = await _db;
    List<Map<String, Object?>> urlEntryResults = await db.query("urlEntries", where: "DELETED IS NULL", whereArgs: <Object?>[], columns: UrlEntry.columns, distinct: true, limit: 100, orderBy: "sequence ASC, created ASC");
    List<UrlEntry> urlEntries = urlEntryResults.fold<List<UrlEntry>>(List<UrlEntry>.empty(growable: true), (List<UrlEntry> result, Map<String, Object?> each) {
      if (UrlEntry.validRow(each)) {
        result.add(UrlEntry.fromRow(each));
      }
      return result;
    });
    return urlEntries;
  }

  Future<UrlEntry> getUrlEntry(int id) async {
    Database db = await _db;
    List<Map<String, Object?>> urlEntryResult = await db.query("urlEntries", where: "DELETED IS NULL AND id=?", whereArgs: <Object?>[id], columns: UrlEntry.columns, limit: 1, distinct: true);
    if (urlEntryResult.isEmpty) {
      throw ErrorDescription("empty");
    }
    UrlEntry urlEntry = UrlEntry.fromRow(urlEntryResult.first);
    return urlEntry;
  }

  void deleteEntireDatabase() async {
    String fn = await dbFn();
    Database db = await _db;
    await db.close();
    await File(fn).delete();
    _db = getBuildDb();
    await getUrlEntries;
  }

  Future<Database> getBuildDb() async {
    String fullFn = await dbFn();
    return await openDatabase(
      fullFn,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(UrlEntry.createSql);
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

class UrlEntry {
  final int id;
  final String url;
  final String username;
  final String password;
  DateTime created;
  DateTime updated;
  DateTime? deleted;

  static const name = "UrlEntry";
  static const createSql = '''
          CREATE TABLE ${UrlEntry.name}(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
            updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
            deleted TIMESTAMP DEFAULT NULL,
            url STRING,
            username STRING,
            password STRING
          );
      ''';
  static const List<String> columns = <String>["id", "created", "updated", "deleted", "url", "username", "password"];
  static const List<String> required = <String>["id", "url", "username", "password"];

  UrlEntry({required this.id, required this.created, required this.updated, this.deleted, required this.url, required this.username, required this.password});

  UrlEntry.fromRow(Map<String, Object?> each)
      : id = int.parse(each["id"].toString()),
        created = DateTime.tryParse(each["created"].toString()) ?? DateTime.timestamp(),
        updated = DateTime.tryParse(each["updated"].toString()) ?? DateTime.timestamp(),
        deleted = each["deleted"] != null ? DateTime.tryParse(each["deleted"].toString()) : null,
        url = each["url"].toString(),
        username = each["username"].toString(),
        password = each["password"].toString();

  static bool validRow(Map<String, Object?> each) {
    for (String column in required) {
      if (!each.containsKey(column) || each[column] == null) {
        return false;
      }
    }
    return true;
  }

}