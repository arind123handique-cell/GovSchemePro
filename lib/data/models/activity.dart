class Activity {
  final String id;
  final String? schemeId;
  final String? type;
  final String? description;
  final DateTime createdAt;

  const Activity({
    required this.id,
    this.schemeId,
    this.type,
    this.description,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'scheme_id': schemeId,
        'type': type,
        'description': description,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Activity.fromMap(Map<String, Object?> map) => Activity(
        id: map['id'] as String,
        schemeId: map['scheme_id'] as String?,
        type: map['type'] as String?,
        description: map['description'] as String?,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
