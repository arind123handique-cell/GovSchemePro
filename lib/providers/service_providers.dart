import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audit/audit_service.dart';
import '../services/backup/backup_service.dart';
import '../services/excel/excel_service.dart';
import '../services/import/boq_import_service.dart';
import '../services/pdf/pdf_service.dart';
import 'repository_providers.dart';

final excelServiceProvider = Provider<ExcelService>((ref) => const ExcelService());

final auditServiceProvider = Provider<AuditService>((ref) => const AuditService());

final boqImportServiceProvider =
    Provider<BoqImportService>((ref) => const BoqImportService());

final backupServiceProvider = Provider<BackupService>(
    (ref) => BackupService(ref.watch(databaseProvider)));

/// Builds a [PdfService] using the latest saved department/office settings.
final pdfServiceProvider = FutureProvider<PdfService>((ref) async {
  final Map<String, String> settings =
      await ref.watch(settingsRepositoryProvider).all();
  return PdfService(settings);
});
