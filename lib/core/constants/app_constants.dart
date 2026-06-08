/// Static option lists and enumerations used across the app.
class AppConstants {
  AppConstants._();

  static const String appName = 'GovScheme Pro';
  static const String appTagline =
      'Government Scheme, eMB, BOQ, Billing & Monitoring System';

  static const List<String> schemeStatuses = <String>[
    'Planned',
    'Ongoing',
    'Delayed',
    'Completed',
    'On Hold',
    'Cancelled',
  ];

  static const List<String> schemeTypes = <String>[
    'Road',
    'Building',
    'Bridge',
    'Water Supply',
    'Drainage',
    'Irrigation',
    'Electrical',
    'Sanitation',
    'Other',
  ];

  static const List<String> billTypes = <String>[
    'RA Bill',
    'Running Bill',
    'Final Bill',
    'First & Final Bill',
    'Advance Bill',
    'Part Bill',
  ];

  static const List<String> billStatuses = <String>[
    'Draft',
    'Submitted',
    'Verified',
    'Paid',
    'Rejected',
  ];

  static const List<String> certificateTypes = <String>[
    'Physical Progress Certificate',
    'Verification Certificate',
    'Completion Certificate',
    'Bill Verification Certificate',
    'Measurement Certificate',
    'Contractor Payment Certificate',
    'Work Completion Certificate',
  ];

  static const List<String> documentCategories = <String>[
    'AA',
    'TS',
    'Estimate',
    'Agreement',
    'BOQ',
    'MB',
    'Bills',
    'Certificates',
    'Drawings',
    'Photos',
    'Other Documents',
  ];

  static const List<String> photoStages = <String>[
    'Before Work',
    'During Work',
    'After Work',
  ];

  static const List<String> fundingSources = <String>[
    'State Plan',
    'Central Plan',
    'CSS',
    'SOPD',
    'MGNREGA',
    'Finance Commission',
    'Other',
  ];

  static List<String> financialYears() {
    final List<String> years = <String>[];
    final int current = DateTime.now().year;
    for (int y = current + 1; y >= current - 8; y--) {
      years.add('${y - 1}-${y.toString().substring(2)}');
    }
    return years;
  }
}
