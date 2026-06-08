import 'package:sqflite_common/sqlite_api.dart';

import '../../core/database/app_database.dart';
import '../../core/database/schema.dart';
import '../models/contractor.dart';

class ContractorRepository {
  ContractorRepository(this._db);

  final AppDatabase _db;

  Future<List<Contractor>> getAll({String? search}) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      DbSchema.contractors,
      where: search != null && search.isNotEmpty
          ? 'name LIKE ? OR gst_number LIKE ? OR phone LIKE ?'
          : null,
      whereArgs: search != null && search.isNotEmpty
          ? <Object?>['%$search%', '%$search%', '%$search%']
          : null,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Contractor.fromMap).toList();
  }

  Future<Contractor?> getById(String id) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      DbSchema.contractors,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Contractor.fromMap(rows.first);
  }

  Future<void> upsert(Contractor contractor) async {
    final Database db = await _db.database;
    await db.insert(
      DbSchema.contractors,
      contractor.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final Database db = await _db.database;
    await db.delete(DbSchema.contractors, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<int> count() async {
    final Database db = await _db.database;
    final Object? value = (await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${DbSchema.contractors}',
    ))
        .first['c'];
    return (value as int?) ?? 0;
  }
}
