import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/certificate.dart';
import '../../data/models/scheme.dart';
import '../../data/repositories/scheme_repository.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/service_providers.dart';
import '../../services/pdf/pdf_service.dart';
import '../../widgets/section_card.dart';
import '../schemes/scheme_workspace_page.dart';

final _allCertificatesProvider =
    FutureProvider<List<Certificate>>((ref) async {
  ref.watch(refreshTickProvider);
  return ref.watch(certificateRepositoryProvider).all();
});

final _schemeMapProvider = FutureProvider<Map<String, Scheme>>((ref) async {
  ref.watch(refreshTickProvider);
  final List<Scheme> list =
      await ref.watch(schemeRepositoryProvider).query(const SchemeFilter());
  return <String, Scheme>{for (final Scheme s in list) s.id: s};
});

class CertificatesPage extends ConsumerWidget {
  const CertificatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Certificate>> certs =
        ref.watch(_allCertificatesProvider);
    final Map<String, Scheme> schemes =
        ref.watch(_schemeMapProvider).valueOrNull ?? <String, Scheme>{};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Certificates')),
      body: certs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text('Error: $e')),
        data: (List<Certificate> list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.workspace_premium_outlined,
              message:
                  'No certificates issued yet.\nOpen a scheme to create one.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (BuildContext context, int i) {
              final Certificate c = list[i];
              final Scheme? s = schemes[c.schemeId];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.secondary,
                    child:
                        Icon(Icons.verified_outlined, color: AppColors.primary),
                  ),
                  title: Text(c.title ?? c.type ?? 'Certificate',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${s?.schemeName ?? c.schemeId}\n${c.type ?? ''} • ${Formatters.date(c.issuedDate)}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Export PDF',
                    icon: const Icon(Icons.picture_as_pdf),
                    onPressed: s == null
                        ? null
                        : () => _pdf(ref, s, c),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          SchemeWorkspacePage(schemeId: c.schemeId),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _pdf(WidgetRef ref, Scheme scheme, Certificate cert) async {
    final PdfService pdf = await ref.read(pdfServiceProvider.future);
    final Uint8List bytes =
        await pdf.certificate(scheme: scheme, certificate: cert);
    await PdfService.preview(bytes, cert.title ?? 'Certificate');
  }
}
