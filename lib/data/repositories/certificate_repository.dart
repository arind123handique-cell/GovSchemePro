import 'package:sqflite_common/sqlite_api.dart';

import '../../core/database/app_database.dart';
import '../../core/database/schema.dart';
import '../models/certificate.dart';

class CertificateRepository {
  CertificateRepository(this._db);

  final AppDatabase _db;

  Future<List<Certificate>> forScheme(String schemeId) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      DbSchema.certificates,
      where: 'scheme_id = ?',
      whereArgs: <Object?>[schemeId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Certificate.fromMap).toList();
  }

  Future<List<Certificate>> all() async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows =
        await db.query(DbSchema.certificates, orderBy: 'created_at DESC');
    return rows.map(Certificate.fromMap).toList();
  }

  Future<void> upsert(Certificate certificate) async {
    final Database db = await _db.database;
    await db.insert(
      DbSchema.certificates,
      certificate.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final Database db = await _db.database;
    await db
        .delete(DbSchema.certificates, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<int> pendingCount() async {
    final Database db = await _db.database;
    // Schemes that are completed but have no completion certificate yet.
    return ((await db.rawQuery('''
      SELECT COUNT(*) AS c FROM ${DbSchema.schemes} s
      WHERE s.status = 'Completed' AND NOT EXISTS (
        SELECT 1 FROM ${DbSchema.certificates} c
        WHERE c.scheme_id = s.id AND c.type LIKE '%Completion%')
    ''')).first['c'] as int?) ??
        0;
  }
}
