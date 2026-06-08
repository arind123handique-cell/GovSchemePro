import 'package:sqflite_common/sqlite_api.dart';

import '../../core/database/app_database.dart';
import '../../core/database/schema.dart';
import '../models/photo.dart';

class PhotoRepository {
  PhotoRepository(this._db);

  final AppDatabase _db;

  Future<List<SchemePhoto>> forScheme(String schemeId, {String? stage}) async {
    final Database db = await _db.database;
    final List<String> clauses = <String>['scheme_id = ?'];
    final List<Object?> args = <Object?>[schemeId];
    if (stage != null) {
      clauses.add('stage = ?');
      args.add(stage);
    }
    final List<Map<String, Object?>> rows = await db.query(
      DbSchema.photos,
      where: clauses.join(' AND '),
      whereArgs: args,
      orderBy: 'taken_at DESC',
    );
    return rows.map(SchemePhoto.fromMap).toList();
  }

  Future<void> upsert(SchemePhoto photo) async {
    final Database db = await _db.database;
    await db.insert(
      DbSchema.photos,
      photo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final Database db = await _db.database;
    await db.delete(DbSchema.photos, where: 'id = ?', whereArgs: <Object?>[id]);
  }
}
