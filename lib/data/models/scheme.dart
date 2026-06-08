/// Helpers for nullable epoch-millis <-> DateTime conversions used by models.
DateTime? dtFromEpoch(Object? value) =>
    value == null ? null : DateTime.fromMillisecondsSinceEpoch(value as int);

int? epochFromDt(DateTime? value) => value?.millisecondsSinceEpoch;

class Scheme {
  final String id;
  final String schemeName;
  final String? schemeType;
  final String? department;
  final String? division;
  final String? subDivision;
  final String? financialYear;
  final String? aaNumber;
  final DateTime? aaDate;
  final String? tsNumber;
  final DateTime? tsDate;
  final String? workOrderNumber;
  final DateTime? workOrderDate;
  final String? tenderNumber;
  final String? contractorId;
  final String? contractorAddress;
  final double tenderValue;
  final double estimatedCost;
  final String? location;
  final String? village;
  final String? block;
  final String? district;
  final double? latitude;
  final double? longitude;
  final DateTime? startDate;
  final DateTime? targetCompletionDate;
  final String? fundingSource;
  final String? remarks;
  final String status;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Scheme({
    required this.id,
    required this.schemeName,
    this.schemeType,
    this.department,
    this.division,
    this.subDivision,
    this.financialYear,
    this.aaNumber,
    this.aaDate,
    this.tsNumber,
    this.tsDate,
    this.workOrderNumber,
    this.workOrderDate,
    this.tenderNumber,
    this.contractorId,
    this.contractorAddress,
    this.tenderValue = 0,
    this.estimatedCost = 0,
    this.location,
    this.village,
    this.block,
    this.district,
    this.latitude,
    this.longitude,
    this.startDate,
    this.targetCompletionDate,
    this.fundingSource,
    this.remarks,
    this.status = 'Planned',
    this.archived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Scheme copyWith({
    String? schemeName,
    String? schemeType,
    String? department,
    String? division,
    String? subDivision,
    String? financialYear,
    String? aaNumber,
    DateTime? aaDate,
    String? tsNumber,
    DateTime? tsDate,
    String? workOrderNumber,
    DateTime? workOrderDate,
    String? tenderNumber,
    String? contractorId,
    String? contractorAddress,
    double? tenderValue,
    double? estimatedCost,
    String? location,
    String? village,
    String? block,
    String? district,
    double? latitude,
    double? longitude,
    DateTime? startDate,
    DateTime? targetCompletionDate,
    String? fundingSource,
    String? remarks,
    String? status,
    bool? archived,
    DateTime? updatedAt,
  }) {
    return Scheme(
      id: id,
      schemeName: schemeName ?? this.schemeName,
      schemeType: schemeType ?? this.schemeType,
      department: department ?? this.department,
      division: division ?? this.division,
      subDivision: subDivision ?? this.subDivision,
      financialYear: financialYear ?? this.financialYear,
      aaNumber: aaNumber ?? this.aaNumber,
      aaDate: aaDate ?? this.aaDate,
      tsNumber: tsNumber ?? this.tsNumber,
      tsDate: tsDate ?? this.tsDate,
      workOrderNumber: workOrderNumber ?? this.workOrderNumber,
      workOrderDate: workOrderDate ?? this.workOrderDate,
      tenderNumber: tenderNumber ?? this.tenderNumber,
      contractorId: contractorId ?? this.contractorId,
      contractorAddress: contractorAddress ?? this.contractorAddress,
      tenderValue: tenderValue ?? this.tenderValue,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      location: location ?? this.location,
      village: village ?? this.village,
      block: block ?? this.block,
      district: district ?? this.district,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      startDate: startDate ?? this.startDate,
      targetCompletionDate: targetCompletionDate ?? this.targetCompletionDate,
      fundingSource: fundingSource ?? this.fundingSource,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      archived: archived ?? this.archived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'scheme_name': schemeName,
        'scheme_type': schemeType,
        'department': department,
        'division': division,
        'sub_division': subDivision,
        'financial_year': financialYear,
        'aa_number': aaNumber,
        'aa_date': epochFromDt(aaDate),
        'ts_number': tsNumber,
        'ts_date': epochFromDt(tsDate),
        'work_order_number': workOrderNumber,
        'work_order_date': epochFromDt(workOrderDate),
        'tender_number': tenderNumber,
        'contractor_id': contractorId,
        'contractor_address': contractorAddress,
        'tender_value': tenderValue,
        'estimated_cost': estimatedCost,
        'location': location,
        'village': village,
        'block': block,
        'district': district,
        'latitude': latitude,
        'longitude': longitude,
        'start_date': epochFromDt(startDate),
        'target_completion_date': epochFromDt(targetCompletionDate),
        'funding_source': fundingSource,
        'remarks': remarks,
        'status': status,
        'archived': archived ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Scheme.fromMap(Map<String, Object?> map) => Scheme(
        id: map['id'] as String,
        schemeName: map['scheme_name'] as String,
        schemeType: map['scheme_type'] as String?,
        department: map['department'] as String?,
        division: map['division'] as String?,
        subDivision: map['sub_division'] as String?,
        financialYear: map['financial_year'] as String?,
        aaNumber: map['aa_number'] as String?,
        aaDate: dtFromEpoch(map['aa_date']),
        tsNumber: map['ts_number'] as String?,
        tsDate: dtFromEpoch(map['ts_date']),
        workOrderNumber: map['work_order_number'] as String?,
        workOrderDate: dtFromEpoch(map['work_order_date']),
        tenderNumber: map['tender_number'] as String?,
        contractorId: map['contractor_id'] as String?,
        contractorAddress: map['contractor_address'] as String?,
        tenderValue: (map['tender_value'] as num?)?.toDouble() ?? 0,
        estimatedCost: (map['estimated_cost'] as num?)?.toDouble() ?? 0,
        location: map['location'] as String?,
        village: map['village'] as String?,
        block: map['block'] as String?,
        district: map['district'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        startDate: dtFromEpoch(map['start_date']),
        targetCompletionDate: dtFromEpoch(map['target_completion_date']),
        fundingSource: map['funding_source'] as String?,
        remarks: map['remarks'] as String?,
        status: (map['status'] as String?) ?? 'Planned',
        archived: (map['archived'] as int? ?? 0) == 1,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );
}
