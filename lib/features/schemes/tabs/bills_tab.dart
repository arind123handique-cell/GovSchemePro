import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../data/models/bill.dart';
import '../../../data/models/boq_item.dart';
import '../../../data/models/contractor.dart';
import '../../../data/models/scheme.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../services/pdf/pdf_service.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_chip.dart';

class BillsTab extends ConsumerWidget {
  final String schemeId;
  const BillsTab({super.key, required this.schemeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Bill>> bills = ref.watch(schemeBillsProvider(schemeId));

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('New Bill'),
      ),
      body: bills.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text('Error: $e')),
        data: (List<Bill> list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'No bills yet.\nGenerate RA / Final bills with Form 25.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: list.length,
            itemBuilder: (BuildContext context, int i) {
              final Bill b = list[i];
              return Card(
                child: ListTile(
                  title: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                            '${b.billType ?? 'Bill'} • ${b.billNumber ?? b.id.substring(0, 6)}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      StatusChip(b.status),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                        '${Formatters.date(b.billDate)}  •  Gross ${Formatters.currency(b.grossAmount)}  •  Net Payable ${Formatters.currency(b.netPayable)}'),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (String v) async {
                      switch (v) {
                        case 'edit':
                          _open(context, ref, b);
                          break;
                        case 'form25':
                          await _form25(context, ref, b);
                          break;
                        case 'export':
                          await _form25(context, ref, b, export: true);
                          break;
                        case 'delete':
                          final bool ok = await UiHelpers.confirm(context,
                              title: 'Delete bill',
                              message: 'Delete this bill permanently?',
                              destructive: true,
                              confirmLabel: 'Delete');
                          if (ok) {
                            await ref.read(billRepositoryProvider).delete(b.id);
                            bumpRefresh(ref);
                          }
                          break;
                      }
                    },
                    itemBuilder: (_) => const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                          value: 'form25', child: Text('Form 25 PDF')),
                      PopupMenuItem<String>(
                          value: 'export', child: Text('Export PDF')),
                      PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                      PopupMenuItem<String>(
                          value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () => _open(context, ref, b),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, Bill? bill) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => BillFormPage(schemeId: schemeId, existing: bill),
    ));
  }

  Future<void> _form25(BuildContext context, WidgetRef ref, Bill bill,
      {bool export = false}) async {
    final Scheme? scheme =
        await ref.read(schemeRepositoryProvider).getById(schemeId);
    if (scheme == null) return;
    final List<BillItem> items =
        await ref.read(billRepositoryProvider).itemsFor(bill.id);
    final Contractor? contractor = bill.contractorId == null
        ? null
        : await ref.read(contractorRepositoryProvider).getById(bill.contractorId!);
    final PdfService pdf = await ref.read(pdfServiceProvider.future);
    final Uint8List bytes = await pdf.form25(
      scheme: scheme,
      bill: bill,
      items: items,
      contractor: contractor,
    );
    final String name = 'Form25_${bill.billNumber ?? bill.id}';
    if (export) {
      await PdfService.share(bytes, '$name.pdf');
    } else {
      await PdfService.preview(bytes, name);
    }
  }
}

class BillFormPage extends ConsumerStatefulWidget {
  final String schemeId;
  final Bill? existing;
  const BillFormPage({super.key, required this.schemeId, this.existing});

  @override
  ConsumerState<BillFormPage> createState() => _BillFormPageState();
}

class _BillFormPageState extends ConsumerState<BillFormPage> {
  final Map<String, TextEditingController> _c = <String, TextEditingController>{};
  final List<_LineItem> _items = <_LineItem>[];

  String _billType = AppConstants.billTypes.first;
  String _status = AppConstants.billStatuses.first;
  DateTime _billDate = DateTime.now();
  double _previousAmount = 0;
  Scheme? _scheme;
  bool _loading = true;

  TextEditingController _ctrl(String k, [String v = '']) =>
      _c.putIfAbsent(k, () => TextEditingController(text: v));

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final Scheme? scheme =
        await ref.read(schemeRepositoryProvider).getById(widget.schemeId);
    final Bill? b = widget.existing;
    _previousAmount = await ref
        .read(billRepositoryProvider)
        .previousTotal(widget.schemeId, excludeBillId: b?.id);

