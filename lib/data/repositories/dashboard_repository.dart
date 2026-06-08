import 'package:intl/intl.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../core/database/app_database.dart';
import '../../core/database/schema.dart';
import '../models/dashboard_stats.dart';

class DashboardRepository {
  DashboardRepository(this._db);

  final AppDatabase _db;

  Future<DashboardStats> load() async {
    final Database db = await _db.database;

    final List<Map<String, Object?>> schemeRows = await db.query(
      DbSchema.schemes,
      where: 'archived = 0',
    );

    int total = schemeRows.length;
    int ongoing = 0;
    int completed = 0;
    int delayed = 0;
    double tenderValue = 0;
    final Map<String, int> statusDist = <String, int>{};
    final Map<String, int> deptCount = <String, int>{};

    for (final Map<String, Object?> row in schemeRows) {
      final String status = (row['status'] as String?) ?? 'Planned';
      statusDist[status] = (statusDist[status] ?? 0) + 1;
      if (status == 'Ongoing') ongoing++;
      if (status == 'Completed') completed++;
      if (status == 'Delayed') delayed++;
      tenderValue += (row['tender_value'] as num?)?.toDouble() ?? 0;
      final String dept = (row['department'] as String?)?.trim().isNotEmpty == true
          ? row['department'] as String
          : 'Unspecified';
      deptCount[dept] = (deptCount[dept] ?? 0) + 1;
    }

    final int billCount = ((await db
                .rawQuery('SELECT COUNT(*) AS c FROM ${DbSchema.bills}'))
            .first['c'] as int?) ??
        0;

    final double billedTotal = ((await db.rawQuery(
                'SELECT COALESCE(SUM(net_amount),0) AS s FROM ${DbSchema.bills}'))
            .first['s'] as num)
        .toDouble();

    final double paidTotal = ((await db.rawQuery(
                "SELECT COALESCE(SUM(net_payable),0) AS s FROM ${DbSchema.bills} WHERE status = 'Paid'"))
            .first['s'] as num)
        .toDouble();

    final double boqTotal = ((await db.rawQuery(
                'SELECT COALESCE(SUM(amount),0) AS s FROM ${DbSchema.boqItems}'))
            .first['s'] as num)
        .toDouble();

    // Approximate aggregate physical progress = executed BOQ value / total BOQ.
    final List<Map<String, Object?>> execRows = await db.rawQuery('''
      SELECT b.quantity AS q, b.rate AS r,
             COALESCE((SELECT SUM(m.measured_quantity) FROM ${DbSchema.mbEntries} m
                       WHERE m.boq_item_id = b.id), 0) AS executed
      FROM ${DbSchema.boqItems} b
    ''');
    double executedValue = 0;
    for (final Map<String, Object?> row in execRows) {
      final double q = (row['q'] as num).toDouble();
      final double r = (row['r'] as num).toDouble();
      final double executed = (row['executed'] as num).toDouble();
      final double capped = q > 0 ? (executed > q ? q : executed) : executed;
      executedValue += capped * r;
    }
    final double physicalProgress =
        boqTotal > 0 ? (executedValue / boqTotal * 100).clamp(0, 100) : 0;
    final double financialProgress =
        tenderValue > 0 ? (billedTotal / tenderValue * 100).clamp(0, 100) : 0;

    // Monthly expenditure (last 6 months) from bill dates.
    final Map<String, double> monthly = <String, double>{};
    final DateFormat monthFmt = DateFormat('MMM yy');
    final DateTime now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final DateTime m = DateTime(now.year, now.month - i, 1);
      monthly[monthFmt.format(m)] = 0;
    }
    final List<Map<String, Object?>> billRows = await db.query(
      DbSchema.bills,
      columns: <String>['bill_date', 'net_amount'],
      where: 'bill_date IS NOT NULL',
    );
    for (final Map<String, Object?> row in billRows) {
      final DateTime d =
          DateTime.fromMillisecondsSinceEpoch(row['bill_date'] as int);
      final String key = monthFmt.format(DateTime(d.year, d.month, 1));
      if (monthly.containsKey(key)) {
        monthly[key] = monthly[key]! + ((row['net_amount'] as num?)?.toDouble() ?? 0);
      }
    }

    // Contractor-wise work value (top 6 by tender value).
    final List<Map<String, Object?>> contractorRows = await db.rawQuery('''
      SELECT COALESCE(c.name, 'Unassigned') AS name,
             COALESCE(SUM(s.tender_value), 0) AS value
      FROM ${DbSchema.schemes} s
      LEFT JOIN ${DbSchema.contractors} c ON c.id = s.contractor_id
      WHERE s.archived = 0
      GROUP BY s.contractor_id
      ORDER BY value DESC
      LIMIT 6
    ''');
    final Map<String, double> contractorValue = <String, double>{
      for (final Map<String, Object?> row in contractorRows)
        row['name'] as String: (row['value'] as num).toDouble(),
    };

    return DashboardStats(
      totalSchemes: total,
      ongoingSchemes: ongoing,
      completedSchemes: completed,
      delayedSchemes: delayed,
      totalTenderValue: tenderValue,
      totalBillsGenerated: billCount,
      totalPaidAmount: paidTotal,
      totalBilledAmount: billedTotal,
      physicalProgress: physicalProgress.toDouble(),
      financialProgress: financialProgress.toDouble(),
      statusDistribution: statusDist,
      monthlyExpenditure: monthly,
      contractorWorkValue: contractorValue,
      departmentSchemeCount: deptCount,
    );
  }

  Future<List<Map<String, Object?>>> upcomingCompletions({int limit = 6}) async {
    final Database db = await _db.database;
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    return db.query(
      DbSchema.schemes,
      columns: <String>['id', 'scheme_name', 'target_completion_date', 'status'],
      where:
          "archived = 0 AND target_completion_date IS NOT NULL AND status <> 'Completed' AND target_completion_date >= ?",
      whereArgs: <Object?>[nowMs],
      orderBy: 'target_completion_date ASC',
      limit: limit,
    );
  }
}
