import 'package:sqflite_common/sqlite_api.dart';

import '../../core/database/app_database.dart';
import '../../core/database/schema.dart';

/// Key/value store backed by SQLite for department, office and officer details.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const String kDepartment = 'department_name';
  static const String kOffice = 'office_name';
  static const String kOfficer = 'officer_name';
  static const String kOfficerDesignation = 'officer_designation';
  static const String kDivision = 'division_name';
  static const String kLogoPath = 'logo_path';
  static const String kSignaturePath = 'signature_path';

  Future<Map<String, String>> all() async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(DbSchema.settings);
    return <String, String>{
      for (final Map<String, Object?> row in rows)
        row['key'] as String: (row['value'] as String?) ?? '',
    };
  }

  Future<String?> get(String key) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      DbSchema.settings,
      where: 'key = ?',
      whereArgs: <Object?>[key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> set(String key, String value) async {
    final Database db = await _db.database;
    await db.insert(
      DbSchema.settings,
      <String, Object?>{'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setAll(Map<String, String> values) async {
    final Database db = await _db.database;
    await db.transaction((Transaction txn) async {
      for (final MapEntry<String, String> entry in values.entries) {
        await txn.insert(
          DbSchema.settings,
          <String, Object?>{'key': entry.key, 'value': entry.value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
