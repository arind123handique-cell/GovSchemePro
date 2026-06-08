import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui_helpers.dart';
import '../../data/models/contractor.dart';
import '../../data/models/scheme.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/section_card.dart';

class CreateSchemePage extends ConsumerStatefulWidget {
  final Scheme? existing;

  const CreateSchemePage({super.key, this.existing});

  @override
  ConsumerState<CreateSchemePage> createState() => _CreateSchemePageState();
}

class _CreateSchemePageState extends ConsumerState<CreateSchemePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _c = <String, TextEditingController>{};

  String? _schemeId;
  String? _type;
  String? _financialYear;
  String? _fundingSource;
  String _status = 'Planned';
  String? _contractorId;
  DateTime? _aaDate;
  DateTime? _tsDate;
  DateTime? _workOrderDate;
  DateTime? _startDate;
  DateTime? _targetDate;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  TextEditingController _ctrl(String key, [String? initial]) =>
      _c.putIfAbsent(key, () => TextEditingController(text: initial));

  @override
  void initState() {
    super.initState();
    final Scheme? s = widget.existing;
    if (s != null) {
      _schemeId = s.id;
      _type = s.schemeType;
      _financialYear = s.financialYear;
      _fundingSource = s.fundingSource;
      _status = s.status;
      _contractorId = s.contractorId;
      _aaDate = s.aaDate;
      _tsDate = s.tsDate;
      _workOrderDate = s.workOrderDate;
      _startDate = s.startDate;
      _targetDate = s.targetCompletionDate;
      _ctrl('name', s.schemeName);
      _ctrl('department', s.department ?? '');
      _ctrl('division', s.division ?? '');
      _ctrl('subDivision', s.subDivision ?? '');
      _ctrl('aaNumber', s.aaNumber ?? '');
      _ctrl('tsNumber', s.tsNumber ?? '');
      _ctrl('workOrderNumber', s.workOrderNumber ?? '');
      _ctrl('tenderNumber', s.tenderNumber ?? '');
      _ctrl('contractorAddress', s.contractorAddress ?? '');
      _ctrl('tenderValue', s.tenderValue.toString());
      _ctrl('estimatedCost', s.estimatedCost.toString());
      _ctrl('location', s.location ?? '');
      _ctrl('village', s.village ?? '');
      _ctrl('block', s.block ?? '');
      _ctrl('district', s.district ?? '');
      _ctrl('latitude', s.latitude?.toString() ?? '');
      _ctrl('longitude', s.longitude?.toString() ?? '');
      _ctrl('remarks', s.remarks ?? '');
    } else {
      _financialYear = AppConstants.financialYears().first;
      _loadNextId();
    }
  }

  Future<void> _loadNextId() async {
    final String id = await ref.read(schemeRepositoryProvider).nextSchemeId();
    if (mounted) setState(() => _schemeId = id);
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _c.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(DateTime? current, ValueChanged<DateTime> onPicked) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final DateTime now = DateTime.now();
    final double tender = double.tryParse(_ctrl('tenderValue').text.trim()) ?? 0;
    final Scheme scheme = Scheme(
      id: _schemeId ?? await ref.read(schemeRepositoryProvider).nextSchemeId(),
      schemeName: _ctrl('name').text.trim(),
      schemeType: _type,
      department: _ctrl('department').text.trim(),
      division: _ctrl('division').text.trim(),
      subDivision: _ctrl('subDivision').text.trim(),
      financialYear: _financialYear,
      aaNumber: _ctrl('aaNumber').text.trim(),
      aaDate: _aaDate,
      tsNumber: _ctrl('tsNumber').text.trim(),
      tsDate: _tsDate,
      workOrderNumber: _ctrl('workOrderNumber').text.trim(),
      workOrderDate: _workOrderDate,
      tenderNumber: _ctrl('tenderNumber').text.trim(),
      contractorId: _contractorId,
      contractorAddress: _ctrl('contractorAddress').text.trim(),
      tenderValue: tender,
      estimatedCost: double.tryParse(_ctrl('estimatedCost').text.trim()) ?? 0,
      location: _ctrl('location').text.trim(),
      village: _ctrl('village').text.trim(),
      block: _ctrl('block').text.trim(),
      district: _ctrl('district').text.trim(),
      latitude: double.tryParse(_ctrl('latitude').text.trim()),
      longitude: double.tryParse(_ctrl('longitude').text.trim()),
      startDate: _startDate,
      targetCompletionDate: _targetDate,
      fundingSource: _fundingSource,
      remarks: _ctrl('remarks').text.trim(),
      status: _status,
      archived: widget.existing?.archived ?? false,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    await ref.read(schemeRepositoryProvider).upsert(scheme);
    await ref.read(activityRepositoryProvider).log(
          'Scheme',
          _isEdit
              ? 'Scheme "${scheme.schemeName}" updated'
              : 'Scheme "${scheme.schemeName}" created',
          schemeId: scheme.id,
        );
    bumpRefresh(ref);
    if (!mounted) return;
    UiHelpers.showSnack(context, _isEdit ? 'Scheme updated' : 'Scheme created');
    Navigator.of(context).pop(scheme);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Contractor>> contractors =
        ref.watch(contractorListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Scheme' : 'Create Scheme'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            SectionCard(
              title: 'Identification',
              icon: Icons.badge_outlined,
              child: Column(
                children: <Widget>[
                  _readonly('Scheme ID (Auto)', _schemeId ?? 'Generating…'),
                  _gap(),
                  _text('name', 'Scheme Name *', required: true),
                  _gap(),
                  _wrapTwo(
                    _dropdown('Scheme Type', _type, AppConstants.schemeTypes,
                        (String? v) => setState(() => _type = v)),
                    _dropdown('Financial Year', _financialYear,
                        AppConstants.financialYears(),
                        (String? v) => setState(() => _financialYear = v)),
                  ),
                  _gap(),
                  _wrapThree(
                    _text('department', 'Department'),
                    _text('division', 'Division'),
                    _text('subDivision', 'Sub-Division'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Approvals & Sanctions',
              icon: Icons.verified_outlined,
              child: Column(
                children: <Widget>[
                  _wrapTwo(
                    _text('aaNumber', 'Administrative Approval No.'),
                    _dateField('AA Date', _aaDate,
                        (DateTime d) => setState(() => _aaDate = d)),
                  ),
                  _gap(),
                  _wrapTwo(
                    _text('tsNumber', 'Technical Sanction No.'),
                    _dateField('TS Date', _tsDate,
                        (DateTime d) => setState(() => _tsDate = d)),
                  ),
                  _gap(),
                  _wrapTwo(
                    _text('workOrderNumber', 'Work Order No.'),
                    _dateField('Work Order Date', _workOrderDate,
                        (DateTime d) => setState(() => _workOrderDate = d)),
                  ),
                  _gap(),
                  _text('tenderNumber', 'Tender Number'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Contractor & Financials',
              icon: Icons.payments_outlined,
              child: Column(
                children: <Widget>[
                  contractors.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (Object e, _) => Text('Error: $e'),
                    data: (List<Contractor> list) => DropdownButtonFormField<String>(
                      initialValue: _contractorId,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Contractor'),
                      items: <DropdownMenuItem<String>>[
                        const DropdownMenuItem<String>(
                            value: null, child: Text('— None —')),
                        ...list.map((Contractor c) => DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(c.name, overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (String? v) {
                        setState(() {
                          _contractorId = v;
                          final Contractor? c =
                              list.where((Contractor x) => x.id == v).firstOrNull;
                          if (c != null && _ctrl('contractorAddress').text.isEmpty) {
                            _ctrl('contractorAddress').text = c.address ?? '';
                          }
                        });
                      },
                    ),
                  ),
                  _gap(),
                  _text('contractorAddress', 'Contractor Address', maxLines: 2),
                  _gap(),
                  _wrapTwo(
                    _number('tenderValue', 'Tender Value *', required: true),
                    _number('estimatedCost', 'Estimated Cost'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Location',
              icon: Icons.place_outlined,
              child: Column(
                children: <Widget>[
                  _text('location', 'Location'),
                  _gap(),
                  _wrapThree(
                    _text('village', 'Village'),
                    _text('block', 'Block'),
                    _text('district', 'District'),
                  ),
                  _gap(),
                  _wrapTwo(
                    _number('latitude', 'Latitude'),
                    _number('longitude', 'Longitude'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Timeline & Status',
              icon: Icons.schedule_outlined,
              child: Column(
                children: <Widget>[
                  _wrapTwo(
                    _dateField('Start Date', _startDate,
                        (DateTime d) => setState(() => _startDate = d)),
                    _dateField('Target Completion', _targetDate,
                        (DateTime d) => setState(() => _targetDate = d)),
                  ),
                  _gap(),
                  _wrapTwo(
                    _dropdown('Funding Source', _fundingSource,
                        AppConstants.fundingSources,
                        (String? v) => setState(() => _fundingSource = v)),
                    _dropdown('Status', _status, AppConstants.schemeStatuses,
                        (String? v) => setState(() => _status = v ?? 'Planned')),
                  ),
                  _gap(),
                  _text('remarks', 'Remarks', maxLines: 3),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save),
                    label: Text(_isEdit ? 'Update Scheme' : 'Save Scheme'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 12);

  Widget _readonly(String label, String value) => InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      );

  Widget _text(String key, String label,
      {bool required = false, int maxLines = 1}) {
    return TextFormField(
      controller: _ctrl(key),
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _number(String key, String label, {bool required = false}) {
    return TextFormField(
      controller: _ctrl(key),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _dropdown(String label, String? value, List<String> options,
      ValueChanged<String?> onChanged) {
    final List<String> safe = <String>{...options, ?value}.toList();
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: safe
          .map((String o) =>
              DropdownMenuItem<String>(value: o, child: Text(o)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _dateField(String label, DateTime? value, ValueChanged<DateTime> onPicked) {
    return InkWell(
      onTap: () => _pickDate(value, onPicked),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(value == null ? 'Select date' : Formatters.date(value)),
      ),
    );
  }

  Widget _wrapTwo(Widget a, Widget b) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints c) {
      if (c.maxWidth < 520) {
        return Column(children: <Widget>[a, const SizedBox(height: 12), b]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      );
    });
  }

  Widget _wrapThree(Widget a, Widget b, Widget cc) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints c) {
      if (c.maxWidth < 600) {
        return Column(children: <Widget>[
          a,
          const SizedBox(height: 12),
          b,
          const SizedBox(height: 12),
          cc
        ]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
          const SizedBox(width: 12),
          Expanded(child: cc),
        ],
      );
    });
  }
}
