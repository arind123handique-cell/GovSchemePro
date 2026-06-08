import 'scheme.dart' show dtFromEpoch, epochFromDt;

class Bill {
  final String id;
  final String schemeId;
  final String? contractorId;
  final String? billNumber;
  final String? billType;
  final DateTime? billDate;
  final double grossAmount;
  final double previousAmount;
  final double netAmount;
  final double securityDeposit;
  final double gst;
  final double labourCess;
  final double incomeTax;
  final double royalty;
  final double otherRecoveries;
  final double netPayable;
  final String status;
  final String? remarks;
  final DateTime createdAt;

  const Bill({
    required this.id,
    required this.schemeId,
    this.contractorId,
    this.billNumber,
    this.billType,
    this.billDate,
    this.grossAmount = 0,
    this.previousAmount = 0,
    this.netAmount = 0,
    this.securityDeposit = 0,
    this.gst = 0,
    this.labourCess = 0,
    this.incomeTax = 0,
    this.royalty = 0,
    this.otherRecoveries = 0,
    this.netPayable = 0,
    this.status = 'Draft',
    this.remarks,
    required this.createdAt,
  });

  double get totalDeductions =>
      securityDeposit + gst + labourCess + incomeTax + royalty + otherRecoveries;

  Bill copyWith({
    String? contractorId,
    String? billNumber,
    String? billType,
    DateTime? billDate,
    double? grossAmount,
    double? previousAmount,
    double? netAmount,
    double? securityDeposit,
    double? gst,
    double? labourCess,
    double? incomeTax,
    double? royalty,
    double? otherRecoveries,
    double? netPayable,
    String? status,
    String? remarks,
  }) {
    return Bill(
      id: id,
      schemeId: schemeId,
      contractorId: contractorId ?? this.contractorId,
      billNumber: billNumber ?? this.billNumber,
      billType: billType ?? this.billType,
      billDate: billDate ?? this.billDate,
      grossAmount: grossAmount ?? this.grossAmount,
      previousAmount: previousAmount ?? this.previousAmount,
      netAmount: netAmount ?? this.netAmount,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      gst: gst ?? this.gst,
      labourCess: labourCess ?? this.labourCess,
      incomeTax: incomeTax ?? this.incomeTax,
      royalty: royalty ?? this.royalty,
      otherRecoveries: otherRecoveries ?? this.otherRecoveries,
      netPayable: netPayable ?? this.netPayable,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'scheme_id': schemeId,
        'contractor_id': contractorId,
        'bill_number': billNumber,
        'bill_type': billType,
        'bill_date': epochFromDt(billDate),
        'gross_amount': grossAmount,
        'previous_amount': previousAmount,
        'net_amount': netAmount,
        'security_deposit': securityDeposit,
        'gst': gst,
        'labour_cess': labourCess,
        'income_tax': incomeTax,
        'royalty': royalty,
        'other_recoveries': otherRecoveries,
        'net_payable': netPayable,
        'status': status,
        'remarks': remarks,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Bill.fromMap(Map<String, Object?> map) => Bill(
        id: map['id'] as String,
        schemeId: map['scheme_id'] as String,
        contractorId: map['contractor_id'] as String?,
        billNumber: map['bill_number'] as String?,
        billType: map['bill_type'] as String?,
        billDate: dtFromEpoch(map['bill_date']),
        grossAmount: (map['gross_amount'] as num?)?.toDouble() ?? 0,
        previousAmount: (map['previous_amount'] as num?)?.toDouble() ?? 0,
        netAmount: (map['net_amount'] as num?)?.toDouble() ?? 0,
        securityDeposit: (map['security_deposit'] as num?)?.toDouble() ?? 0,
        gst: (map['gst'] as num?)?.toDouble() ?? 0,
        labourCess: (map['labour_cess'] as num?)?.toDouble() ?? 0,
        incomeTax: (map['income_tax'] as num?)?.toDouble() ?? 0,
        royalty: (map['royalty'] as num?)?.toDouble() ?? 0,
        otherRecoveries: (map['other_recoveries'] as num?)?.toDouble() ?? 0,
        netPayable: (map['net_payable'] as num?)?.toDouble() ?? 0,
        status: (map['status'] as String?) ?? 'Draft',
        remarks: map['remarks'] as String?,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}

class BillItem {
  final String id;
  final String billId;
  final String? boqItemId;
  final String? itemNo;
  final String? description;
  final String? unit;
  final double quantity;
  final double rate;
  final double amount;
  final int sortOrder;

  const BillItem({
    required this.id,
    required this.billId,
    this.boqItemId,
    this.itemNo,
    this.description,
    this.unit,
    this.quantity = 0,
    this.rate = 0,
    this.amount = 0,
    this.sortOrder = 0,
  });

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'bill_id': billId,
        'boq_item_id': boqItemId,
        'item_no': itemNo,
        'description': description,
        'unit': unit,
        'quantity': quantity,
        'rate': rate,
        'amount': amount,
        'sort_order': sortOrder,
      };

  factory BillItem.fromMap(Map<String, Object?> map) => BillItem(
        id: map['id'] as String,
        billId: map['bill_id'] as String,
        boqItemId: map['boq_item_id'] as String?,
        itemNo: map['item_no'] as String?,
        description: map['description'] as String?,
        unit: map['unit'] as String?,
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
        rate: (map['rate'] as num?)?.toDouble() ?? 0,
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        sortOrder: (map['sort_order'] as int?) ?? 0,
      );
}
