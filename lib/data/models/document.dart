class SchemeDocument {
  final String id;
  final String? schemeId;
  final String? category;
  final String name;
  final String? filePath;
  final int? fileSize;
  final DateTime uploadedAt;

  const SchemeDocument({
    required this.id,
    this.schemeId,
    this.category,
    required this.name,
    this.filePath,
    this.fileSize,
    required this.uploadedAt,
  });

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'scheme_id': schemeId,
        'category': category,
        'name': name,
        'file_path': filePath,
        'file_size': fileSize,
        'uploaded_at': uploadedAt.millisecondsSinceEpoch,
      };

  factory SchemeDocument.fromMap(Map<String, Object?> map) => SchemeDocument(
        id: map['id'] as String,
        schemeId: map['scheme_id'] as String?,
        category: map['category'] as String?,
        name: map['name'] as String,
        filePath: map['file_path'] as String?,
        fileSize: map['file_size'] as int?,
        uploadedAt:
            DateTime.fromMillisecondsSinceEpoch(map['uploaded_at'] as int),
      );
}
