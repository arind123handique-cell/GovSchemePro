import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
// ignore: unnecessary_import
import 'package:sqflite/sqflite.dart'; // provides the default Android/iOS factory
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'schema.dart';

/// Singleton wrapper around the offline-first SQLite database.
///
/// Chooses the correct [databaseFactory] for the running platform so the same
/// data layer works on Android, Windows desktop and the web.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _dbName = 'govscheme_pro.db';
  static const int _dbVersion = 1;

  Database? _db;

  /// Initialises the platform database factory. Call once before [database].
  static void initFactory() {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return;
    }
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    // Android / iOS use the default sqflite factory.
  }

  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final String path = kIsWeb
        ? _dbName
        : p.join(await databaseFactory.getDatabasesPath(), _dbName);

    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onConfigure: (Database db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (Database db, int version) async {
          for (final String statement in DbSchema.createStatements) {
            await db.execute(statement);
          }
        },
      ),
    );
  }

  /// Closes and clears the cached connection (used by restore/import).
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Deletes every row from every table (used before a restore import).
  Future<void> wipe() async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      for (final String table in DbSchema.tableNames.reversed) {
        await txn.delete(table);
      }
    });
  }
}
