import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/activity.dart';
import '../data/models/bill.dart';
import '../data/models/boq_item.dart';
import '../data/models/certificate.dart';
import '../data/models/contractor.dart';
import '../data/models/dashboard_stats.dart';
import '../data/models/document.dart';
import '../data/models/mb_entry.dart';
import '../data/models/photo.dart';
import '../data/models/scheme.dart';
import '../data/models/scheme_progress.dart';
import '../data/repositories/scheme_repository.dart';
import 'repository_providers.dart';

/// Bump to force dependent providers to refetch after a write.
final refreshTickProvider = StateProvider<int>((ref) => 0);

void bumpRefresh(WidgetRef ref) =>
    ref.read(refreshTickProvider.notifier).state++;

// ----------------------------- Dashboard ------------------------------------

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  ref.watch(refreshTickProvider);
  return ref.watch(dashboardRepositoryProvider).load();
});

final upcomingCompletionsProvider =
    FutureProvider<List<Map<String, Object?>>>((ref) async {
  ref.watch(refreshTickProvider);
  return ref.watch(dashboardRepositoryProvider).upcomingCompletions();
});

final recentActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  ref.watch(refreshTickProvider);
  return ref.watch(activityRepositoryProvider).recent();
});

// ----------------------------- Schemes --------------------------------------

final schemeFilterProvider =
    StateProvider<SchemeFilter>((ref) => const SchemeFilter());

final schemeListProvider = FutureProvider<List<Scheme>>((ref) async {
  ref.watch(refreshTickProvider);
  final SchemeFilter filter = ref.watch(schemeFilterProvider);
  return ref.watch(schemeRepositoryProvider).query(filter);
});

final departmentsProvider = FutureProvider<List<String>>((ref) async {
  ref.watch(refreshTickProvider);
  return ref.watch(schemeRepositoryProvider).distinctDepartments();
});

final schemeByIdProvider =
    FutureProvider.family<Scheme?, String>((ref, id) async {
  ref.watch(refreshTickProvider);
  return ref.watch(schemeRepositoryProvider).getById(id);
});

final schemeProgressProvider =
    FutureProvider.family<SchemeProgress, String>((ref, id) async {
  ref.watch(refreshTickProvider);
  final scheme = await ref.watch(schemeRepositoryProvider).getById(id);
  if (scheme == null) return const SchemeProgress();
  return ref.watch(schemeRepositoryProvider).progress(scheme);
});

// ----------------------------- Contractors ----------------------------------

final contractorSearchProvider = StateProvider<String>((ref) => '');

final contractorListProvider = FutureProvider<List<Contractor>>((ref) async {
  ref.watch(refreshTickProvider);
  final String search = ref.watch(contractorSearchProvider);
  return ref.watch(contractorRepositoryProvider).getAll(search: search);
});

/// Quick lookup map id -> contractor for tables.
final contractorMapProvider =
    FutureProvider<Map<String, Contractor>>((ref) async {
  final List<Contractor> list =
      await ref.watch(contractorRepositoryProvider).getAll();
  return <String, Contractor>{for (final Contractor c in list) c.id: c};
});

// ----------------------------- BOQ ------------------------------------------

final boqListProvider =
    FutureProvider.family<List<BoqItem>, String>((ref, schemeId) async {
  ref.watch(refreshTickProvider);
  return ref.watch(boqRepositoryProvider).forScheme(schemeId);
});

// ----------------------------- Measurement Book -----------------------------

final mbListProvider =
    FutureProvider.family<List<MbEntry>, String>((ref, schemeId) async {
  ref.watch(refreshTickProvider);
  return ref.watch(mbRepositoryProvider).forScheme(schemeId);
});

// ----------------------------- Bills ----------------------------------------

final schemeBillsProvider =
    FutureProvider.family<List<Bill>, String>((ref, schemeId) async {
  ref.watch(refreshTickProvider);
  return ref.watch(billRepositoryProvider).forScheme(schemeId);
});

final billSearchProvider = StateProvider<String>((ref) => '');

final allBillsProvider = FutureProvider<List<Bill>>((ref) async {
  ref.watch(refreshTickProvider);
  return ref.watch(billRepositoryProvider).all(search: ref.watch(billSearchProvider));
});

// ----------------------------- Certificates ---------------------------------

final schemeCertificatesProvider =
    FutureProvider.family<List<Certificate>, String>((ref, schemeId) async {
  ref.watch(refreshTickProvider);
  return ref.watch(certificateRepositoryProvider).forScheme(schemeId);
});

final pendingCertificatesProvider = FutureProvider<int>((ref) async {
  ref.watch(refreshTickProvider);
  return ref.watch(certificateRepositoryProvider).pendingCount();
});

// ----------------------------- Documents ------------------------------------

final documentSearchProvider = StateProvider<String>((ref) => '');

final documentListProvider =
    FutureProvider.family<List<SchemeDocument>, String?>((ref, schemeId) async {
  ref.watch(refreshTickProvider);
  return ref.watch(documentRepositoryProvider).all(
        schemeId: schemeId,
        search: ref.watch(documentSearchProvider),
      );
});

// ----------------------------- Photos ---------------------------------------

final photoListProvider =
    FutureProvider.family<List<SchemePhoto>, String>((ref, schemeId) async {
  ref.watch(refreshTickProvider);
  return ref.watch(photoRepositoryProvider).forScheme(schemeId);
});

// ----------------------------- Settings -------------------------------------

final settingsProvider = FutureProvider<Map<String, String>>((ref) async {
  ref.watch(refreshTickProvider);
  return ref.watch(settingsRepositoryProvider).all();
});
