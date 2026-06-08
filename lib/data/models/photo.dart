class SchemePhoto {
  final String id;
  final String schemeId;
  final String? billId;
  final String? stage;
  final String? caption;
  final String? filePath;
  final double? latitude;
  final double? longitude;
  final DateTime takenAt;

  const SchemePhoto({
    required this.id,
    required this.schemeId,
    this.billId,
    this.stage,
    this.caption,
    this.filePath,
    this.latitude,
    this.longitude,
    required this.takenAt,
  });

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'scheme_id': schemeId,
        'bill_id': billId,
        'stage': stage,
        'caption': caption,
        'file_path': filePath,
        'latitude': latitude,
        'longitude': longitude,
        'taken_at': takenAt.millisecondsSinceEpoch,
      };

  factory SchemePhoto.fromMap(Map<String, Object?> map) => SchemePhoto(
        id: map['id'] as String,
        schemeId: map['scheme_id'] as String,
        billId: map['bill_id'] as String?,
        stage: map['stage'] as String?,
        caption: map['caption'] as String?,
        filePath: map['file_path'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        takenAt: DateTime.fromMillisecondsSinceEpoch(map['taken_at'] as int),
      );
}
