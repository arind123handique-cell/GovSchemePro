/// Computed financial / physical progress for a scheme.
class SchemeProgress {
  final double tenderValue;
  final double boqTotal;
  final double executedValue;
  final double billedNet;
  final double paidAmount;

  const SchemeProgress({
    this.tenderValue = 0,
    this.boqTotal = 0,
    this.executedValue = 0,
    this.billedNet = 0,
    this.paidAmount = 0,
  });

  /// Executed quantity value / BOQ value * 100 (capped at 100).
  double get physicalPercent {
    if (boqTotal <= 0) return 0;
    return (executedValue / boqTotal * 100).clamp(0, 100).toDouble();
  }

  /// Net billed amount / tender value * 100 (capped at 100).
  double get financialPercent {
    if (tenderValue <= 0) return 0;
    return (billedNet / tenderValue * 100).clamp(0, 100).toDouble();
  }

  double get balanceValue => tenderValue - billedNet;

  double get balanceLiability => billedNet - paidAmount;
}
