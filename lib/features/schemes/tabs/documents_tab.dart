import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../data/models/document.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../widgets/section_card.dart';

class DocumentsTab extends ConsumerWidget {
  final String schemeId;
  const DocumentsTab({super.key, required this.schemeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SchemeDocument>> docs =
        ref.watch(documentListProvider(schemeId));

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _upload(context, ref),
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
      body: docs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text('Error: $e')),
        data: (List<SchemeDocument> list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_open_outlined,
              message:
                  'No documents.\nUpload AA, TS, agreements, drawings, etc.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: list.length,
            itemBuilder: (BuildContext context, int i) {
              final SchemeDocument d = list[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.secondary,
                    child: Text(
                      (d.category ?? '?').characters.first,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(d.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                      '${d.category ?? 'Other'}  •  ${_size(d.fileSize)}  •  ${Formatters.date(d.uploadedAt)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ref.read(documentRepositoryProvider).delete(d.id);
                      bumpRefresh(ref);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _size(int? bytes) {
    if (bytes == null || bytes == 0) return '-';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _upload(BuildContext context, WidgetRef ref) async {
    final FilePickerResult? picked = await FilePicker.platform.pickFiles();
    if (picked == null || picked.files.isEmpty || !context.mounted) return;
    final PlatformFile file = picked.files.first;
    await showDialog<void>(
      context: context,
      builder: (_) => _DocMetaDialog(
        schemeId: schemeId,
        name: file.name,
        path: file.path,
        size: file.size,
      ),
    );
  }
}

class _DocMetaDialog extends ConsumerStatefulWidget {
  final String schemeId;
  final String name;
  final String? path;
  final int size;
  const _DocMetaDialog({
    required this.schemeId,
    required this.name,
    required this.path,
    required this.size,
  });

  @override
  ConsumerState<_DocMetaDialog> createState() => _DocMetaDialogState();
}

class _DocMetaDialogState extends ConsumerState<_DocMetaDialog> {
  String _category = AppConstants.documentCategories.first;
  late final TextEditingController _name =
      TextEditingController(text: widget.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final SchemeDocument doc = SchemeDocument(
      id: IdGenerator.uuid(),
      schemeId: widget.schemeId,
      category: _category,
      name: _name.text.trim().isEmpty ? widget.name : _name.text.trim(),
      filePath: widget.path,
      fileSize: widget.size,
      uploadedAt: DateTime.now(),
    );
    await ref.read(documentRepositoryProvider).upsert(doc);
    await ref.read(activityRepositoryProvider).log(
        'Document', 'Uploaded ${doc.name}', schemeId: widget.schemeId);
    bumpRefresh(ref);
    if (mounted) {
      Navigator.pop(context);
      UiHelpers.showSnack(context, 'Document added');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Document Details'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _name,
              decoration:
                  const InputDecoration(labelText: 'Name', isDense: true),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              decoration:
                  const InputDecoration(labelText: 'Category', isDense: true),
              items: AppConstants.documentCategories
                  .map((String c) =>
                      DropdownMenuItem<String>(value: c, child: Text(c)))
                  .toList(),
              onChanged: (String? v) =>
                  setState(() => _category = v ?? _category),
            ),
          ],
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
