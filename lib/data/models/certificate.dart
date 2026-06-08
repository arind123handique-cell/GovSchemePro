import 'scheme.dart' show dtFromEpoch, epochFromDt;

class Certificate {
  final String id;
  final String schemeId;
  final String? type;
  final String? title;
  final String? body;
  final DateTime? issuedDate;
  final String? officerName;
  final DateTime createdAt;

  const Certificate({
    required this.id,
    required this.schemeId,
    this.type,
    this.title,
    this.body,
    this.issuedDate,
    this.officerName,
    required this.createdAt,
  });

  Certificate copyWith({
    String? type,
    String? title,
    String? body,
    DateTime? issuedDate,
    String? officerName,
  }) {
    return Certificate(
      id: id,
      schemeId: schemeId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      issuedDate: issuedDate ?? this.issuedDate,
      officerName: officerName ?? this.officerName,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'scheme_id': schemeId,
        'type': type,
        'title': title,
        'body': body,
        'issued_date': epochFromDt(issuedDate),
        'officer_name': officerName,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Certificate.fromMap(Map<String, Object?> map) => Certificate(
        id: map['id'] as String,
        schemeId: map['scheme_id'] as String,
        type: map['type'] as String?,
        title: map['title'] as String?,
        body: map['body'] as String?,
        issuedDate: dtFromEpoch(map['issued_date']),
        officerName: map['officer_name'] as String?,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
