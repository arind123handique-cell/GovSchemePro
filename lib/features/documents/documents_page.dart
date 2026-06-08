import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/document.dart';
import '../../data/models/scheme.dart';
import '../../data/repositories/scheme_repository.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/section_card.dart';
import '../schemes/scheme_workspace_page.dart';

final _schemeMapProvider = FutureProvider<Map<String, Scheme>>((ref) async {
  ref.watch(refreshTickProvider);
  final List<Scheme> list =
      await ref.watch(schemeRepositoryProvider).query(const SchemeFilter());
  return <String, Scheme>{for (final Scheme s in list) s.id: s};
});

class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SchemeDocument>> docs =
        ref.watch(documentListProvider(null));
    final Map<String, Scheme> schemes =
        ref.watch(_schemeMapProvider).valueOrNull ?? <String, Scheme>{};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Documents')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search documents',
                isDense: true,
              ),
              onChanged: (String v) =>
                  ref.read(documentSearchProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: docs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, _) => Center(child: Text('Error: $e')),
              data: (List<SchemeDocument> list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.folder_open_outlined,
                    message:
                        'No documents.\nUpload documents from a scheme workspace.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: list.length,
                  itemBuilder: (BuildContext context, int i) {
                    final SchemeDocument d = list[i];
                    final Scheme? s = schemes[d.schemeId];
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
                            '${d.category ?? 'Other'} • ${s?.schemeName ?? '-'} • ${Formatters.date(d.uploadedAt)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await ref
                                .read(documentRepositoryProvider)
                                .delete(d.id);
                            bumpRefresh(ref);
                          },
                        ),
                        onTap: d.schemeId == null
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => SchemeWorkspacePage(
                                        schemeId: d.schemeId!),
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
}
