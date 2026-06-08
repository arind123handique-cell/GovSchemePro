import 'package:sqflite_common/sqlite_api.dart';

import '../../core/database/app_database.dart';
import '../../core/database/schema.dart';
import '../models/bill.dart';

class BillRepository {
  BillRepository(this._db);

  final AppDatabase _db;

  Future<List<Bill>> forScheme(String schemeId) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      DbSchema.bills,
      where: 'scheme_id = ?',
      whereArgs: <Object?>[schemeId],
      orderBy: 'bill_date DESC, created_at DESC',
    );
    return rows.map(Bill.fromMap).toList();
  }

  Future<List<Bill>> all({String? search, String? status}) async {
    final Database db = await _db.database;
    final List<String> clauses = <String>[];
    final List<Object?> args = <Object?>[];
    if (search != null && search.isNotEmpty) {
      clauses.add('(bill_number LIKE ? OR bill_type LIKE ?)');
      args.addAll(<Object?>['%$search%', '%$search%']);
    }
    if (status != null) {
      clauses.add('status = ?');
      args.add(status);
    }
    final List<Map<String, Object?>> rows = await db.query(
      DbSchema.bills,
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'bill_date DESC, created_at DESC',
    );
    return rows.map(Bill.fromMap).toList();
  }

  Future<Bill?> getById(String id) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db
        .query(DbSchema.bills, where: 'id = ?', whereArgs: <Object?>[id], limit: 1);
    if (rows.isEmpty) return null;
    return Bill.fromMap(rows.first);
  }

  Future<List<BillItem>> itemsFor(String billId) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      DbSchema.billItems,
      where: 'bill_id = ?',
      whereArgs: <Object?>[billId],
      orderBy: 'sort_order ASC',
    );
    return rows.map(BillItem.fromMap).toList();
  }

  Future<void> save(Bill bill, List<BillItem> items) async {
    final Database db = await _db.database;
    await db.transaction((Transaction txn) async {
      await txn.insert(DbSchema.bills, bill.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete(DbSchema.billItems,
          where: 'bill_id = ?', whereArgs: <Object?>[bill.id]);
      for (final BillItem item in items) {
        await txn.insert(DbSchema.billItems, item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> delete(String id) async {
    final Database db = await _db.database;
    await db.delete(DbSchema.bills, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  /// Sum of net amounts of all prior bills for the scheme (for carry-forward).
  Future<double> previousTotal(String schemeId, {String? excludeBillId}) async {
    final Database db = await _db.database;
    final String exclude =
        excludeBillId != null ? ' AND id <> ?' : '';
    final List<Object?> args = <Object?>[schemeId];
    if (excludeBillId != null) args.add(excludeBillId);
    return ((await db.rawQuery(
                'SELECT COALESCE(SUM(net_amount),0) AS s FROM ${DbSchema.bills} WHERE scheme_id = ?$exclude',
                args))
            .first['s'] as num)
        .toDouble();
  }

  Future<int> countForScheme(String schemeId) async {
    final Database db = await _db.database;
    return ((await db.rawQuery(
                'SELECT COUNT(*) AS c FROM ${DbSchema.bills} WHERE scheme_id = ?',
                <Object?>[schemeId]))
            .first['c'] as int?) ??
        0;
  }
}
