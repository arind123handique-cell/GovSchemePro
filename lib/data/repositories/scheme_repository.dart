import 'package:sqflite_common/sqlite_api.dart';

import '../../core/database/app_database.dart';
import '../../core/database/schema.dart';
import '../../core/utils/id_generator.dart';
import '../models/scheme.dart';
import '../models/scheme_progress.dart';

class SchemeFilter {
  final String? search;
  final String? status;
  final String? department;
  final String? financialYear;
  final bool includeArchived;
  final String orderBy;

  const SchemeFilter({
    this.search,
    this.status,
    this.department,
    this.financialYear,
    this.includeArchived = false,
    this.orderBy = 'created_at DESC',
  });

  SchemeFilter copyWith({
    String? search,
    String? status,
    String? department,
    String? financialYear,
    bool? includeArchived,
    String? orderBy,
    bool clearStatus = false,
    bool clearDepartment = false,
    bool clearYear = false,
  }) {
    return SchemeFilter(
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      department: clearDepartment ? null : (department ?? this.department),
      financialYear: clearYear ? null : (financialYear ?? this.financialYear),
      includeArchived: includeArchived ?? this.includeArchived,
      orderBy: orderBy ?? this.orderBy,
    );
  }
}

class SchemeRepository {
  SchemeRepository(this._db);

  final AppDatabase _db;

  Future<List<Scheme>> query(SchemeFilter filter) async {
    final Database db = await _db.database;
    final List<String> clauses = <String>[];
    final List<Object?> args = <Object?>[];

    if (!filter.includeArchived) {
      clauses.add('archived = 0');
    }
    if (filter.search != null && filter.search!.isNotEmpty) {
      clauses.add(
          '(scheme_name LIKE ? OR id LIKE ? OR village LIKE ? OR district LIKE ? OR aa_number LIKE ? OR ts_number LIKE ? OR work_order_number LIKE ?)');
      final String like = '%${filter.search}%';
      args.addAll(<Object?>[like, like, like, like, like, like, like]);
    }
    if (filter.status != null) {
      clauses.add('status = ?');
      args.add(filter.status);
    }
    if (filter.department != null) {
      clauses.add('department = ?');
      args.add(filter.department);
    }
    if (filter.financialYear != null) {
      clauses.add('financial_year = ?');
      args.add(filter.financialYear);
    }

    final List<Map<String, Object?>> rows = await db.query(
      DbSchema.schemes,
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: filter.orderBy,
    );
    return rows.map(Scheme.fromMap).toList();
  }

  Future<Scheme?> getById(String id) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      DbSchema.schemes,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Scheme.fromMap(rows.first);
  }

  Future<String> nextSchemeId() async {
    final Database db = await _db.database;
    final int count = (await db.rawQuery(
                'SELECT COUNT(*) AS c FROM ${DbSchema.schemes}')
            .then((List<Map<String, Object?>> r) => r.first['c'] as int?)) ??
        0;
    return IdGenerator.schemeId(count + 1);
  }

  Future<void> upsert(Scheme scheme) async {
    final Database db = await _db.database;
    await db.insert(
      DbSchema.schemes,
      scheme.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final Database db = await _db.database;
    await db.delete(DbSchema.schemes, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<void> setArchived(String id, bool archived) async {
    final Database db = await _db.database;
    await db.update(
      DbSchema.schemes,
      <String, Object?>{
        'archived': archived ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Deep-copies a scheme together with its BOQ items.
  Future<Scheme> duplicate(Scheme source) async {
    final Database db = await _db.database;
    final String newId = await nextSchemeId();
    final DateTime now = DateTime.now();
    final Scheme copy = source.copyWith(
      schemeName: '${source.schemeName} (Copy)',
      status: 'Planned',
      updatedAt: now,
    );
    final Map<String, Object?> map = copy.toMap();
    map['id'] = newId;
    map['created_at'] = now.millisecondsSinceEpoch;

    await db.transaction((Transaction txn) async {
      await txn.insert(DbSchema.schemes, map);
      final List<Map<String, Object?>> boq = await txn.query(
        DbSchema.boqItems,
        where: 'scheme_id = ?',
        whereArgs: <Object?>[source.id],
      );
      for (final Map<String, Object?> item in boq) {
        final Map<String, Object?> newItem = Map<String, Object?>.from(item);
        newItem['id'] = IdGenerator.uuid();
        newItem['scheme_id'] = newId;
        await txn.insert(DbSchema.boqItems, newItem);
      }
    });
    return (await getById(newId))!;
  }

  Future<SchemeProgress> progress(Scheme scheme) async {
    final Database db = await _db.database;

    final double boqTotal = ((await db.rawQuery(
                'SELECT COALESCE(SUM(amount),0) AS s FROM ${DbSchema.boqItems} WHERE scheme_id = ?',
                <Object?>[scheme.id]))
            .first['s'] as num)
        .toDouble();

    // Executed value: cap executed qty per BOQ item by its sanctioned quantity.
    final List<Map<String, Object?>> execRows = await db.rawQuery('''
      SELECT b.quantity AS q, b.rate AS r,
             COALESCE((SELECT SUM(m.measured_quantity) FROM ${DbSchema.mbEntries} m
                       WHERE m.boq_item_id = b.id), 0) AS executed
      FROM ${DbSchema.boqItems} b WHERE b.scheme_id = ?
    ''', <Object?>[scheme.id]);
    double executedValue = 0;
    for (final Map<String, Object?> row in execRows) {
      final double q = (row['q'] as num).toDouble();
      final double r = (row['r'] as num).toDouble();
      final double executed = (row['executed'] as num).toDouble();
      final double capped = q > 0 ? (executed > q ? q : executed) : executed;
      executedValue += capped * r;
    }

    final double billedNet = ((await db.rawQuery(
                'SELECT COALESCE(SUM(net_amount),0) AS s FROM ${DbSchema.bills} WHERE scheme_id = ?',
                <Object?>[scheme.id]))
            .first['s'] as num)
        .toDouble();

    final double paid = ((await db.rawQuery(
                "SELECT COALESCE(SUM(net_payable),0) AS s FROM ${DbSchema.bills} WHERE scheme_id = ? AND status = 'Paid'",
                <Object?>[scheme.id]))
            .first['s'] as num)
        .toDouble();

    return SchemeProgress(
      tenderValue: scheme.tenderValue,
      boqTotal: boqTotal,
      executedValue: executedValue,
      billedNet: billedNet,
      paidAmount: paid,
    );
  }

  Future<List<String>> distinctDepartments() async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
        "SELECT DISTINCT department FROM ${DbSchema.schemes} WHERE department IS NOT NULL AND department <> '' ORDER BY department");
    return rows.map((Map<String, Object?> r) => r['department'] as String).toList();
  }
}
