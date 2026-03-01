class NetWorthSnapshot {
  const NetWorthSnapshot({
    required this.date,
    required this.netWorth,
    required this.totalAssets,
    required this.totalLiabilities,
  });

  final DateTime date;
  final double netWorth;
  final double totalAssets;
  final double totalLiabilities;
}
