import 'package:sqflite_common/sqlite_api.dart';

import '../../core/database/app_database.dart';
import '../../core/database/schema.dart';
import '../models/mb_entry.dart';

class MbRepository {
  MbRepository(this._db);

  final AppDatabase _db;

  Future<List<MbEntry>> forScheme(String schemeId) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      DbSchema.mbEntries,
      where: 'scheme_id = ?',
      whereArgs: <Object?>[schemeId],
      orderBy: 'entry_date DESC, created_at DESC',
    );
    return rows.map(MbEntry.fromMap).toList();
  }

  Future<void> upsert(MbEntry entry) async {
    final Database db = await _db.database;
    await db.insert(
      DbSchema.mbEntries,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final Database db = await _db.database;
    await db.delete(DbSchema.mbEntries, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  /// Cumulative executed quantity per BOQ item id for a scheme.
  Future<Map<String, double>> executedByBoqItem(String schemeId) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT boq_item_id, SUM(measured_quantity) AS executed
      FROM ${DbSchema.mbEntries}
      WHERE scheme_id = ? AND boq_item_id IS NOT NULL
      GROUP BY boq_item_id
    ''', <Object?>[schemeId]);
    return <String, double>{
      for (final Map<String, Object?> row in rows)
        row['boq_item_id'] as String: (row['executed'] as num).toDouble(),
    };
  }
}
