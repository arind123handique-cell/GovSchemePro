import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/activity.dart';
import '../../data/models/dashboard_stats.dart';
import '../../providers/data_providers.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/section_card.dart';
import 'dashboard_charts.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DashboardStats> stats = ref.watch(dashboardStatsProvider);
    final int columns = Responsive.gridColumns(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => bumpRefresh(ref),
        child: stats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, _) => Center(child: Text('Error: $e')),
          data: (DashboardStats s) => ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              const _Header(),
              const SizedBox(height: 16),
              _kpiGrid(s, columns),
              const SizedBox(height: 16),
              _chartsRow(context, s),
              const SizedBox(height: 16),
              _progressAndActivity(context, ref, s),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiGrid(DashboardStats s, int columns) {
    final List<Widget> cards = <Widget>[
      KpiCard(label: 'Total Schemes', value: '${s.totalSchemes}', icon: Icons.account_tree, color: AppColors.primary),
      KpiCard(label: 'Ongoing', value: '${s.ongoingSchemes}', icon: Icons.timelapse, color: AppColors.warning),
      KpiCard(label: 'Completed', value: '${s.completedSchemes}', icon: Icons.check_circle, color: AppColors.success),
      KpiCard(label: 'Delayed', value: '${s.delayedSchemes}', icon: Icons.warning_amber, color: AppColors.danger),
      KpiCard(label: 'Total Tender Value', value: Formatters.compactCurrency(s.totalTenderValue), icon: Icons.gavel, color: AppColors.primary),
      KpiCard(label: 'Bills Generated', value: '${s.totalBillsGenerated}', icon: Icons.receipt_long, color: AppColors.primary),
      KpiCard(label: 'Total Paid', value: Formatters.compactCurrency(s.totalPaidAmount), icon: Icons.payments, color: AppColors.success),
      KpiCard(label: 'Balance Liability', value: Formatters.compactCurrency(s.balanceLiability), icon: Icons.account_balance_wallet, color: AppColors.warning),
      KpiCard(label: 'Physical Progress', value: Formatters.percent(s.physicalProgress), icon: Icons.construction, color: AppColors.primary),
      KpiCard(label: 'Financial Progress', value: Formatters.percent(s.financialProgress), icon: Icons.trending_up, color: AppColors.success),
    ];
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: cards,
    );
  }

  Widget _chartsRow(BuildContext context, DashboardStats s) {
    final bool wide = Responsive.isDesktop(context);
    final List<Widget> charts = <Widget>[
      SectionCard(
        title: 'Scheme Status Distribution',
        icon: Icons.pie_chart_outline,
        child: StatusPieChart(s.statusDistribution),
      ),
      SectionCard(
        title: 'Monthly Expenditure',
        icon: Icons.show_chart,
        child: SimpleBarChart(s.monthlyExpenditure),
      ),
      SectionCard(
        title: 'Contractor-wise Work Value',
        icon: Icons.engineering,
        child: SimpleBarChart(s.contractorWorkValue),
      ),
      SectionCard(
        title: 'Department-wise Scheme Count',
        icon: Icons.apartment,
        child: SimpleBarChart(
          s.departmentSchemeCount.map(
              (String k, int v) => MapEntry<String, double>(k, v.toDouble())),
          currency: false,
          color: AppColors.success,
        ),
      ),
    ];

    if (!wide) {
      return Column(
        children: charts
            .map((Widget c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: c,
                ))
            .toList(),
      );
    }
    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: charts[0]),
            const SizedBox(width: 12),
            Expanded(child: charts[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: charts[2]),
            const SizedBox(width: 12),
            Expanded(child: charts[3]),
          ],
        ),
      ],
    );
  }

  Widget _progressAndActivity(
      BuildContext context, WidgetRef ref, DashboardStats s) {
    final bool wide = Responsive.isDesktop(context);
    final Widget progress = SectionCard(
      title: 'Overall Progress',
      icon: Icons.speed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          GaugeCard(label: 'Physical', percent: s.physicalProgress),
          GaugeCard(
              label: 'Financial',
              percent: s.financialProgress,
              color: AppColors.success),
        ],
      ),
    );

    final Widget activities = SectionCard(
      title: 'Recent Activities',
      icon: Icons.history,
      child: Consumer(
        builder: (BuildContext context, WidgetRef ref, _) {
          final AsyncValue<List<Activity>> a =
              ref.watch(recentActivitiesProvider);
          return a.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator()),
            error: (Object e, _) => Text('Error: $e'),
            data: (List<Activity> list) {
              if (list.isEmpty) {
                return const EmptyState(message: 'No recent activity');
              }
              return Column(
                children: list
                    .take(8)
                    .map((Activity act) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.fiber_manual_record,
                              size: 10, color: AppColors.primary),
                          title: Text(act.description ?? '',
                              style: const TextStyle(fontSize: 13)),
                          subtitle: Text(Formatters.dateTime(act.createdAt),
                              style: const TextStyle(fontSize: 11)),
                        ))
                    .toList(),
              );
            },
          );
        },
      ),
    );

    final Widget upcoming = SectionCard(
      title: 'Upcoming Completion Dates',
      icon: Icons.event_available,
      child: Consumer(
        builder: (BuildContext context, WidgetRef ref, _) {
          final AsyncValue<List<Map<String, Object?>>> u =
              ref.watch(upcomingCompletionsProvider);
          return u.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator()),
            error: (Object e, _) => Text('Error: $e'),
            data: (List<Map<String, Object?>> list) {
              if (list.isEmpty) {
                return const EmptyState(message: 'No upcoming completions');
              }
              return Column(
                children: list.map((Map<String, Object?> row) {
                  final int? ms = row['target_completion_date'] as int?;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.flag_outlined,
                        size: 16, color: AppColors.warning),
                    title: Text(row['scheme_name'] as String? ?? '',
                        style: const TextStyle(fontSize: 13)),
                    trailing: Text(
                      ms != null
                          ? Formatters.date(
                              DateTime.fromMillisecondsSinceEpoch(ms))
                          : '-',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );

    if (!wide) {
      return Column(
        children: <Widget>[
          progress,
          const SizedBox(height: 12),
          activities,
          const SizedBox(height: 12),
          upcoming,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            children: <Widget>[
              progress,
              const SizedBox(height: 12),
              upcoming,
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: activities),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            Text('Dashboard',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            Text('Government Scheme Monitoring Overview',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}
