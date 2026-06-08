import 'package:sqflite_common/sqlite_api.dart';

import '../../core/database/app_database.dart';
import '../../core/database/schema.dart';
import '../../core/utils/id_generator.dart';
import '../../data/models/bill.dart';
import '../../data/models/boq_item.dart';
import '../../data/models/certificate.dart';
import '../../data/models/contractor.dart';
import '../../data/models/mb_entry.dart';
import '../../data/models/scheme.dart';

/// Populates demonstration data on first launch so dashboards are meaningful.
class SeedService {
  const SeedService(this._db);

  final AppDatabase _db;

  Future<void> seedIfEmpty() async {
    final Database db = await _db.database;
    final int? schemeCount =
        (await db.rawQuery('SELECT COUNT(*) AS c FROM ${DbSchema.schemes}'))
            .first['c'] as int?;
    if ((schemeCount ?? 0) > 0) return;

    final DateTime now = DateTime.now();

    // Settings
    await db.insert(DbSchema.settings,
        <String, Object?>{'key': 'department_name', 'value': 'Public Works Department (Roads)'});
    await db.insert(DbSchema.settings,
        <String, Object?>{'key': 'office_name', 'value': 'Office of the Executive Engineer, Guwahati Division'});
    await db.insert(DbSchema.settings,
        <String, Object?>{'key': 'officer_name', 'value': 'Er. A. K. Sharma'});
    await db.insert(DbSchema.settings,
        <String, Object?>{'key': 'officer_designation', 'value': 'Executive Engineer'});
    await db.insert(DbSchema.settings,
        <String, Object?>{'key': 'division_name', 'value': 'Guwahati Division'});
    await db.insert(DbSchema.settings,
        <String, Object?>{'key': 'seeded', 'value': 'true'});

    // Contractors
    final List<Contractor> contractors = <Contractor>[
      _contractor('M/s Brahmaputra Constructions', 'GST18ABCDE1234F1Z5', 'Guwahati', now),
      _contractor('M/s Kamrup Infra Pvt Ltd', 'GST18KAMRP5678G2Z3', 'Nagaon', now),
      _contractor('M/s North East Builders', 'GST18NEBLD9012H3Z1', 'Jorhat', now),
    ];
    for (final Contractor c in contractors) {
      await db.insert(DbSchema.contractors, c.toMap());
    }

    final List<String> departments = <String>[
      'Public Works Department (Roads)',
      'Public Health Engineering',
      'Water Resources',
      'Rural Development',
    ];
    final List<String> statuses = <String>[
      'Ongoing',
      'Completed',
      'Delayed',
      'Ongoing',
      'Planned',
      'Completed',
    ];
    final List<String> types = <String>[
      'Road',
      'Building',
      'Water Supply',
      'Drainage',
      'Bridge',
      'Irrigation',
    ];

    for (int i = 0; i < 6; i++) {
      final String schemeId = IdGenerator.schemeId(i + 1);
      final Contractor contractor = contractors[i % contractors.length];
      final double tender = 2500000 + i * 1850000;
      final Scheme scheme = Scheme(
        id: schemeId,
        schemeName: _schemeName(i),
        schemeType: types[i],
        department: departments[i % departments.length],
        division: 'Guwahati Division',
        subDivision: 'Sub-Division ${(i % 3) + 1}',
        financialYear: '2025-26',
        aaNumber: 'AA/2025/${100 + i}',
        aaDate: now.subtract(Duration(days: 200 - i * 10)),
        tsNumber: 'TS/2025/${200 + i}',
        tsDate: now.subtract(Duration(days: 190 - i * 10)),
        workOrderNumber: 'WO/2025/${300 + i}',
        workOrderDate: now.subtract(Duration(days: 180 - i * 10)),
        tenderNumber: 'NIT/2025/${400 + i}',
        contractorId: contractor.id,
        contractorAddress: contractor.address,
        tenderValue: tender,
        estimatedCost: tender * 1.05,
        location: 'Ward ${i + 1}',
        village: <String>['Sonapur', 'Chandrapur', 'Rani', 'Palasbari', 'Hajo', 'Rangia'][i],
        block: 'Block ${(i % 3) + 1}',
        district: 'Kamrup',
        latitude: 26.14 + i * 0.01,
        longitude: 91.73 + i * 0.01,
        startDate: now.subtract(Duration(days: 150 - i * 10)),
        targetCompletionDate: now.add(Duration(days: 60 + i * 20)),
        fundingSource: <String>['State Plan', 'CSS', 'Finance Commission'][i % 3],
        remarks: 'Auto-generated demonstration scheme.',
        status: statuses[i],
        createdAt: now.subtract(Duration(days: 150 - i * 5)),
        updatedAt: now,
      );
      await db.insert(DbSchema.schemes, scheme.toMap());

      // BOQ items
      final List<BoqItem> boq = _boqFor(schemeId, tender);
      for (final BoqItem item in boq) {
        await db.insert(DbSchema.boqItems, item.toMap());
      }

      // Measurement book entries (execute a fraction of each BOQ item)
      final double executionFactor = <double>[0.55, 1.0, 0.35, 0.7, 0.0, 1.0][i];
      for (final BoqItem item in boq) {
        if (executionFactor <= 0) continue;
        await db.insert(
          DbSchema.mbEntries,
          MbEntry(
            id: IdGenerator.uuid(),
            schemeId: schemeId,
            boqItemId: item.id,
            mbNumber: 'MB-${i + 1}',
            pageNumber: '${boq.indexOf(item) + 1}',
            entryDate: now.subtract(Duration(days: 30 - boq.indexOf(item))),
            itemNumber: item.itemNo,
            description: item.description,
            location: scheme.village,
            measuredQuantity: item.quantity * executionFactor,
            unit: item.unit,
            engineer: 'Er. A. K. Sharma',
            createdAt: now,
          ).toMap(),
        );
      }

      // Bills for executed schemes
      if (executionFactor > 0) {
        final double gross = tender * executionFactor;
        final double gst = gross * 0.02;
        final double sd = gross * 0.05;
        final double cess = gross * 0.01;
        final double it = gross * 0.02;
        final double net = gross;
        final double payable = net - gst - sd - cess - it;
        await db.insert(
          DbSchema.bills,
          Bill(
            id: IdGenerator.uuid(),
            schemeId: schemeId,
            contractorId: contractor.id,
            billNumber: '$schemeId/RA-001',
            billType: executionFactor >= 1.0 ? 'Final Bill' : 'RA Bill',
            billDate: now.subtract(Duration(days: 20 - i)),
            grossAmount: gross,
            previousAmount: 0,
            netAmount: net,
            securityDeposit: sd,
            gst: gst,
            labourCess: cess,
            incomeTax: it,
            royalty: 0,
            otherRecoveries: 0,
            netPayable: payable,
            status: executionFactor >= 1.0 ? 'Paid' : 'Submitted',
            createdAt: now,
          ).toMap(),
        );
      }

      // Completion certificate for completed schemes
      if (scheme.status == 'Completed') {
        await db.insert(
          DbSchema.certificates,
          Certificate(
            id: IdGenerator.uuid(),
            schemeId: schemeId,
            type: 'Work Completion Certificate',
            title: 'Work Completion Certificate',
            body:
                'This is to certify that the work "${scheme.schemeName}" under ${scheme.department} has been completed satisfactorily as per the approved estimate and specifications.',
            issuedDate: now,
            officerName: 'Er. A. K. Sharma',
            createdAt: now,
          ).toMap(),
        );
      }

      await db.insert(DbSchema.activities, <String, Object?>{
        'id': IdGenerator.uuid(),
        'scheme_id': schemeId,
        'type': 'Scheme',
        'description': 'Scheme "${scheme.schemeName}" created',
        'created_at': now.subtract(Duration(days: 150 - i * 5)).millisecondsSinceEpoch,
      });
    }
  }

