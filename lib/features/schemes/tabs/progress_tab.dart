import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/boq_item.dart';
import '../../../data/models/scheme_progress.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../widgets/section_card.dart';
import '../../dashboard/dashboard_charts.dart';

/// Cumulative executed quantity per BOQ item id.
final _executedProvider =
    FutureProvider.family<Map<String, double>, String>((ref, schemeId) async {
  ref.watch(refreshTickProvider);
  return ref.watch(mbRepositoryProvider).executedByBoqItem(schemeId);
});

class ProgressTab extends ConsumerWidget {
  final String schemeId;
  const ProgressTab({super.key, required this.schemeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SchemeProgress> progress =
        ref.watch(schemeProgressProvider(schemeId));
    final AsyncValue<List<BoqItem>> boq = ref.watch(boqListProvider(schemeId));
    final AsyncValue<Map<String, double>> executed =
        ref.watch(_executedProvider(schemeId));

    return progress.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, _) => Center(child: Text('Error: $e')),
      data: (SchemeProgress p) => ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SectionCard(
            title: 'Progress Overview',
            icon: Icons.speed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                GaugeCard(
                    label: 'Physical',
                    percent: p.physicalPercent,
                    color: AppColors.primary),
                GaugeCard(
                    label: 'Financial',
                    percent: p.financialPercent,
                    color: AppColors.success),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Financial Summary',
            icon: Icons.account_balance_wallet_outlined,
            child: Column(
              children: <Widget>[
                _row('Tender Value', Formatters.currency(p.tenderValue)),
                _row('BOQ Total', Formatters.currency(p.boqTotal)),
                _row('Executed Value', Formatters.currency(p.executedValue)),
                _row('Billed (Net)', Formatters.currency(p.billedNet)),
                _row('Balance Value', Formatters.currency(p.balanceValue)),
                _bar('Physical Progress', p.physicalPercent, AppColors.primary),
                _bar('Financial Progress', p.financialPercent,
                    AppColors.success),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Item-wise Execution',
            icon: Icons.checklist,
            child: boq.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, _) => Text('Error: $e'),
              data: (List<BoqItem> items) {
                if (items.isEmpty) {
                  return const Text('No BOQ items to track.');
                }
                final Map<String, double> exec =
                    executed.valueOrNull ?? <String, double>{};
                return Column(
                  children: items.map((BoqItem item) {
                    final double done = exec[item.id] ?? 0;
                    final double pct = item.quantity > 0
                        ? (done / item.quantity * 100).clamp(0, 100).toDouble()
                        : 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                    '${item.itemNo ?? ''} ${item.description}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Text(
                                  '${Formatters.quantity(done)}/${Formatters.quantity(item.quantity)} ${item.unit ?? ''}',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              minHeight: 8,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _bar(String label, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(label),
              Text(Formatters.percent(percent),
                  style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0, 1),
              minHeight: 10,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
