class RecommendationData {
  final String? waterRequired;
  final double? waterAmountLiters;
  final String? pesticide;
  final String? fertilizerGuidance;
  final String? nitrogenAdvice;
  final String? priority;
  final int? recheckInHours;

  RecommendationData({
    this.waterRequired,
    this.waterAmountLiters,
    this.pesticide,
    this.fertilizerGuidance,
    this.nitrogenAdvice,
    this.priority,
    this.recheckInHours,
  });

  factory RecommendationData.fromJson(Map<String, dynamic> json) {
    return RecommendationData(
      waterRequired: json['water_required'],
      waterAmountLiters: json['water_amount_liters']?.toDouble(),
      pesticide: json['pesticide'],
      fertilizerGuidance: json['fertilizer_guidance'],
      nitrogenAdvice: json['nitrogen_advice'],
      priority: json['priority'],
      recheckInHours: json['recheck_in_hours'],
    );
  }
}

class GridCell {
  final String gridId;
  final String? crop;
  final String disease;
  final double? confidence;
  final double severity;
  final String riskLevel;
  final String statusColor;
  final double? temperature;
  final double? humidity;
  final double? soilMoisture;
  final int? cropAgeDays;
  final RecommendationData? recommendation;
  final String? lastUpdated;

  GridCell({
    required this.gridId,
    this.crop,
    required this.disease,
    this.confidence,
    required this.severity,
    required this.riskLevel,
    required this.statusColor,
    this.temperature,
    this.humidity,
    this.soilMoisture,
    this.cropAgeDays,
    this.recommendation,
    this.lastUpdated,
  });

  factory GridCell.fromJson(Map<String, dynamic> json) {
    return GridCell(
      gridId: json['grid_id'],
      crop: json['crop'],
      disease: json['disease'] ?? 'Unscanned',
      confidence: json['confidence']?.toDouble(),
      severity: json['severity']?.toDouble() ?? 0.0,
      riskLevel: json['risk_level'] ?? 'Unknown',
      statusColor: json['status_color'] ?? 'gray',
      temperature: json['temperature']?.toDouble(),
      humidity: json['humidity']?.toDouble(),
      soilMoisture: json['soil_moisture']?.toDouble(),
      cropAgeDays: json['crop_age_days'],
      recommendation: json['recommendation'] != null ? RecommendationData.fromJson(json['recommendation']) : null,
      lastUpdated: json['last_updated'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grid_id': gridId,
      'crop': crop,
      'disease': disease,
      'confidence': confidence,
      'severity': severity,
      'risk_level': riskLevel,
      'status_color': statusColor,
      'temperature': temperature,
      'humidity': humidity,
      'soil_moisture': soilMoisture,
      'crop_age_days': cropAgeDays,
      'recommendation': recommendation?.toJson(),
      'last_updated': lastUpdated,
    };
  }
}

extension RecommendationDataJson on RecommendationData {
  Map<String, dynamic> toJson() {
    return {
      'water_required': waterRequired,
      'water_amount_liters': waterAmountLiters,
      'pesticide': pesticide,
      'fertilizer_guidance': fertilizerGuidance,
      'nitrogen_advice': nitrogenAdvice,
      'priority': priority,
      'recheck_in_hours': recheckInHours,
    };
  }
}

