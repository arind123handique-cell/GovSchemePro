import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../data/models/boq_item.dart';
import '../../../data/models/mb_entry.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../widgets/section_card.dart';

class MbTab extends ConsumerWidget {
  final String schemeId;
  const MbTab({super.key, required this.schemeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MbEntry>> entries = ref.watch(mbListProvider(schemeId));
    final AsyncValue<List<BoqItem>> boq = ref.watch(boqListProvider(schemeId));

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null, boq.valueOrNull ?? <BoqItem>[]),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text('Error: $e')),
        data: (List<MbEntry> list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.menu_book_outlined,
              message: 'No measurement entries.\nRecord field measurements here.',
            );
          }
          return Column(
            children: <Widget>[
              _toolbar(context, ref, list),
              Expanded(child: _list(context, ref, list, boq.valueOrNull ?? <BoqItem>[])),
            ],
          );
        },
      ),
    );
  }

  Widget _toolbar(BuildContext context, WidgetRef ref, List<MbEntry> list) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text('${list.length} measurement entries',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            OutlinedButton.icon(
              onPressed: () => _export(context, ref, list),
              icon: const Icon(Icons.table_view, size: 18),
              label: const Text('Excel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, List<MbEntry> list,
      List<BoqItem> boq) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
      itemCount: list.length,
      itemBuilder: (BuildContext context, int i) {
        final MbEntry e = list[i];
        return Card(
          child: ListTile(
            title: Text(e.description ?? 'Entry',
                maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 4),
                Text(
                    'MB ${e.mbNumber ?? '-'} • Pg ${e.pageNumber ?? '-'} • ${Formatters.date(e.entryDate)}',
                    style: const TextStyle(fontSize: 12)),
                Text(
                    'Measured: ${Formatters.quantity(e.measuredQuantity)} ${e.unit ?? ''}  •  ${e.engineer ?? ''}',
                    style: const TextStyle(fontSize: 12)),
                if ((e.location ?? '').isNotEmpty)
                  Text('Location: ${e.location}',
                      style: const TextStyle(fontSize: 12)),
              ],
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (String v) async {
                if (v == 'edit') {
                  _edit(context, ref, e, boq);
                } else {
                  await ref.read(mbRepositoryProvider).delete(e.id);
                  bumpRefresh(ref);
                }
              },
              itemBuilder: (_) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _export(
      BuildContext context, WidgetRef ref, List<MbEntry> list) async {
    final List<List<Object?>> rows = list
        .map((MbEntry e) => <Object?>[
              e.mbNumber,
              e.pageNumber,
              Formatters.date(e.entryDate),
              e.itemNumber,
              e.description,
              e.location,
              e.measuredQuantity,
              e.unit,
              e.engineer,
            ])
        .toList();
    final bytes = ref.read(excelServiceProvider).buildSheet(
      name: 'Measurement Book',
      headers: const <String>[
        'MB No',
        'Page',
        'Date',
        'Item',
        'Description',
        'Location',
        'Measured Qty',
        'Unit',
        'Engineer'
      ],
      rows: rows,
    );
    await UiHelpers.exportAndNotify(context,
        bytes: bytes, filename: '${schemeId}_mb.xlsx', mime: Mime.xlsx);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, MbEntry? existing,
      List<BoqItem> boq) async {
    await showDialog<void>(
      context: context,
      builder: (_) =>
          _MbDialog(schemeId: schemeId, existing: existing, boqItems: boq),
    );
  }
}

class _MbDialog extends ConsumerStatefulWidget {
  final String schemeId;
  final MbEntry? existing;
  final List<BoqItem> boqItems;
  const _MbDialog(
      {required this.schemeId, this.existing, required this.boqItems});

  @override
  ConsumerState<_MbDialog> createState() => _MbDialogState();
}

class _MbDialogState extends ConsumerState<_MbDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  String? _boqItemId;
  DateTime _entryDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final MbEntry? e = widget.existing;
    _boqItemId = e?.boqItemId;
    _entryDate = e?.entryDate ?? DateTime.now();
    _c = <String, TextEditingController>{
      'mbNumber': TextEditingController(text: e?.mbNumber ?? ''),
      'pageNumber': TextEditingController(text: e?.pageNumber ?? ''),
      'description': TextEditingController(text: e?.description ?? ''),
      'location': TextEditingController(text: e?.location ?? ''),
      'quantity': TextEditingController(
          text: e == null ? '' : e.measuredQuantity.toString()),
      'unit': TextEditingController(text: e?.unit ?? ''),
      'engineer': TextEditingController(text: e?.engineer ?? ''),
      'remarks': TextEditingController(text: e?.remarks ?? ''),
      'latitude': TextEditingController(text: e?.latitude?.toString() ?? ''),
      'longitude': TextEditingController(text: e?.longitude?.toString() ?? ''),
    };
  }

  @override
  void dispose() {
    for (final TextEditingController c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onBoqSelected(String? id) {
    setState(() => _boqItemId = id);
    if (id == null) return;
    final BoqItem item =
        widget.boqItems.firstWhere((BoqItem b) => b.id == id);
    if (_c['description']!.text.isEmpty) {
      _c['description']!.text = item.description;
    }
    if (_c['unit']!.text.isEmpty) _c['unit']!.text = item.unit ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final MbEntry entry = MbEntry(
      id: widget.existing?.id ?? IdGenerator.uuid(),
      schemeId: widget.schemeId,
      boqItemId: _boqItemId,
      mbNumber: _c['mbNumber']!.text.trim(),
      pageNumber: _c['pageNumber']!.text.trim(),
      entryDate: _entryDate,
      itemNumber: _boqItemId == null
          ? null
          : widget.boqItems
              .firstWhere((BoqItem b) => b.id == _boqItemId)
              .itemNo,
      description: _c['description']!.text.trim(),
      location: _c['location']!.text.trim(),
      measuredQuantity: double.tryParse(_c['quantity']!.text.trim()) ?? 0,
      unit: _c['unit']!.text.trim(),
      engineer: _c['engineer']!.text.trim(),
      remarks: _c['remarks']!.text.trim(),
      latitude: double.tryParse(_c['latitude']!.text.trim()),
      longitude: double.tryParse(_c['longitude']!.text.trim()),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    await ref.read(mbRepositoryProvider).upsert(entry);
    await ref.read(activityRepositoryProvider).log(
        'MB', 'Recorded measurement: ${entry.description}',
        schemeId: widget.schemeId);
    bumpRefresh(ref);
    if (mounted) {
      Navigator.pop(context);
      UiHelpers.showSnack(context, 'Measurement saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add MB Entry' : 'Edit MB Entry'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.boqItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: DropdownButtonFormField<String>(
                      initialValue: _boqItemId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'Linked BOQ Item', isDense: true),
                      items: <DropdownMenuItem<String>>[
                        const DropdownMenuItem<String>(
                            value: null, child: Text('None')),
                        ...widget.boqItems.map((BoqItem b) =>
                            DropdownMenuItem<String>(
                                value: b.id,
                                child: Text(
                                    '${b.itemNo ?? ''} ${b.description}',
                                    overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: _onBoqSelected,
                    ),
                  ),
                Row(children: <Widget>[
                  Expanded(child: _field('mbNumber', 'MB Number')),
                  const SizedBox(width: 10),
                  Expanded(child: _field('pageNumber', 'Page Number')),
                ]),
                _field('description', 'Description *', required: true, maxLines: 2),
                _field('location', 'Location'),
                Row(children: <Widget>[
                  Expanded(child: _num('quantity', 'Measured Qty')),
                  const SizedBox(width: 10),
                  Expanded(child: _field('unit', 'Unit')),
                ]),
                _field('engineer', 'Engineer'),
                Row(children: <Widget>[
                  Expanded(child: _num('latitude', 'Latitude')),
                  const SizedBox(width: 10),
                  Expanded(child: _num('longitude', 'Longitude')),
                ]),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _entryDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _entryDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                          labelText: 'Entry Date', isDense: true),
                      child: Text(Formatters.date(_entryDate)),
                    ),
                  ),
                ),
                _field('remarks', 'Remarks', maxLines: 2),
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
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
        ],
        decoration: InputDecoration(labelText: label, isDense: true),
      ),
    );
  }
}