    if (b != null) {
      _billType = b.billType ?? _billType;
      _status = b.status;
      _billDate = b.billDate ?? DateTime.now();
      _ctrl('billNumber', b.billNumber ?? '');
      _ctrl('securityDeposit', b.securityDeposit.toString());
      _ctrl('gst', b.gst.toString());
      _ctrl('labourCess', b.labourCess.toString());
      _ctrl('incomeTax', b.incomeTax.toString());
      _ctrl('royalty', b.royalty.toString());
      _ctrl('otherRecoveries', b.otherRecoveries.toString());
      _ctrl('remarks', b.remarks ?? '');
      final List<BillItem> items =
          await ref.read(billRepositoryProvider).itemsFor(b.id);
      for (final BillItem it in items) {
        _items.add(_LineItem.fromBillItem(it));
      }
    } else {
      final int count =
          await ref.read(billRepositoryProvider).countForScheme(widget.schemeId);
      _ctrl('billNumber',
          IdGenerator.billNumber(widget.schemeId, count + 1));
      // Seed line items from BOQ.
      final List<BoqItem> boq =
          await ref.read(boqRepositoryProvider).forScheme(widget.schemeId);
      for (final BoqItem item in boq) {
        _items.add(_LineItem.fromBoq(item));
      }
      for (final String k in <String>[
        'securityDeposit',
        'gst',
        'labourCess',
        'incomeTax',
        'royalty',
        'otherRecoveries'
      ]) {
        _ctrl(k, '0');
      }
      _ctrl('remarks', '');
    }
    if (mounted) {
      setState(() {
        _scheme = scheme;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    for (final TextEditingController c in _c.values) {
      c.dispose();
    }
    for (final _LineItem it in _items) {
      it.dispose();
    }
    super.dispose();
  }

  double get _gross =>
      _items.fold(0, (double s, _LineItem it) => s + it.amount);

  double get _netAmount => _gross - _previousAmount;

  double _ded(String k) => double.tryParse(_ctrl(k).text.trim()) ?? 0;

  double get _totalDeductions =>
      _ded('securityDeposit') +
      _ded('gst') +
      _ded('labourCess') +
      _ded('incomeTax') +
      _ded('royalty') +
      _ded('otherRecoveries');

  double get _netPayable => _netAmount - _totalDeductions;

  Future<void> _save({bool preview = false}) async {
    final String billId = widget.existing?.id ?? IdGenerator.uuid();
    final Bill bill = Bill(
      id: billId,
      schemeId: widget.schemeId,
      contractorId: _scheme?.contractorId,
      billNumber: _ctrl('billNumber').text.trim(),
      billType: _billType,
      billDate: _billDate,
      grossAmount: _gross,
      previousAmount: _previousAmount,
      netAmount: _netAmount,
      securityDeposit: _ded('securityDeposit'),
      gst: _ded('gst'),
      labourCess: _ded('labourCess'),
      incomeTax: _ded('incomeTax'),
      royalty: _ded('royalty'),
      otherRecoveries: _ded('otherRecoveries'),
      netPayable: _netPayable,
      status: _status,
      remarks: _ctrl('remarks').text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    final List<BillItem> items = <BillItem>[];
    for (int i = 0; i < _items.length; i++) {
      final _LineItem it = _items[i];
      if (it.amount <= 0 && it.quantity <= 0) continue;
      items.add(it.toBillItem(billId, i));
    }
    await ref.read(billRepositoryProvider).save(bill, items);
    await ref.read(activityRepositoryProvider).log(
        'Bill', 'Saved $_billType ${bill.billNumber}',
        schemeId: widget.schemeId);
    bumpRefresh(ref);
    if (!mounted) return;
    if (preview && _scheme != null) {
      final Contractor? contractor = _scheme!.contractorId == null
          ? null
          : await ref
              .read(contractorRepositoryProvider)
              .getById(_scheme!.contractorId!);
      final PdfService pdf = await ref.read(pdfServiceProvider.future);
      final Uint8List bytes = await pdf.form25(
        scheme: _scheme!,
        bill: bill,
        items: items,
        contractor: contractor,
      );
      await PdfService.preview(bytes, 'Form25_${bill.billNumber}');
    }
    if (mounted) {
      Navigator.pop(context);
      UiHelpers.showSnack(context, 'Bill saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New Bill' : 'Edit Bill'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () => _save(preview: true),
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            label: const Text('Save & Form 25',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                SectionCard(
                  title: 'Bill Details',
                  icon: Icons.description_outlined,
                  child: Column(
                    children: <Widget>[
                      Row(children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _billType,
                            decoration: const InputDecoration(
                                labelText: 'Bill Type', isDense: true),
                            items: AppConstants.billTypes
                                .map((String t) => DropdownMenuItem<String>(
                                    value: t, child: Text(t)))
                                .toList(),
                            onChanged: (String? v) =>
                                setState(() => _billType = v ?? _billType),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _status,
                            decoration: const InputDecoration(
                                labelText: 'Status', isDense: true),
                            items: AppConstants.billStatuses
                                .map((String t) => DropdownMenuItem<String>(
                                    value: t, child: Text(t)))
                                .toList(),
                            onChanged: (String? v) =>
                                setState(() => _status = v ?? _status),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _ctrl('billNumber'),
                            decoration: const InputDecoration(
                                labelText: 'Bill Number', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _billDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _billDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                  labelText: 'Bill Date', isDense: true),
                              child: Text(Formatters.date(_billDate)),
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Work Executed (Bill Items)',
                  icon: Icons.list_alt,
                  actions: <Widget>[
                    IconButton(
                      tooltip: 'Add item',
                      onPressed: () => setState(() => _items.add(_LineItem.blank())),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                  child: _items.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('No items. Add items or import a BOQ.'),
                        )
                      : Column(children: <Widget>[
                          for (int i = 0; i < _items.length; i++)
                            _itemRow(i),
                        ]),
                ),
                const SizedBox(height: 12),
                _abstractCard(),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Remarks',
                  icon: Icons.notes,
                  child: TextField(
                    controller: _ctrl('remarks'),
                    maxLines: 2,
                    decoration: const InputDecoration(isDense: true),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _save(),
                  icon: const Icon(Icons.save),
                  label: const Text('Save Bill'),
                ),
              ],
            ),
    );
  }

  Widget _itemRow(int i) {
    final _LineItem it = _items[i];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: TextField(
              controller: it.description,
              decoration: const InputDecoration(
                  labelText: 'Description', isDense: true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: it.quantityCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(labelText: 'Qty', isDense: true),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: it.rateCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(labelText: 'Rate', isDense: true),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(Formatters.quantity(it.amount),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          IconButton(
            onPressed: () => setState(() {
              _items.removeAt(i).dispose();
            }),
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _abstractCard() {
    Widget row(String label, double value, {bool bold = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
            Text(Formatters.currency(value),
                style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      );
    }

    Widget deduction(String key, String label) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _ctrl(key),
                textAlign: TextAlign.right,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(isDense: true, prefixText: '₹ '),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      );
    }

    return SectionCard(
      title: 'Abstract & Recoveries',
      icon: Icons.calculate_outlined,
      child: Column(
        children: <Widget>[
          row('Gross value of work done (A)', _gross, bold: true),
          row('Less: Previous bill amount', _previousAmount),
          row('Net value of this bill (B)', _netAmount, bold: true),
          const Divider(),
          deduction('securityDeposit', 'Security Deposit'),
          deduction('gst', 'GST'),
          deduction('labourCess', 'Labour Cess'),
          deduction('incomeTax', 'Income Tax'),
          deduction('royalty', 'Royalty'),
          deduction('otherRecoveries', 'Other Recoveries'),
          const Divider(),
          row('Total Deductions', _totalDeductions, bold: true),
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                row('Net Amount Payable', _netPayable, bold: true),
                const SizedBox(height: 4),
                Text(Formatters.amountInWords(_netPayable),
                    style: const TextStyle(
                        fontStyle: FontStyle.italic, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Editable line item backing a bill row.
class _LineItem {
  final String? boqItemId;
  final String? itemNo;
  final String? unit;
  final TextEditingController description;
  final TextEditingController quantityCtrl;
  final TextEditingController rateCtrl;

  _LineItem({
    this.boqItemId,
    this.itemNo,
    this.unit,
    required this.description,
    required this.quantityCtrl,
    required this.rateCtrl,
  });

  factory _LineItem.blank() => _LineItem(
        description: TextEditingController(),
        quantityCtrl: TextEditingController(text: '0'),
        rateCtrl: TextEditingController(text: '0'),
      );

  factory _LineItem.fromBoq(BoqItem item) => _LineItem(
        boqItemId: item.id,
        itemNo: item.itemNo,
        unit: item.unit,
        description: TextEditingController(text: item.description),
        quantityCtrl: TextEditingController(text: '0'),
        rateCtrl: TextEditingController(text: item.rate.toString()),
      );

  factory _LineItem.fromBillItem(BillItem item) => _LineItem(
        boqItemId: item.boqItemId,
        itemNo: item.itemNo,
        unit: item.unit,
        description: TextEditingController(text: item.description ?? ''),
        quantityCtrl: TextEditingController(text: item.quantity.toString()),
        rateCtrl: TextEditingController(text: item.rate.toString()),
      );

  double get quantity => double.tryParse(quantityCtrl.text.trim()) ?? 0;
  double get rate => double.tryParse(rateCtrl.text.trim()) ?? 0;
  double get amount => quantity * rate;

  BillItem toBillItem(String billId, int sortOrder) => BillItem(
        id: IdGenerator.uuid(),
        billId: billId,
        boqItemId: boqItemId,
        itemNo: itemNo,
        description: description.text.trim(),
        unit: unit,
        quantity: quantity,
        rate: rate,
        amount: amount,
        sortOrder: sortOrder,
      );

  void dispose() {
    description.dispose();
    quantityCtrl.dispose();
    rateCtrl.dispose();
  }
}
