/// SQL DDL for the GovScheme Pro offline database.
class DbSchema {
  DbSchema._();

  static const String contractors = 'contractors';
  static const String schemes = 'schemes';
  static const String boqItems = 'boq_items';
  static const String mbEntries = 'mb_entries';
  static const String bills = 'bills';
  static const String billItems = 'bill_items';
  static const String certificates = 'certificates';
  static const String documents = 'documents';
  static const String photos = 'photos';
  static const String activities = 'activities';
  static const String settings = 'app_settings';

  /// Order matters for creation (parents first) and deletion (reverse).
  static const List<String> tableNames = <String>[
    contractors,
    schemes,
    boqItems,
    mbEntries,
    bills,
    billItems,
    certificates,
    documents,
    photos,
    activities,
    settings,
  ];

  static const List<String> createStatements = <String>[
    '''
    CREATE TABLE $contractors (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      address TEXT,
      gst_number TEXT,
      pan_number TEXT,
      phone TEXT,
      email TEXT,
      bank_account TEXT,
      ifsc TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
    ''',
    '''
    CREATE TABLE $schemes (
      id TEXT PRIMARY KEY,
      scheme_name TEXT NOT NULL,
      scheme_type TEXT,
      department TEXT,
      division TEXT,
      sub_division TEXT,
      financial_year TEXT,
      aa_number TEXT,
      aa_date INTEGER,
      ts_number TEXT,
      ts_date INTEGER,
      work_order_number TEXT,
      work_order_date INTEGER,
      tender_number TEXT,
      contractor_id TEXT,
      contractor_address TEXT,
      tender_value REAL NOT NULL DEFAULT 0,
      estimated_cost REAL NOT NULL DEFAULT 0,
      location TEXT,
      village TEXT,
      block TEXT,
      district TEXT,
      latitude REAL,
      longitude REAL,
      start_date INTEGER,
      target_completion_date INTEGER,
      funding_source TEXT,
      remarks TEXT,
      status TEXT NOT NULL DEFAULT 'Planned',
      archived INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (contractor_id) REFERENCES $contractors (id) ON DELETE SET NULL
    )
    ''',
    '''
    CREATE TABLE $boqItems (
      id TEXT PRIMARY KEY,
      scheme_id TEXT NOT NULL,
      item_no TEXT,
      description TEXT NOT NULL,
      unit TEXT,
      quantity REAL NOT NULL DEFAULT 0,
      rate REAL NOT NULL DEFAULT 0,
      amount REAL NOT NULL DEFAULT 0,
      category TEXT,
      sub_category TEXT,
      remarks TEXT,
      sort_order INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (scheme_id) REFERENCES $schemes (id) ON DELETE CASCADE
    )
    ''',
    '''
    CREATE TABLE $mbEntries (
      id TEXT PRIMARY KEY,
      scheme_id TEXT NOT NULL,
      boq_item_id TEXT,
      mb_number TEXT,
      page_number TEXT,
      entry_date INTEGER,
      item_number TEXT,
      description TEXT,
      location TEXT,
      measured_quantity REAL NOT NULL DEFAULT 0,
      unit TEXT,
      remarks TEXT,
      engineer TEXT,
      photo_path TEXT,
      latitude REAL,
      longitude REAL,
      created_at INTEGER NOT NULL,
      FOREIGN KEY (scheme_id) REFERENCES $schemes (id) ON DELETE CASCADE,
      FOREIGN KEY (boq_item_id) REFERENCES $boqItems (id) ON DELETE SET NULL
    )
    ''',
    '''
    CREATE TABLE $bills (
      id TEXT PRIMARY KEY,
      scheme_id TEXT NOT NULL,
      contractor_id TEXT,
      bill_number TEXT,
      bill_type TEXT,
      bill_date INTEGER,
      gross_amount REAL NOT NULL DEFAULT 0,
      previous_amount REAL NOT NULL DEFAULT 0,
      net_amount REAL NOT NULL DEFAULT 0,
      security_deposit REAL NOT NULL DEFAULT 0,
      gst REAL NOT NULL DEFAULT 0,
      labour_cess REAL NOT NULL DEFAULT 0,
      income_tax REAL NOT NULL DEFAULT 0,
      royalty REAL NOT NULL DEFAULT 0,
      other_recoveries REAL NOT NULL DEFAULT 0,
      net_payable REAL NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'Draft',
      remarks TEXT,
      created_at INTEGER NOT NULL,
      FOREIGN KEY (scheme_id) REFERENCES $schemes (id) ON DELETE CASCADE,
      FOREIGN KEY (contractor_id) REFERENCES $contractors (id) ON DELETE SET NULL
    )
    ''',
    '''
    CREATE TABLE $billItems (
      id TEXT PRIMARY KEY,
      bill_id TEXT NOT NULL,
      boq_item_id TEXT,
      item_no TEXT,
      description TEXT,
      unit TEXT,
      quantity REAL NOT NULL DEFAULT 0,
      rate REAL NOT NULL DEFAULT 0,
      amount REAL NOT NULL DEFAULT 0,
      sort_order INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (bill_id) REFERENCES $bills (id) ON DELETE CASCADE
    )
    ''',
    '''
    CREATE TABLE $certificates (
      id TEXT PRIMARY KEY,
      scheme_id TEXT NOT NULL,
      type TEXT,
      title TEXT,
      body TEXT,
      issued_date INTEGER,
      officer_name TEXT,
      created_at INTEGER NOT NULL,
      FOREIGN KEY (scheme_id) REFERENCES $schemes (id) ON DELETE CASCADE
    )
    ''',
    '''
    CREATE TABLE $documents (
      id TEXT PRIMARY KEY,
      scheme_id TEXT,
      category TEXT,
      name TEXT NOT NULL,
      file_path TEXT,
      file_size INTEGER,
      uploaded_at INTEGER NOT NULL,
      FOREIGN KEY (scheme_id) REFERENCES $schemes (id) ON DELETE CASCADE
    )
    ''',
    '''
    CREATE TABLE $photos (
      id TEXT PRIMARY KEY,
      scheme_id TEXT NOT NULL,
      bill_id TEXT,
      stage TEXT,
      caption TEXT,
      file_path TEXT,
      latitude REAL,
      longitude REAL,
      taken_at INTEGER NOT NULL,
      FOREIGN KEY (scheme_id) REFERENCES $schemes (id) ON DELETE CASCADE
    )
    ''',
    '''
    CREATE TABLE $activities (
      id TEXT PRIMARY KEY,
      scheme_id TEXT,
      type TEXT,
      description TEXT,
      created_at INTEGER NOT NULL
    )
    ''',
    '''
    CREATE TABLE $settings (
      key TEXT PRIMARY KEY,
      value TEXT
    )
    ''',
  ];
}
