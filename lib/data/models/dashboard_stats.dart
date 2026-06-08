class DashboardStats {
  final int totalSchemes;
  final int ongoingSchemes;
  final int completedSchemes;
  final int delayedSchemes;
  final double totalTenderValue;
  final int totalBillsGenerated;
  final double totalPaidAmount;
  final double totalBilledAmount;
  final double physicalProgress;
  final double financialProgress;

  final Map<String, int> statusDistribution;
  final Map<String, double> monthlyExpenditure;
  final Map<String, double> contractorWorkValue;
  final Map<String, int> departmentSchemeCount;

  const DashboardStats({
    this.totalSchemes = 0,
    this.ongoingSchemes = 0,
    this.completedSchemes = 0,
    this.delayedSchemes = 0,
    this.totalTenderValue = 0,
    this.totalBillsGenerated = 0,
    this.totalPaidAmount = 0,
    this.totalBilledAmount = 0,
    this.physicalProgress = 0,
    this.financialProgress = 0,
    this.statusDistribution = const <String, int>{},
    this.monthlyExpenditure = const <String, double>{},
    this.contractorWorkValue = const <String, double>{},
    this.departmentSchemeCount = const <String, int>{},
  });

  double get balanceLiability => totalBilledAmount - totalPaidAmount;
}
