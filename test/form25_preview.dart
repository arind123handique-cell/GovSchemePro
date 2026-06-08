import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:govscheme_pro/data/models/bill.dart';
import 'package:govscheme_pro/data/models/contractor.dart';
import 'package:govscheme_pro/data/models/scheme.dart';
import 'package:govscheme_pro/services/pdf/pdf_service.dart';

/// Generates a sample Form 25 PDF to build/form25_preview.pdf for visual review.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate Form 25 preview', () async {
    final DateTime now = DateTime(2026, 6, 1);
    final Scheme scheme = Scheme(
      id: 'SCH-2026-000006',
      schemeName:
          'Jagannath Community and Skill Centre under Golaghat LAC at Negheriting Tea Estate.',
      division: 'Golaghat (B) Division',
      subDivision: 'Golaghat Sub-Division',
      workOrderNumber: 'SE(B)/JHT/(C/S)S-19/2024-25/1577',
      workOrderDate: DateTime(2025, 2, 11),
      tenderNumber: 'NIT-04/2024-25',
      startDate: DateTime(2025, 2, 14),
      targetCompletionDate: DateTime(2026, 8, 31),
      status: 'Ongoing',
      tenderValue: 9082903,
      createdAt: now,
      updatedAt: now,
    );

    final Contractor contractor = Contractor(
      id: 'C1',
      name: 'Sri Kaustav Saikia',
      address:
          'c/o Moheswar Saikia, Raidongia Gaon, P.O Kamarbondha Ali, P.S, Golaghat, Golaghat, Pin -785625.',
      createdAt: now,
      updatedAt: now,
    );

    final Bill bill = Bill(
      id: 'B1',
      schemeId: scheme.id,
      contractorId: contractor.id,
      billNumber: '2',
      billType: '2nd RA/',
      billDate: now,
      grossAmount: 9082903,
      previousAmount: 6204414,
      netAmount: 2878489,
      netPayable: 2878489,
      createdAt: now,
    );

    final List<BillItem> items = <BillItem>[
      const BillItem(
        id: 'i1',
        billId: 'B1',
        itemNo: '1',
        unit: 'Cum',
        quantity: 338.01,
        rate: 220,
        amount: 74362,
        description:
            'Earth work in excavation by mechanical means (Hydraulic excavator)/ manual means over areas (exceeding 30 cm in depth, 1.5 m in width as well as 10 sqm on plan) including getting out and disposal of excavated earth lead upto 50 m and lift upto 1.5 m, as directed by Engineer-incharge. All kinds of soil',
      ),
      const BillItem(
        id: 'i2',
        billId: 'B1',
        itemNo: '2',
        unit: 'Cum',
        quantity: 326.30,
        rate: 2165,
        amount: 706440,
        description:
            'Supplying and filling in plinth with sand under floors, including watering, ramming, consolidating and dressing complete',
      ),
      const BillItem(
        id: 'i3',
        billId: 'B1',
        itemNo: '3',
        unit: 'Sqm',
        quantity: 126.00,
        rate: 15,
        amount: 1890,
        description:
            'Clearing jungle including uprooting of rank vegetation, grass, brush wood, trees and saplings of girth up to 30 cm measured at a height of 1 m above ground level and removal of rubbish up to a distance of 50 m outside the periphery of the area cleared.',
      ),
      const BillItem(
        id: 'i4',
        billId: 'B1',
        itemNo: '5',
        unit: 'Cum',
        quantity: 22.23,
        rate: 6850,
        amount: 152276,
        description:
            'Providing and laying in position cement concrete of specified grade excluding the cost of centering and shuttering - All work up to plinth level : 1:3:6 (1 Cement : 3 coarse sand (zone-III) derived from natural sources : 6 graded stone aggregate 20 mm nominal size derived from natural sources)',
      ),
    ];

    final PdfService pdf = const PdfService(<String, String>{
      'department_name': 'P.W.D (Building)',
      'officer_name': 'Asst. Executive Engineer',
    });

    final bytes = await pdf.form25(
      scheme: scheme,
      bill: bill,
      items: items,
      contractor: contractor,
    );

    Directory('build').createSync(recursive: true);
    final File out = File('build/form25_preview.pdf');
    out.writeAsBytesSync(bytes);
    expect(out.existsSync(), isTrue);
    // ignore: avoid_print
    print('WROTE ${out.absolute.path} (${bytes.length} bytes)');
  });
}
