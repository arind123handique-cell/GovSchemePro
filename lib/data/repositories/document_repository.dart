import 'package:sqflite_common/sqlite_api.dart';

import '../../core/database/app_database.dart';
import '../../core/database/schema.dart';
import '../models/document.dart';

class DocumentRepository {
  DocumentRepository(this._db);

  final AppDatabase _db;

  Future<List<SchemeDocument>> all({String? schemeId, String? category, String? search}) async {
    final Database db = await _db.database;
    final List<String> clauses = <String>[];
    final List<Object?> args = <Object?>[];
    if (schemeId != null) {
      clauses.add('scheme_id = ?');
      args.add(schemeId);
    }
    if (category != null) {
      clauses.add('category = ?');
      args.add(category);
    }
    if (search != null && search.isNotEmpty) {
      clauses.add('name LIKE ?');
      args.add('%$search%');
    }
    final List<Map<String, Object?>> rows = await db.query(
      DbSchema.documents,
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'uploaded_at DESC',
    );
    return rows.map(SchemeDocument.fromMap).toList();
  }

  Future<void> upsert(SchemeDocument document) async {
    final Database db = await _db.database;
    await db.insert(
      DbSchema.documents,
      document.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final Database db = await _db.database;
    await db.delete(DbSchema.documents, where: 'id = ?', whereArgs: <Object?>[id]);
  }
}
