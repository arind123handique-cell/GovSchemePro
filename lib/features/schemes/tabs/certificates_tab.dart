import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../data/models/certificate.dart';
import '../../../data/models/scheme.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../services/pdf/pdf_service.dart';
import '../../../widgets/section_card.dart';

class CertificatesTab extends ConsumerWidget {
  final String schemeId;
  const CertificatesTab({super.key, required this.schemeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Certificate>> certs =
        ref.watch(schemeCertificatesProvider(schemeId));

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('New Certificate'),
      ),
      body: certs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text('Error: $e')),
        data: (List<Certificate> list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.workspace_premium_outlined,
              message: 'No certificates issued for this scheme yet.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: list.length,
            itemBuilder: (BuildContext context, int i) {
              final Certificate c = list[i];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.secondary,
                    child: Icon(Icons.verified_outlined,
                        color: AppColors.primary),
                  ),
                  title: Text(c.title ?? c.type ?? 'Certificate',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${c.type ?? ''}  •  ${Formatters.date(c.issuedDate)}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (String v) async {
                      switch (v) {
                        case 'pdf':
                          await _pdf(context, ref, c);
                          break;
                        case 'edit':
                          _edit(context, ref, c);
                          break;
                        case 'delete':
                          await ref
                              .read(certificateRepositoryProvider)
                              .delete(c.id);
                          bumpRefresh(ref);
                          break;
                      }
                    },
                    itemBuilder: (_) => const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                          value: 'pdf', child: Text('Export PDF')),
                      PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                      PopupMenuItem<String>(
                          value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () => _edit(context, ref, c),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _pdf(
      BuildContext context, WidgetRef ref, Certificate cert) async {
    final Scheme? scheme =
        await ref.read(schemeRepositoryProvider).getById(schemeId);
    if (scheme == null) return;
    final PdfService pdf = await ref.read(pdfServiceProvider.future);
    final Uint8List bytes =
        await pdf.certificate(scheme: scheme, certificate: cert);
    await PdfService.preview(bytes, cert.title ?? 'Certificate');
  }

  Future<void> _edit(
      BuildContext context, WidgetRef ref, Certificate? existing) async {
    final Scheme? scheme =
        await ref.read(schemeRepositoryProvider).getById(schemeId);
    if (scheme == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) =>
          _CertDialog(scheme: scheme, existing: existing),
    );
  }
}

class _CertDialog extends ConsumerStatefulWidget {
  final Scheme scheme;
  final Certificate? existing;
  const _CertDialog({required this.scheme, this.existing});

  @override
  ConsumerState<_CertDialog> createState() => _CertDialogState();
}

class _CertDialogState extends ConsumerState<_CertDialog> {
  late String _type;
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _officer;
  DateTime _issuedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final Certificate? e = widget.existing;
    _type = e?.type ?? AppConstants.certificateTypes.first;
    _title = TextEditingController(text: e?.title ?? _type);
    _body = TextEditingController(text: e?.body ?? _template(_type));
    _officer = TextEditingController(text: e?.officerName ?? '');
    _issuedDate = e?.issuedDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _officer.dispose();
    super.dispose();
  }

  String _template(String type) {
    final Scheme s = widget.scheme;
    return 'This is to certify that the work "${s.schemeName}" '
        '(Scheme ID: ${s.id}) under ${s.department ?? 'the Department'}, '
        'executed by the contractor as per Work Order '
        '${s.workOrderNumber ?? '-'}, has been examined with reference to '
        '"$type".\n\nThe particulars recorded in the measurement book and '
        'the running account bills have been verified and found correct. '
        'This certificate is issued for official and audit purposes.';
  }

  void _onTypeChanged(String? v) {
    if (v == null) return;
    setState(() {
      _type = v;
      if (widget.existing == null) {
        _title.text = v;
        _body.text = _template(v);
      }
    });
  }

  Future<void> _save() async {
    final Certificate cert = Certificate(
      id: widget.existing?.id ?? IdGenerator.uuid(),
      schemeId: widget.scheme.id,
      type: _type,
      title: _title.text.trim(),
      body: _body.text.trim(),
      issuedDate: _issuedDate,
      officerName: _officer.text.trim().isEmpty ? null : _officer.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    await ref.read(certificateRepositoryProvider).upsert(cert);
    await ref.read(activityRepositoryProvider).log(
        'Certificate', 'Issued $_type', schemeId: widget.scheme.id);
    bumpRefresh(ref);
    if (mounted) {
      Navigator.pop(context);
      UiHelpers.showSnack(context, 'Certificate saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null
          ? 'New Certificate'
          : 'Edit Certificate'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: _type,
                isExpanded: true,
                decoration:
                    const InputDecoration(labelText: 'Type', isDense: true),
                items: AppConstants.certificateTypes
                    .map((String t) =>
                        DropdownMenuItem<String>(value: t, child: Text(t)))
                    .toList(),
                onChanged: _onTypeChanged,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                decoration:
                    const InputDecoration(labelText: 'Title', isDense: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _body,
                maxLines: 8,
                decoration:
                    const InputDecoration(labelText: 'Body', isDense: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _officer,
                decoration: const InputDecoration(
                    labelText: 'Officer Name (optional)', isDense: true),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _issuedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _issuedDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                      labelText: 'Issued Date', isDense: true),
                  child: Text(Formatters.date(_issuedDate)),
                ),
              ),
            ],
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
}
