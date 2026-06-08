import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../data/repositories/activity_repository.dart';
import '../data/repositories/bill_repository.dart';
import '../data/repositories/boq_repository.dart';
import '../data/repositories/certificate_repository.dart';
import '../data/repositories/contractor_repository.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/document_repository.dart';
import '../data/repositories/mb_repository.dart';
import '../data/repositories/photo_repository.dart';
import '../data/repositories/scheme_repository.dart';
import '../data/repositories/settings_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final schemeRepositoryProvider = Provider<SchemeRepository>(
    (ref) => SchemeRepository(ref.watch(databaseProvider)));

final contractorRepositoryProvider = Provider<ContractorRepository>(
    (ref) => ContractorRepository(ref.watch(databaseProvider)));

final boqRepositoryProvider = Provider<BoqRepository>(
    (ref) => BoqRepository(ref.watch(databaseProvider)));

final mbRepositoryProvider = Provider<MbRepository>(
    (ref) => MbRepository(ref.watch(databaseProvider)));

final billRepositoryProvider = Provider<BillRepository>(
    (ref) => BillRepository(ref.watch(databaseProvider)));

final certificateRepositoryProvider = Provider<CertificateRepository>(
    (ref) => CertificateRepository(ref.watch(databaseProvider)));

final documentRepositoryProvider = Provider<DocumentRepository>(
    (ref) => DocumentRepository(ref.watch(databaseProvider)));

final photoRepositoryProvider = Provider<PhotoRepository>(
    (ref) => PhotoRepository(ref.watch(databaseProvider)));

final activityRepositoryProvider = Provider<ActivityRepository>(
    (ref) => ActivityRepository(ref.watch(databaseProvider)));

final settingsRepositoryProvider = Provider<SettingsRepository>(
    (ref) => SettingsRepository(ref.watch(databaseProvider)));

final dashboardRepositoryProvider = Provider<DashboardRepository>(
    (ref) => DashboardRepository(ref.watch(databaseProvider)));
