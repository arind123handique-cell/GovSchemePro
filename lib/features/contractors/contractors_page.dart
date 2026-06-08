import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/id_generator.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/ui_helpers.dart';
import '../../data/models/contractor.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/section_card.dart';

class ContractorsPage extends ConsumerWidget {
  const ContractorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Contractor>> contractors =
        ref.watch(contractorListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Contractor'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search contractors by name, GST or phone',
              ),
              onChanged: (String v) =>
                  ref.read(contractorSearchProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: contractors.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, _) => Center(child: Text('Error: $e')),
              data: (List<Contractor> list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.engineering_outlined,
                    message: 'No contractors yet',
                  );
                }
                final int columns = Responsive.isDesktop(context)
                    ? 3
                    : Responsive.isTablet(context)
                        ? 2
                        : 1;
                return GridView.count(
                  crossAxisCount: columns,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: list
                      .map((Contractor c) => _ContractorCard(
                            contractor: c,
                            onEdit: () => _edit(context, ref, c),
                            onDelete: () => _delete(context, ref, c),
                          ))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, Contractor c) async {
    final bool ok = await UiHelpers.confirm(
      context,
      title: 'Delete Contractor',
      message: 'Delete "${c.name}"? Schemes will be unlinked.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(contractorRepositoryProvider).delete(c.id);
    bumpRefresh(ref);
    if (context.mounted) UiHelpers.showSnack(context, 'Contractor deleted');
  }

  Future<void> _edit(
      BuildContext context, WidgetRef ref, Contractor? existing) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) =>
          _ContractorDialog(existing: existing),
    );
  }
}

class _ContractorCard extends StatelessWidget {
  final Contractor contractor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContractorCard({
    required this.contractor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const CircleAvatar(
                  backgroundColor: AppColors.secondary,
                  child: Icon(Icons.engineering, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    contractor.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (String v) =>
                      v == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                    PopupMenuItem<String>(
                        value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if ((contractor.gstNumber ?? '').isNotEmpty)
              _row(Icons.badge_outlined, 'GST: ${contractor.gstNumber}'),
            if ((contractor.phone ?? '').isNotEmpty)
              _row(Icons.phone_outlined, contractor.phone!),
            if ((contractor.address ?? '').isNotEmpty)
              _row(Icons.place_outlined, contractor.address!),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}

class _ContractorDialog extends ConsumerStatefulWidget {
  final Contractor? existing;
  const _ContractorDialog({this.existing});

  @override
  ConsumerState<_ContractorDialog> createState() => _ContractorDialogState();
}

class _ContractorDialogState extends ConsumerState<_ContractorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;

  @override
  void initState() {
    super.initState();
    final Contractor? e = widget.existing;
    _c = <String, TextEditingController>{
      'name': TextEditingController(text: e?.name ?? ''),
      'address': TextEditingController(text: e?.address ?? ''),
      'gst': TextEditingController(text: e?.gstNumber ?? ''),
      'pan': TextEditingController(text: e?.panNumber ?? ''),
      'phone': TextEditingController(text: e?.phone ?? ''),
      'email': TextEditingController(text: e?.email ?? ''),
      'bank': TextEditingController(text: e?.bankAccount ?? ''),
      'ifsc': TextEditingController(text: e?.ifsc ?? ''),
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
    final DateTime now = DateTime.now();
    final Contractor contractor = Contractor(
      id: widget.existing?.id ?? IdGenerator.uuid(),
      name: _c['name']!.text.trim(),
      address: _c['address']!.text.trim(),
      gstNumber: _c['gst']!.text.trim(),
      panNumber: _c['pan']!.text.trim(),
      phone: _c['phone']!.text.trim(),
      email: _c['email']!.text.trim(),
      bankAccount: _c['bank']!.text.trim(),
      ifsc: _c['ifsc']!.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    await ref.read(contractorRepositoryProvider).upsert(contractor);
    bumpRefresh(ref);
    if (mounted) {
      Navigator.of(context).pop();
      UiHelpers.showSnack(context, 'Contractor saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Contractor' : 'Edit Contractor'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _field('name', 'Contractor Name *', required: true),
                _field('address', 'Address', maxLines: 2),
                Row(children: <Widget>[
                  Expanded(child: _field('gst', 'GST Number')),
                  const SizedBox(width: 10),
                  Expanded(child: _field('pan', 'PAN Number')),
                ]),
                Row(children: <Widget>[
                  Expanded(child: _field('phone', 'Phone')),
                  const SizedBox(width: 10),
                  Expanded(child: _field('email', 'Email')),
                ]),
                Row(children: <Widget>[
                  Expanded(child: _field('bank', 'Bank Account')),
                  const SizedBox(width: 10),
                  Expanded(child: _field('ifsc', 'IFSC')),
                ]),
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
}
