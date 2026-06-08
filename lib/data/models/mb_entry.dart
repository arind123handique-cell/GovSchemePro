import 'scheme.dart' show dtFromEpoch, epochFromDt;

class MbEntry {
  final String id;
  final String schemeId;
  final String? boqItemId;
  final String? mbNumber;
  final String? pageNumber;
  final DateTime? entryDate;
  final String? itemNumber;
  final String? description;
  final String? location;
  final double measuredQuantity;
  final String? unit;
  final String? remarks;
  final String? engineer;
  final String? photoPath;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const MbEntry({
    required this.id,
    required this.schemeId,
    this.boqItemId,
    this.mbNumber,
    this.pageNumber,
    this.entryDate,
    this.itemNumber,
    this.description,
    this.location,
    this.measuredQuantity = 0,
    this.unit,
    this.remarks,
    this.engineer,
    this.photoPath,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  MbEntry copyWith({
    String? boqItemId,
    String? mbNumber,
    String? pageNumber,
    DateTime? entryDate,
    String? itemNumber,
    String? description,
    String? location,
    double? measuredQuantity,
    String? unit,
    String? remarks,
    String? engineer,
    String? photoPath,
    double? latitude,
    double? longitude,
  }) {
    return MbEntry(
      id: id,
      schemeId: schemeId,
      boqItemId: boqItemId ?? this.boqItemId,
      mbNumber: mbNumber ?? this.mbNumber,
      pageNumber: pageNumber ?? this.pageNumber,
      entryDate: entryDate ?? this.entryDate,
      itemNumber: itemNumber ?? this.itemNumber,
      description: description ?? this.description,
      location: location ?? this.location,
      measuredQuantity: measuredQuantity ?? this.measuredQuantity,
      unit: unit ?? this.unit,
      remarks: remarks ?? this.remarks,
      engineer: engineer ?? this.engineer,
      photoPath: photoPath ?? this.photoPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'scheme_id': schemeId,
        'boq_item_id': boqItemId,
        'mb_number': mbNumber,
        'page_number': pageNumber,
        'entry_date': epochFromDt(entryDate),
        'item_number': itemNumber,
        'description': description,
        'location': location,
        'measured_quantity': measuredQuantity,
        'unit': unit,
        'remarks': remarks,
        'engineer': engineer,
        'photo_path': photoPath,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory MbEntry.fromMap(Map<String, Object?> map) => MbEntry(
        id: map['id'] as String,
        schemeId: map['scheme_id'] as String,
        boqItemId: map['boq_item_id'] as String?,
        mbNumber: map['mb_number'] as String?,
        pageNumber: map['page_number'] as String?,
        entryDate: dtFromEpoch(map['entry_date']),
        itemNumber: map['item_number'] as String?,
        description: map['description'] as String?,
        location: map['location'] as String?,
        measuredQuantity: (map['measured_quantity'] as num?)?.toDouble() ?? 0,
        unit: map['unit'] as String?,
        remarks: map['remarks'] as String?,
        engineer: map['engineer'] as String?,
        photoPath: map['photo_path'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