  Contractor _contractor(String name, String gst, String place, DateTime now) {
    return Contractor(
      id: IdGenerator.uuid(),
      name: name,
      address: '$place, Assam',
      gstNumber: gst,
      panNumber: 'ABCDE1234F',
      phone: '94350${(10000 + name.length).toString().substring(0, 5)}',
      email: '${name.split(' ').last.toLowerCase()}@example.com',
      bankAccount: '5012${name.length}00112233',
      ifsc: 'SBIN0001234',
      createdAt: now,
      updatedAt: now,
    );
  }

  String _schemeName(int i) => <String>[
        'Construction of RCC Road from Sonapur to Panbari',
        'Construction of Primary Health Sub-Centre at Chandrapur',
        'Augmentation of Piped Water Supply Scheme, Rani',
        'Construction of RCC Drain at Palasbari Market',
        'Construction of RCC Bridge over Kalajan at Hajo',
        'Minor Irrigation Canal Lining Work at Rangia',
      ][i];

  List<BoqItem> _boqFor(String schemeId, double tender) {
    final List<List<Object>> defs = <List<Object>>[
      <Object>['1', 'Earth work in excavation in foundation', 'Cum', 0.10],
      <Object>['2', 'Providing and laying PCC 1:4:8', 'Cum', 0.18],
      <Object>['3', 'Providing and laying RCC M20', 'Cum', 0.32],
      <Object>['4', 'Reinforcement Fe500 TMT bars', 'MT', 0.20],
      <Object>['5', 'Brick work in cement mortar 1:6', 'Cum', 0.12],
      <Object>['6', 'Plastering 12mm thick 1:6', 'Sqm', 0.08],
    ];
    final List<BoqItem> items = <BoqItem>[];
    for (int i = 0; i < defs.length; i++) {
      final double amount = tender * (defs[i][3] as double);
      final double rate = <double>[450, 4800, 7200, 68000, 5600, 280][i];
      final double quantity = amount / rate;
      items.add(BoqItem(
        id: IdGenerator.uuid(),
        schemeId: schemeId,
        itemNo: defs[i][0] as String,
        description: defs[i][1] as String,
        unit: defs[i][2] as String,
        quantity: double.parse(quantity.toStringAsFixed(2)),
        rate: rate,
        amount: double.parse(amount.toStringAsFixed(2)),
        category: 'Civil',
        sortOrder: i,
      ));
    }
    return items;
  }
}
