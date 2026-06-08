import 'package:sqflite_common/sqlite_api.dart';

import '../../core/database/app_database.dart';
import '../../core/database/schema.dart';
import '../../core/utils/id_generator.dart';
import '../models/activity.dart';

class ActivityRepository {
  ActivityRepository(this._db);

  final AppDatabase _db;

  Future<void> log(String type, String description, {String? schemeId}) async {
    final Database db = await _db.database;
    final Activity activity = Activity(
      id: IdGenerator.uuid(),
      schemeId: schemeId,
      type: type,
      description: description,
      createdAt: DateTime.now(),
    );
    await db.insert(DbSchema.activities, activity.toMap());
  }

  Future<List<Activity>> recent({int limit = 12, String? schemeId}) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      DbSchema.activities,
      where: schemeId != null ? 'scheme_id = ?' : null,
      whereArgs: schemeId != null ? <Object?>[schemeId] : null,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(Activity.fromMap).toList();
  }
}
