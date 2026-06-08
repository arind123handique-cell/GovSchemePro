import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui_helpers.dart';
import '../../data/models/bill.dart';
import '../../data/models/contractor.dart';
import '../../data/models/scheme.dart';
import '../../data/repositories/scheme_repository.dart';
import '../../providers/repository_providers.dart';
import '../../providers/service_providers.dart';
import '../../services/pdf/pdf_service.dart';

class ReportDef {
  final String title;
  final String description;
  final IconData icon;
  final List<String> headers;
  final Future<List<List<String>>> Function(WidgetRef ref) build;

  const ReportDef({
    required this.title,
    required this.description,
    required this.icon,
    required this.headers,
    required this.build,
  });
}

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  List<ReportDef> _reports() => <ReportDef>[
        ReportDef(
          title: 'Scheme Register',
          description: 'All schemes with tender value, status and progress.',
          icon: Icons.account_tree_outlined,
          headers: const <String>[
            'Scheme ID',
            'Name',
            'Department',
            'FY',
            'Tender Value',
            'Status',
          ],
          build: (WidgetRef ref) async {
            final List<Scheme> list = await ref
                .read(schemeRepositoryProvider)
                .query(const SchemeFilter());
            return list
                .map((Scheme s) => <String>[
                      s.id,
                      s.schemeName,
                      s.department ?? '-',
                      s.financialYear ?? '-',
                      Formatters.quantity(s.tenderValue),
                      s.status,
                    ])
                .toList();
          },
        ),
        ReportDef(
          title: 'Bill Register',
          description: 'All bills across schemes with recoveries.',
          icon: Icons.receipt_long_outlined,
          headers: const <String>[
            'Bill No',
            'Type',
            'Date',
            'Gross',
            'Net',
            'Net Payable',
            'Status',
          ],
          build: (WidgetRef ref) async {
            final List<Bill> list =
                await ref.read(billRepositoryProvider).all();
            return list
                .map((Bill b) => <String>[
                      b.billNumber ?? '-',
                      b.billType ?? '-',
                      Formatters.date(b.billDate),
                      Formatters.quantity(b.grossAmount),
                      Formatters.quantity(b.netAmount),
                      Formatters.quantity(b.netPayable),
                      b.status,
                    ])
                .toList();
          },
        ),
        ReportDef(
          title: 'Contractor Register',
          description: 'Registered contractors with statutory details.',
          icon: Icons.engineering_outlined,
          headers: const <String>[
            'Contractor ID',
            'Name',
            'GST',
            'PAN',
            'Phone',
          ],
          build: (WidgetRef ref) async {
            final List<Contractor> list =
                await ref.read(contractorRepositoryProvider).getAll();
            return list
                .map((Contractor c) => <String>[
                      c.id,
                      c.name,
                      c.gstNumber ?? '-',
                      c.panNumber ?? '-',
                      c.phone ?? '-',
                    ])
                .toList();
          },
        ),
        ReportDef(
          title: 'Department Summary',
          description: 'Scheme count and tender value grouped by department.',
          icon: Icons.apartment_outlined,
          headers: const <String>['Department', 'Schemes', 'Tender Value'],
          build: (WidgetRef ref) async {
            final List<Scheme> list = await ref
                .read(schemeRepositoryProvider)
                .query(const SchemeFilter());
            final Map<String, int> counts = <String, int>{};
            final Map<String, double> values = <String, double>{};
            for (final Scheme s in list) {
              final String dept = s.department ?? 'Unspecified';
              counts[dept] = (counts[dept] ?? 0) + 1;
              values[dept] = (values[dept] ?? 0) + s.tenderValue;
            }
            return counts.keys
                .map((String d) => <String>[
                      d,
                      counts[d].toString(),
                      Formatters.quantity(values[d] ?? 0),
                    ])
                .toList();
          },
        ),
        ReportDef(
          title: 'Pending Bills Report',
          description: 'Bills that are not yet marked paid.',
          icon: Icons.pending_actions_outlined,
          headers: const <String>[
            'Bill No',
            'Type',
            'Date',
            'Net Payable',
            'Status',
          ],
          build: (WidgetRef ref) async {
            final List<Bill> list =
                await ref.read(billRepositoryProvider).all();
            return list
                .where((Bill b) => b.status != 'Paid')
                .map((Bill b) => <String>[
                      b.billNumber ?? '-',
                      b.billType ?? '-',
                      Formatters.date(b.billDate),
                      Formatters.quantity(b.netPayable),
                      b.status,
                    ])
                .toList();
          },
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ReportDef> reports = _reports();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reports')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: reports.length,
        itemBuilder: (BuildContext context, int i) {
          final ReportDef r = reports[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(r.icon, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(r.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                            Text(r.description,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: () => _exportPdf(context, ref, r),
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('PDF'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _exportExcel(context, ref, r),
                        icon: const Icon(Icons.table_view, size: 18),
                        label: const Text('Excel'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _exportCsv(context, ref, r),
                        icon: const Icon(Icons.description_outlined, size: 18),
                        label: const Text('CSV'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportPdf(
      BuildContext context, WidgetRef ref, ReportDef r) async {
    final List<List<String>> rows = await r.build(ref);
    final PdfService pdf = await ref.read(pdfServiceProvider.future);
    final Uint8List bytes = await pdf.tableReport(
      title: r.title,
      headers: r.headers,
      rows: rows,
    );
    await PdfService.preview(bytes, r.title.replaceAll(' ', '_'));
  }

  Future<void> _exportExcel(
      BuildContext context, WidgetRef ref, ReportDef r) async {
    final List<List<String>> rows = await r.build(ref);
    final Uint8List bytes = ref.read(excelServiceProvider).buildSheet(
          name: r.title,
          headers: r.headers,
          rows: rows,
        );
    if (!context.mounted) return;
    await UiHelpers.exportAndNotify(context,
        bytes: bytes,
        filename: '${r.title.replaceAll(' ', '_')}.xlsx',
        mime: Mime.xlsx);
  }

  Future<void> _exportCsv(
      BuildContext context, WidgetRef ref, ReportDef r) async {
    final List<List<String>> rows = await r.build(ref);
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(r.headers.map(_csvCell).join(','));
    for (final List<String> row in rows) {
      buffer.writeln(row.map(_csvCell).join(','));
    }
    final Uint8List bytes =
        Uint8List.fromList(buffer.toString().codeUnits);
    if (!context.mounted) return;
    await UiHelpers.exportAndNotify(context,
        bytes: bytes,
        filename: '${r.title.replaceAll(' ', '_')}.csv',
        mime: Mime.csv);
  }

  String _csvCell(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
