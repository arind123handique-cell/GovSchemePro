class BoqItem {
  final String id;
  final String schemeId;
  final String? itemNo;
  final String description;
  final String? unit;
  final double quantity;
  final double rate;
  final double amount;
  final String? category;
  final String? subCategory;
  final String? remarks;
  final int sortOrder;

  const BoqItem({
    required this.id,
    required this.schemeId,
    this.itemNo,
    required this.description,
    this.unit,
    this.quantity = 0,
    this.rate = 0,
    this.amount = 0,
    this.category,
    this.subCategory,
    this.remarks,
    this.sortOrder = 0,
  });

  double get computedAmount => quantity * rate;

  BoqItem copyWith({
    String? itemNo,
    String? description,
    String? unit,
    double? quantity,
    double? rate,
    double? amount,
    String? category,
    String? subCategory,
    String? remarks,
    int? sortOrder,
  }) {
    return BoqItem(
      id: id,
      schemeId: schemeId,
      itemNo: itemNo ?? this.itemNo,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      remarks: remarks ?? this.remarks,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'scheme_id': schemeId,
        'item_no': itemNo,
        'description': description,
        'unit': unit,
        'quantity': quantity,
        'rate': rate,
        'amount': amount,
        'category': category,
        'sub_category': subCategory,
        'remarks': remarks,
        'sort_order': sortOrder,
      };

  factory BoqItem.fromMap(Map<String, Object?> map) => BoqItem(
        id: map['id'] as String,
        schemeId: map['scheme_id'] as String,
        itemNo: map['item_no'] as String?,
        description: map['description'] as String,
        unit: map['unit'] as String?,
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
        rate: (map['rate'] as num?)?.toDouble() ?? 0,
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        category: map['category'] as String?,
        subCategory: map['sub_category'] as String?,
        remarks: map['remarks'] as String?,
        sortOrder: (map['sort_order'] as int?) ?? 0,
      );
}
