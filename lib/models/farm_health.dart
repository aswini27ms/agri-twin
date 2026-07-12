class FarmHealth {
  final double farmHealthScore;
  final int gridsScanned;
  final int gridsTotal;
  final int infectedGrids;
  final double averageRisk;
  final double? averageSoilMoisture;
  final Map<String, dynamic> breakdown;

  FarmHealth({
    required this.farmHealthScore,
    required this.gridsScanned,
    required this.gridsTotal,
    required this.infectedGrids,
    required this.averageRisk,
    this.averageSoilMoisture,
    required this.breakdown,
  });

  factory FarmHealth.fromJson(Map<String, dynamic> json) {
    return FarmHealth(
      farmHealthScore: json['farm_health_score']?.toDouble() ?? 100.0,
      gridsScanned: json['grids_scanned'] ?? 0,
      gridsTotal: json['grids_total'] ?? 0,
      infectedGrids: json['infected_grids'] ?? 0,
      averageRisk: json['average_risk']?.toDouble() ?? 0.0,
      averageSoilMoisture: json['average_soil_moisture']?.toDouble(),
      breakdown: json['breakdown'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farm_health_score': farmHealthScore,
      'grids_scanned': gridsScanned,
      'grids_total': gridsTotal,
      'infected_grids': infectedGrids,
      'average_risk': averageRisk,
      'average_soil_moisture': averageSoilMoisture,
      'breakdown': breakdown,
    };
  }
}
