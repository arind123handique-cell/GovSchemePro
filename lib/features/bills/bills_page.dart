import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:typed_data';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/ui_helpers.dart';
import '../../data/models/bill.dart';
import '../../data/models/scheme.dart';
import '../../data/repositories/scheme_repository.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/service_providers.dart';
import '../../services/excel/excel_service.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_chip.dart';
import '../schemes/scheme_workspace_page.dart';

/// Map of scheme id -> scheme for labelling bills.
final _schemeMapProvider = FutureProvider<Map<String, Scheme>>((ref) async {
  ref.watch(refreshTickProvider);
  final List<Scheme> list =
      await ref.watch(schemeRepositoryProvider).query(const SchemeFilter());
  return <String, Scheme>{for (final Scheme s in list) s.id: s};
});

class BillsPage extends ConsumerWidget {
  const BillsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Bill>> bills = ref.watch(allBillsProvider);
    final Map<String, Scheme> schemes =
        ref.watch(_schemeMapProvider).valueOrNull ?? <String, Scheme>{};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bill Register'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Export Excel',
            icon: const Icon(Icons.table_view),
            onPressed: () => _export(
                context, ref, bills.valueOrNull ?? <Bill>[], schemes),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by bill number or type',
                isDense: true,
              ),
              onChanged: (String v) =>
                  ref.read(billSearchProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: bills.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, _) => Center(child: Text('Error: $e')),
              data: (List<Bill> list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'No bills generated yet.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: list.length,
                  itemBuilder: (BuildContext context, int i) {
                    final Bill b = list[i];
                    final Scheme? s = schemes[b.schemeId];
                    return Card(
                      child: ListTile(
                        title: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                  '${b.billType ?? 'Bill'} • ${b.billNumber ?? b.id.substring(0, 6)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                            StatusChip(b.status),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                              '${s?.schemeName ?? b.schemeId}\n${Formatters.date(b.billDate)}  •  Net Payable ${Formatters.currency(b.netPayable)}'),
                        ),
                        isThreeLine: true,
                        trailing: Responsive.isMobile(context)
                            ? null
                            : Text(Formatters.currency(b.grossAmount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                SchemeWorkspacePage(schemeId: b.schemeId),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref, List<Bill> bills,
      Map<String, Scheme> schemes) async {
    final ExcelService excel = ref.read(excelServiceProvider);
    final List<List<Object?>> rows = bills
        .map((Bill b) => <Object?>[
              b.billNumber ?? '',
              b.billType ?? '',
              schemes[b.schemeId]?.schemeName ?? b.schemeId,
              Formatters.date(b.billDate),
              b.grossAmount,
              b.previousAmount,
              b.netAmount,
              b.netPayable,
              b.status,
            ])
        .toList();
    final Uint8List bytes = excel.buildWorkbook(<ExcelSheetData>[
      ExcelSheetData(
        name: 'Bills',
        headers: const <String>[
          'Bill No',
          'Type',
          'Scheme',
          'Date',
          'Gross',
          'Previous',
          'Net',
          'Net Payable',
          'Status',
        ],
        rows: rows,
      ),
    ]);
    if (!context.mounted) return;
    await UiHelpers.exportAndNotify(context,
        bytes: bytes, filename: 'Bill_Register.xlsx', mime: Mime.xlsx);
  }
}
