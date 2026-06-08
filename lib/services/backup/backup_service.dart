import 'dart:convert';
import 'dart:typed_data';

import 'package:sqflite_common/sqlite_api.dart';

import '../../core/database/app_database.dart';
import '../../core/database/schema.dart';

/// Exports/imports the entire offline database as a portable JSON backup.
class BackupService {
  const BackupService(this._db);

  final AppDatabase _db;

  Future<Uint8List> exportBackup() async {
    final Database db = await _db.database;
    final Map<String, Object?> payload = <String, Object?>{
      'app': 'GovScheme Pro',
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'tables': <String, Object?>{},
    };
    final Map<String, Object?> tables =
        payload['tables'] as Map<String, Object?>;
    for (final String table in DbSchema.tableNames) {
      tables[table] = await db.query(table);
    }
    final String json = const JsonEncoder.withIndent('  ').convert(payload);
    return Uint8List.fromList(utf8.encode(json));
  }

  /// Restores from a backup file, replacing all existing data.
  Future<int> restoreBackup(Uint8List bytes) async {
    final Map<String, Object?> payload =
        jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    final Map<String, Object?> tables =
        (payload['tables'] as Map<String, Object?>?) ?? <String, Object?>{};

    await _db.wipe();
    final Database db = await _db.database;
    int restored = 0;
    await db.transaction((Transaction txn) async {
      for (final String table in DbSchema.tableNames) {
        final List<Object?> records =
            (tables[table] as List<Object?>?) ?? <Object?>[];
        for (final Object? record in records) {
          if (record is Map) {
            await txn.insert(
              table,
              Map<String, Object?>.from(record),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            restored++;
          }
        }
      }
    });
    return restored;
  }
}
