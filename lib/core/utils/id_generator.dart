import 'package:uuid/uuid.dart';

/// Generates unique primary keys and human-readable document numbers.
class IdGenerator {
  IdGenerator._();

  static const Uuid _uuid = Uuid();

  static String uuid() => _uuid.v4();

  /// e.g. SCH-2026-000123
  static String schemeId(int sequence) {
    final int year = DateTime.now().year;
    return 'SCH-$year-${sequence.toString().padLeft(6, '0')}';
  }

  static String contractorId(int sequence) =>
      'CON-${sequence.toString().padLeft(5, '0')}';

  static String billNumber(String schemeCode, int sequence) =>
      '$schemeCode/RA-${sequence.toString().padLeft(3, '0')}';
}
