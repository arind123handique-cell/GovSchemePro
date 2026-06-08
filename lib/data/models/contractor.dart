class Contractor {
  final String id;
  final String name;
  final String? address;
  final String? gstNumber;
  final String? panNumber;
  final String? phone;
  final String? email;
  final String? bankAccount;
  final String? ifsc;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Contractor({
    required this.id,
    required this.name,
    this.address,
    this.gstNumber,
    this.panNumber,
    this.phone,
    this.email,
    this.bankAccount,
    this.ifsc,
    required this.createdAt,
    required this.updatedAt,
  });

  Contractor copyWith({
    String? name,
    String? address,
    String? gstNumber,
    String? panNumber,
    String? phone,
    String? email,
    String? bankAccount,
    String? ifsc,
    DateTime? updatedAt,
  }) {
    return Contractor(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bankAccount: bankAccount ?? this.bankAccount,
      ifsc: ifsc ?? this.ifsc,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'address': address,
        'gst_number': gstNumber,
        'pan_number': panNumber,
        'phone': phone,
        'email': email,
        'bank_account': bankAccount,
        'ifsc': ifsc,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Contractor.fromMap(Map<String, Object?> map) => Contractor(
        id: map['id'] as String,
        name: map['name'] as String,
        address: map['address'] as String?,
        gstNumber: map['gst_number'] as String?,
        panNumber: map['pan_number'] as String?,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        bankAccount: map['bank_account'] as String?,
        ifsc: map['ifsc'] as String?,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );
}
