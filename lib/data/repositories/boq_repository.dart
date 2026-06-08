import 'package:sqflite_common/sqlite_api.dart';

import '../../core/database/app_database.dart';
import '../../core/database/schema.dart';
import '../models/boq_item.dart';

class BoqRepository {
  BoqRepository(this._db);

  final AppDatabase _db;

  Future<List<BoqItem>> forScheme(String schemeId) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      DbSchema.boqItems,
      where: 'scheme_id = ?',
      whereArgs: <Object?>[schemeId],
      orderBy: 'sort_order ASC, item_no ASC',
    );
    return rows.map(BoqItem.fromMap).toList();
  }

  Future<void> upsert(BoqItem item) async {
    final Database db = await _db.database;
    await db.insert(
      DbSchema.boqItems,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertMany(List<BoqItem> items) async {
    final Database db = await _db.database;
    await db.transaction((Transaction txn) async {
      for (final BoqItem item in items) {
        await txn.insert(
          DbSchema.boqItems,
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> delete(String id) async {
    final Database db = await _db.database;
    await db.delete(DbSchema.boqItems, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<void> deleteForScheme(String schemeId) async {
    final Database db = await _db.database;
    await db.delete(DbSchema.boqItems,
        where: 'scheme_id = ?', whereArgs: <Object?>[schemeId]);
  }

  Future<double> total(String schemeId) async {
    final Database db = await _db.database;
    return ((await db.rawQuery(
                'SELECT COALESCE(SUM(amount),0) AS s FROM ${DbSchema.boqItems} WHERE scheme_id = ?',
                <Object?>[schemeId]))
            .first['s'] as num)
        .toDouble();
  }
}
