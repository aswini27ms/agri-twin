class SensorData {
  final double? temperature;
  final double? humidity;
  final double? soilMoisture;
  final String? lastUpdated;

  SensorData({
    this.temperature,
    this.humidity,
    this.soilMoisture,
    this.lastUpdated,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: json['temperature']?.toDouble(),
      humidity: json['humidity']?.toDouble(),
      soilMoisture: json['soil_moisture']?.toDouble(),
      lastUpdated: json['last_updated'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'soil_moisture': soilMoisture,
      'last_updated': lastUpdated,
    };
  }
}
