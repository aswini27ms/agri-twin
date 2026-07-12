class SoilData {
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double moisture;
  final double ph;
  final double organicMatter;
  final double zinc;
  final double iron;
  final String source; // "sensor" | "simulated"
  final DateTime timestamp;

  SoilData({
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.moisture,
    this.ph = 6.8,
    this.organicMatter = 3.2,
    this.zinc = 1.2,
    this.iron = 4.5,
    this.source = 'simulated',
    required this.timestamp,
  });

  bool get isLive => source == 'sensor';

  Map<String, dynamic> toJson() => {
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'moisture': moisture,
        'ph': ph,
        'organic_matter': organicMatter,
        'zinc': zinc,
        'iron': iron,
        'source': source,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SoilData.fromJson(Map<String, dynamic> json) {
    final rawTimestamp = json['timestamp'];
    DateTime parsedTime;
    if (rawTimestamp is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
    } else if (rawTimestamp is String) {
      parsedTime = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    double _num(dynamic v, double fallback) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    return SoilData(
      nitrogen: _num(json['nitrogen'], 0),
      phosphorus: _num(json['phosphorus'], 0),
      potassium: _num(json['potassium'], 0),
      moisture: _num(json['moisture'], 0),
      ph: _num(json['ph'], 6.8),
      organicMatter: _num(json['organic_matter'], 3.2),
      zinc: _num(json['zinc'], 1.2),
      iron: _num(json['iron'], 4.5),
      source: json['source']?.toString() ?? 'simulated',
      timestamp: parsedTime,
    );
  }
}