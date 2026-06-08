import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/ui_helpers.dart';
import '../../data/models/contractor.dart';
import '../../data/models/scheme.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/service_providers.dart';
import '../../data/repositories/scheme_repository.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_chip.dart';
import 'create_scheme_page.dart';
import 'scheme_workspace_page.dart';

class SchemeRegisterPage extends ConsumerWidget {
  const SchemeRegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Scheme>> schemes = ref.watch(schemeListProvider);
    final SchemeFilter filter = ref.watch(schemeFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: <Widget>[
          _Toolbar(filter: filter),
          Expanded(
            child: schemes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, _) => Center(child: Text('Error: $e')),
              data: (List<Scheme> list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.account_tree_outlined,
                    message: 'No schemes found.\nCreate your first scheme.',
                    action: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const CreateSchemePage()),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Scheme'),
                    ),
                  );
                }
                return Responsive.isMobile(context)
                    ? _SchemeCards(list)
                    : _SchemeTable(list);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends ConsumerWidget {
  final SchemeFilter filter;
  const _Toolbar({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<String>> departments =
        ref.watch(departmentsProvider);
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 260,
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search scheme, village, AA/TS/WO…',
                  isDense: true,
                ),
                onChanged: (String v) => ref
                    .read(schemeFilterProvider.notifier)
                    .state = filter.copyWith(search: v),
              ),
            ),
            _filterDropdown(
              'Status',
              filter.status,
              AppConstants.schemeStatuses,
              (String? v) => ref.read(schemeFilterProvider.notifier).state =
                  v == null
                      ? filter.copyWith(clearStatus: true)
                      : filter.copyWith(status: v),
            ),
            departments.maybeWhen(
              data: (List<String> list) => _filterDropdown(
                'Department',
                filter.department,
                list,
                (String? v) => ref.read(schemeFilterProvider.notifier).state =
                    v == null
                        ? filter.copyWith(clearDepartment: true)
                        : filter.copyWith(department: v),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            FilterChip(
              label: const Text('Archived'),
              selected: filter.includeArchived,
              onSelected: (bool v) => ref
                  .read(schemeFilterProvider.notifier)
                  .state = filter.copyWith(includeArchived: v),
            ),
            const SizedBox(width: 4),
            OutlinedButton.icon(
              onPressed: () => _export(context, ref, pdf: true),
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text('PDF'),
            ),
            OutlinedButton.icon(
              onPressed: () => _export(context, ref, pdf: false),
              icon: const Icon(Icons.table_view, size: 18),
              label: const Text('Excel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const CreateSchemePage()),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterDropdown(String label, String? value, List<String> options,
      ValueChanged<String?> onChanged) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: <DropdownMenuItem<String>>[
          DropdownMenuItem<String>(value: null, child: Text('All $label')),
          ...options.map((String o) =>
              DropdownMenuItem<String>(value: o, child: Text(o))),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref,
      {required bool pdf}) async {
    final List<Scheme> list = await ref.read(schemeRepositoryProvider).query(filter);
    final Map<String, Contractor> contractors =
        await ref.read(contractorMapProvider.future);
    final List<List<String>> rows = list
        .map((Scheme s) => <String>[
              s.id,
              s.schemeName,
              s.department ?? '-',
              s.financialYear ?? '-',
              contractors[s.contractorId]?.name ?? '-',
              Formatters.currency(s.tenderValue),
              s.status,
            ])
        .toList();
    const List<String> headers = <String>[
      'Scheme ID',
      'Name',
      'Department',
      'FY',
      'Contractor',
      'Tender Value',
      'Status'
    ];
    if (!context.mounted) return;
    if (pdf) {
      final pdfService = await ref.read(pdfServiceProvider.future);
      final bytes = await pdfService.tableReport(
        title: 'Scheme Register',
        headers: headers,
        rows: rows,
      );
      if (!context.mounted) return;
      await UiHelpers.exportAndNotify(context,
          bytes: bytes, filename: 'scheme_register.pdf', mime: Mime.pdf);
    } else {
      final bytes = ref.read(excelServiceProvider).buildSheet(
            name: 'Scheme Register',
            headers: headers,
            rows: rows,
          );
      await UiHelpers.exportAndNotify(context,
          bytes: bytes, filename: 'scheme_register.xlsx', mime: Mime.xlsx);
    }
  }
}

class _SchemeTable extends ConsumerWidget {
  final List<Scheme> schemes;
  const _SchemeTable(this.schemes);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Map<String, Contractor>> contractors =
        ref.watch(contractorMapProvider);
    final Map<String, Contractor> map =
        contractors.maybeWhen(data: (Map<String, Contractor> m) => m, orElse: () => <String, Contractor>{});

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minWidth: MediaQuery.sizeOf(context).width - 300),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.secondary),
              columns: const <DataColumn>[
                DataColumn(label: Text('Scheme ID')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Department')),
                DataColumn(label: Text('Contractor')),
                DataColumn(label: Text('Tender Value'), numeric: true),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: schemes.map((Scheme s) {
                return DataRow(cells: <DataCell>[
                  DataCell(Text(s.id)),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Text(s.schemeName, overflow: TextOverflow.ellipsis),
                    ),
                    onTap: () => _open(context, s),
                  ),
                  DataCell(Text(s.department ?? '-')),
                  DataCell(Text(map[s.contractorId]?.name ?? '-')),
                  DataCell(Text(Formatters.currency(s.tenderValue))),
                  DataCell(StatusChip(s.status)),
                  DataCell(_actions(context, ref, s)),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Scheme s) {
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => SchemeWorkspacePage(schemeId: s.id)));
  }

  Widget _actions(BuildContext context, WidgetRef ref, Scheme s) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      onSelected: (String action) =>
          _handleAction(context, ref, s, action),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'view', child: Text('Open Workspace')),
        const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
        const PopupMenuItem<String>(value: 'duplicate', child: Text('Duplicate')),
        PopupMenuItem<String>(
            value: 'archive',
            child: Text(s.archived ? 'Unarchive' : 'Archive')),
        const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, Scheme s, String action) async {
    final SchemeRepository repo = ref.read(schemeRepositoryProvider);
    switch (action) {
      case 'view':
        _open(context, s);
        break;
      case 'edit':
        await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => CreateSchemePage(existing: s)));
        break;
      case 'duplicate':
        await repo.duplicate(s);
        bumpRefresh(ref);
        if (context.mounted) UiHelpers.showSnack(context, 'Scheme duplicated');
        break;
      case 'archive':
        await repo.setArchived(s.id, !s.archived);
        bumpRefresh(ref);
        if (context.mounted) {
          UiHelpers.showSnack(
              context, s.archived ? 'Unarchived' : 'Archived');
        }
        break;
      case 'delete':
        final bool ok = await UiHelpers.confirm(
          context,
          title: 'Delete Scheme',
          message:
              'Delete "${s.schemeName}" and all its BOQ, MB, bills and certificates? This cannot be undone.',
          confirmLabel: 'Delete',
          destructive: true,
        );
        if (ok) {
          await repo.delete(s.id);
          bumpRefresh(ref);
          if (context.mounted) UiHelpers.showSnack(context, 'Scheme deleted');
        }
        break;
    }
  }
}

class _SchemeCards extends ConsumerWidget {
  final List<Scheme> schemes;
  const _SchemeCards(this.schemes);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: schemes.length,
      itemBuilder: (BuildContext context, int i) {
        final Scheme s = schemes[i];
        return Card(
          child: ListTile(
            title: Text(s.schemeName,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 4),
                Text('${s.id}  •  ${s.department ?? '-'}',
                    style: const TextStyle(fontSize: 12)),
                Text(Formatters.currency(s.tenderValue),
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                StatusChip(s.status),
              ],
            ),
            isThreeLine: true,
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => SchemeWorkspacePage(schemeId: s.id))),
          ),
        );
      },
    );
  }
}
