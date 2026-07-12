class VillageAlert {
  final int id;
  final String villageId;
  final String deviceId;
  final String farmName;
  final String gridId;
  final String? crop;
  final String disease;
  final double severity;
  final String riskLevel;
  final double confidencePct;
  final double? temperature;
  final double? humidity;
  final double? soilMoisture;
  final double timestamp;

  VillageAlert({
    required this.id,
    required this.villageId,
    required this.deviceId,
    required this.farmName,
    required this.gridId,
    this.crop,
    required this.disease,
    required this.severity,
    required this.riskLevel,
    required this.confidencePct,
    this.temperature,
    this.humidity,
    this.soilMoisture,
    required this.timestamp,
  });

  factory VillageAlert.fromJson(Map<String, dynamic> json) {
    return VillageAlert(
      id: json['id'],
      villageId: json['village_id'] ?? '',
      deviceId: json['device_id'] ?? '',
      farmName: json['farm_name'] ?? '',
      gridId: json['grid_id'] ?? '',
      crop: json['crop'],
      disease: json['disease'] ?? '',
      severity: json['severity']?.toDouble() ?? 0.0,
      riskLevel: json['risk_level'] ?? '',
      confidencePct: json['confidence_pct']?.toDouble() ?? 0.0,
      temperature: json['temperature']?.toDouble(),
      humidity: json['humidity']?.toDouble(),
      soilMoisture: json['soil_moisture']?.toDouble(),
      timestamp: json['timestamp']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'village_id': villageId,
      'device_id': deviceId,
      'farm_name': farmName,
      'grid_id': gridId,
      'crop': crop,
      'disease': disease,
      'severity': severity,
      'risk_level': riskLevel,
      'confidence_pct': confidencePct,
      'temperature': temperature,
      'humidity': humidity,
      'soil_moisture': soilMoisture,
      'timestamp': timestamp,
    };
  }
}
