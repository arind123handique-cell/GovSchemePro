import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../data/models/contractor.dart';
import '../../../data/models/scheme.dart';
import '../../../data/models/scheme_progress.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_chip.dart';
import '../../dashboard/dashboard_charts.dart';

class OverviewTab extends ConsumerWidget {
  final Scheme scheme;
  const OverviewTab({super.key, required this.scheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SchemeProgress> progress =
        ref.watch(schemeProgressProvider(scheme.id));
    final AsyncValue<Map<String, Contractor>> contractors =
        ref.watch(contractorMapProvider);
    final Contractor? contractor = contractors.maybeWhen(
        data: (Map<String, Contractor> m) => m[scheme.contractorId],
        orElse: () => null);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(scheme.schemeName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            StatusChip(scheme.status),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _exportSummary(context, ref, progress.valueOrNull),
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text('Summary PDF'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        progress.when(
          loading: () => const LinearProgressIndicator(),
          error: (Object e, _) => Text('Error: $e'),
          data: (SchemeProgress p) => _financialCards(context, p),
        ),
        const SizedBox(height: 12),
        progress.maybeWhen(
          data: (SchemeProgress p) => SectionCard(
            title: 'Progress',
            icon: Icons.speed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                GaugeCard(label: 'Physical', percent: p.physicalPercent),
                GaugeCard(
                    label: 'Financial',
                    percent: p.financialPercent,
                    color: AppColors.success),
              ],
            ),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        _detailsCard(context, contractor),
        const SizedBox(height: 12),
        _activityCard(ref),
      ],
    );
  }

  Widget _financialCards(BuildContext context, SchemeProgress p) {
    final List<Widget> cards = <Widget>[
      _miniCard('Tender Value', Formatters.currency(p.tenderValue),
          Icons.gavel, AppColors.primary),
      _miniCard('BOQ Total', Formatters.currency(p.boqTotal),
          Icons.list_alt, AppColors.primary),
      _miniCard('Billed (Net)', Formatters.currency(p.billedNet),
          Icons.receipt_long, AppColors.success),
      _miniCard('Balance', Formatters.currency(p.balanceValue),
          Icons.account_balance_wallet, AppColors.warning),
    ];
    final int cols = Responsive.isMobile(context) ? 2 : 4;
    return GridView.count(
      crossAxisCount: cols,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: cards,
    );
  }

  Widget _miniCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _detailsCard(BuildContext context, Contractor? contractor) {
    final List<List<String>> rows = <List<String>>[
      <String>['Scheme Type', scheme.schemeType ?? '-'],
      <String>['Department', scheme.department ?? '-'],
      <String>['Division', scheme.division ?? '-'],
      <String>['Financial Year', scheme.financialYear ?? '-'],
      <String>['Contractor', contractor?.name ?? '-'],
      <String>['Funding Source', scheme.fundingSource ?? '-'],
      <String>['AA No.', scheme.aaNumber ?? '-'],
      <String>['TS No.', scheme.tsNumber ?? '-'],
      <String>['Work Order', scheme.workOrderNumber ?? '-'],
      <String>['Start Date', Formatters.date(scheme.startDate)],
      <String>['Target Completion', Formatters.date(scheme.targetCompletionDate)],
      <String>['Location', scheme.location ?? '-'],
      <String>['Village', scheme.village ?? '-'],
      <String>['District', scheme.district ?? '-'],
    ];
    return SectionCard(
      title: 'Scheme Details',
      icon: Icons.info_outline,
      child: Column(
        children: rows
            .map((List<String> r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                          width: 150,
                          child: Text(r[0],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textSecondary))),
                      Expanded(
                          child: Text(r[1],
                              style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _activityCard(WidgetRef ref) {
    return SectionCard(
      title: 'Recent Activity',
      icon: Icons.history,
      child: Consumer(
        builder: (BuildContext context, WidgetRef ref, _) {
          final activities = ref.watch(recentActivitiesProvider);
          return activities.maybeWhen(
            data: (list) {
              final filtered =
                  list.where((a) => a.schemeId == scheme.id).take(6).toList();
              if (filtered.isEmpty) {
                return const Text('No activity recorded',
                    style: TextStyle(color: AppColors.textSecondary));
              }
              return Column(
                children: filtered
                    .map((a) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.circle,
                              size: 8, color: AppColors.primary),
                          title: Text(a.description ?? '',
                              style: const TextStyle(fontSize: 13)),
                          subtitle: Text(Formatters.dateTime(a.createdAt),
                              style: const TextStyle(fontSize: 11)),
                        ))
                    .toList(),
              );
            },
            orElse: () => const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  Future<void> _exportSummary(
      BuildContext context, WidgetRef ref, SchemeProgress? p) async {
    final SchemeProgress prog = p ??
        await ref.read(schemeRepositoryProvider).progress(scheme);
    final Map<String, Contractor> contractors =
        await ref.read(contractorMapProvider.future);
    final pdfService = await ref.read(pdfServiceProvider.future);
    final bytes = await pdfService.schemeSummary(
      scheme: scheme,
      contractor: contractors[scheme.contractorId],
      boqTotal: prog.boqTotal,
      billedNet: prog.billedNet,
      physical: prog.physicalPercent,
      financial: prog.financialPercent,
    );
    if (!context.mounted) return;
    await UiHelpers.exportAndNotify(context,
        bytes: bytes,
        filename: '${scheme.id}_summary.pdf',
        mime: Mime.pdf);
  }
}
