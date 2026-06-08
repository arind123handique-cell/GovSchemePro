import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../data/models/photo.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../widgets/local_image.dart';
import '../../../widgets/section_card.dart';

class PhotosTab extends ConsumerWidget {
  final String schemeId;
  const PhotosTab({super.key, required this.schemeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SchemePhoto>> photos =
        ref.watch(photoListProvider(schemeId));

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Add Photo'),
      ),
      body: photos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text('Error: $e')),
        data: (List<SchemePhoto> list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.photo_library_outlined,
              message:
                  'No photos yet.\nCapture before / during / after work photos.',
            );
          }
          final int columns = Responsive.gridColumns(context);
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: list.length,
            itemBuilder: (BuildContext context, int i) {
              final SchemePhoto p = list[i];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          (p.filePath == null || p.filePath!.isEmpty)
                              ? Container(
                                  color: Colors.black12,
                                  child: const Icon(Icons.image_outlined))
                              : LocalImage(p.filePath!),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(p.stage ?? 'Photo',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10.5)),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.4),
                              ),
                              onPressed: () async {
                                await ref
                                    .read(photoRepositoryProvider)
                                    .delete(p.id);
                                bumpRefresh(ref);
                              },
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(p.caption ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 12.5)),
                          Text(Formatters.dateTime(p.takenAt),
                              style: const TextStyle(fontSize: 11)),
                          if (p.latitude != null && p.longitude != null)
                            Text(
                                '${p.latitude!.toStringAsFixed(4)}, ${p.longitude!.toStringAsFixed(4)}',
                                style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1600, imageQuality: 80);
    if (file == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _PhotoMetaDialog(schemeId: schemeId, path: file.path),
    );
  }
}

class _PhotoMetaDialog extends ConsumerStatefulWidget {
  final String schemeId;
  final String path;
  const _PhotoMetaDialog({required this.schemeId, required this.path});

  @override
  ConsumerState<_PhotoMetaDialog> createState() => _PhotoMetaDialogState();
}

class _PhotoMetaDialogState extends ConsumerState<_PhotoMetaDialog> {
  String _stage = AppConstants.photoStages.first;
  final TextEditingController _caption = TextEditingController();
  final TextEditingController _lat = TextEditingController();
  final TextEditingController _lng = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final SchemePhoto photo = SchemePhoto(
      id: IdGenerator.uuid(),
      schemeId: widget.schemeId,
      stage: _stage,
      caption: _caption.text.trim(),
      filePath: widget.path,
      latitude: double.tryParse(_lat.text.trim()),
      longitude: double.tryParse(_lng.text.trim()),
      takenAt: DateTime.now(),
    );
    await ref.read(photoRepositoryProvider).upsert(photo);
    await ref.read(activityRepositoryProvider).log(
        'Photo', 'Added $_stage photo', schemeId: widget.schemeId);
    bumpRefresh(ref);
    if (mounted) {
      Navigator.pop(context);
      UiHelpers.showSnack(context, 'Photo added');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Photo Details'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: LocalImage(widget.path),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _stage,
              decoration:
                  const InputDecoration(labelText: 'Stage', isDense: true),
              items: AppConstants.photoStages
                  .map((String s) =>
                      DropdownMenuItem<String>(value: s, child: Text(s)))
                  .toList(),
              onChanged: (String? v) => setState(() => _stage = v ?? _stage),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caption,
              decoration:
                  const InputDecoration(labelText: 'Caption', isDense: true),
            ),
            const SizedBox(height: 12),
            Row(children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _lat,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Latitude', isDense: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _lng,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Longitude', isDense: true),
                ),
              ),
            ]),
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
