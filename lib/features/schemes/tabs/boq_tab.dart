import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../data/models/boq_item.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../services/import/boq_import_service.dart';
import '../../../widgets/section_card.dart';

class BoqTab extends ConsumerWidget {
  final String schemeId;
  const BoqTab({super.key, required this.schemeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BoqItem>> boq = ref.watch(boqListProvider(schemeId));

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editItem(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: boq.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text('Error: $e')),
        data: (List<BoqItem> items) {
          final double total =
              items.fold(0, (double s, BoqItem i) => s + i.amount);
          return Column(
            children: <Widget>[
              _toolbar(context, ref, items, total),
              Expanded(
                child: items.isEmpty
                    ? EmptyState(
                        icon: Icons.list_alt,
                        message: 'No BOQ items.\nAdd manually or import a file.',
                        action: FilledButton.icon(
                          onPressed: () => _import(context, ref),
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Import BOQ'),
                        ),
                      )
                    : _table(context, ref, items),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _toolbar(BuildContext context, WidgetRef ref, List<BoqItem> items,
      double total) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('${items.length} items',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('BOQ Total: ${Formatters.currency(total)}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _import(context, ref),
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Import'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: items.isEmpty
                  ? null
                  : () => _export(context, ref, items),
              icon: const Icon(Icons.table_view, size: 18),
              label: const Text('Excel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _table(BuildContext context, WidgetRef ref, List<BoqItem> items) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
      child: Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minWidth: MediaQuery.sizeOf(context).width - 300),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.secondary),
              columns: const <DataColumn>[
                DataColumn(label: Text('Item')),
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('Unit')),
                DataColumn(label: Text('Qty'), numeric: true),
                DataColumn(label: Text('Rate'), numeric: true),
                DataColumn(label: Text('Amount'), numeric: true),
                DataColumn(label: Text('')),
              ],
              rows: items.map((BoqItem item) {
                return DataRow(cells: <DataCell>[
                  DataCell(Text(item.itemNo ?? '-')),
                  DataCell(ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Text(item.description,
                        overflow: TextOverflow.ellipsis),
                  )),
                  DataCell(Text(item.unit ?? '-')),
                  DataCell(Text(Formatters.quantity(item.quantity))),
                  DataCell(Text(Formatters.quantity(item.rate))),
                  DataCell(Text(Formatters.currency(item.amount))),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        onPressed: () => _editItem(context, ref, item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16),
                        onPressed: () async {
                          await ref
                              .read(boqRepositoryProvider)
                              .delete(item.id);
                          bumpRefresh(ref);
                        },
                      ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final BoqImportService service = ref.read(boqImportServiceProvider);
    final BoqImportResult? result = await service.pickAndParse();
    if (result == null) {
      if (context.mounted) UiHelpers.showSnack(context, 'Import cancelled');
      return;
    }
    if (result.rows.isEmpty) {
      if (context.mounted) {
        UiHelpers.showSnack(context,
            'No rows detected in ${result.fileName}. Check column headers.',
            error: true);
      }
      return;
    }
    if (!context.mounted) return;
    final bool ok = await UiHelpers.confirm(
      context,
      title: 'Import BOQ',
      message:
          'Detected ${result.rows.length} items from ${result.fileName} (${result.format}). Import them?',
      confirmLabel: 'Import',
    );
    if (!ok) return;
    final List<BoqItem> items = <BoqItem>[];
    for (int i = 0; i < result.rows.length; i++) {
      final ParsedBoqRow r = result.rows[i];
      items.add(BoqItem(
        id: IdGenerator.uuid(),
        schemeId: schemeId,
        itemNo: r.itemNo ?? '${i + 1}',
        description: r.description,
        unit: r.unit,
        quantity: r.quantity,
        rate: r.rate,
        amount: r.amount,
        sortOrder: i,
      ));
    }
    await ref.read(boqRepositoryProvider).upsertMany(items);
    await ref.read(activityRepositoryProvider).log(
        'BOQ', 'Imported ${items.length} BOQ items', schemeId: schemeId);
    bumpRefresh(ref);
    if (context.mounted) {
      UiHelpers.showSnack(context, 'Imported ${items.length} items');
    }
  }

  Future<void> _export(
      BuildContext context, WidgetRef ref, List<BoqItem> items) async {
    final List<List<Object?>> rows = items
        .map((BoqItem i) => <Object?>[
              i.itemNo,
              i.description,
              i.unit,
              i.quantity,
              i.rate,
              i.amount,
            ])
        .toList();
    final bytes = ref.read(excelServiceProvider).buildSheet(
      name: 'BOQ',
      headers: const <String>[
        'Item',
        'Description',
        'Unit',
        'Quantity',
        'Rate',
        'Amount'
      ],
      rows: rows,
    );
    await UiHelpers.exportAndNotify(context,
        bytes: bytes, filename: '${schemeId}_boq.xlsx', mime: Mime.xlsx);
  }

  Future<void> _editItem(
      BuildContext context, WidgetRef ref, BoqItem? existing) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _BoqItemDialog(schemeId: schemeId, existing: existing),
    );
  }
}

class _BoqItemDialog extends ConsumerStatefulWidget {
  final String schemeId;
  final BoqItem? existing;
  const _BoqItemDialog({required this.schemeId, this.existing});

  @override
  ConsumerState<_BoqItemDialog> createState() => _BoqItemDialogState();
}

class _BoqItemDialogState extends ConsumerState<_BoqItemDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;

  @override
  void initState() {
    super.initState();
    final BoqItem? e = widget.existing;
    _c = <String, TextEditingController>{
      'itemNo': TextEditingController(text: e?.itemNo ?? ''),
      'description': TextEditingController(text: e?.description ?? ''),
      'unit': TextEditingController(text: e?.unit ?? ''),
      'quantity': TextEditingController(text: e?.quantity.toString() ?? ''),
      'rate': TextEditingController(text: e?.rate.toString() ?? ''),
      'category': TextEditingController(text: e?.category ?? ''),
    };
  }

  @override
  void dispose() {
    for (final TextEditingController c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final double qty = double.tryParse(_c['quantity']!.text.trim()) ?? 0;
    final double rate = double.tryParse(_c['rate']!.text.trim()) ?? 0;
    final BoqItem item = BoqItem(
      id: widget.existing?.id ?? IdGenerator.uuid(),
      schemeId: widget.schemeId,
      itemNo: _c['itemNo']!.text.trim(),
      description: _c['description']!.text.trim(),
      unit: _c['unit']!.text.trim(),
      quantity: qty,
      rate: rate,
      amount: qty * rate,
      category: _c['category']!.text.trim(),
      sortOrder: widget.existing?.sortOrder ?? 0,
    );
    await ref.read(boqRepositoryProvider).upsert(item);
    bumpRefresh(ref);
    if (mounted) {
      Navigator.pop(context);
      UiHelpers.showSnack(context, 'BOQ item saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add BOQ Item' : 'Edit BOQ Item'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(children: <Widget>[
                  Expanded(child: _field('itemNo', 'Item No')),
                  const SizedBox(width: 10),
                  Expanded(child: _field('unit', 'Unit')),
                ]),
                _field('description', 'Description *', required: true, maxLines: 2),
                Row(children: <Widget>[
                  Expanded(child: _num('quantity', 'Quantity')),
                  const SizedBox(width: 10),
                  Expanded(child: _num('rate', 'Rate')),
                ]),
                _field('category', 'Category'),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  Widget _field(String key, String label,
      {bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: _c[key],
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, isDense: true),
        validator: required
            ? (String? v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _num(String key, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: _c[key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        decoration: InputDecoration(labelText: label, isDense: true),
      ),
    );
  }
}
