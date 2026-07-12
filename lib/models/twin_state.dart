class TwinState {
  final String fieldId;
  final int healthScore;
  final List<double> trendHistory;
  final String riskProjection;

  TwinState({
    required this.fieldId,
    required this.healthScore,
    required this.trendHistory,
    required this.riskProjection,
  });

  Map<String, dynamic> toJson() => {
    'fieldId': fieldId,
    'healthScore': healthScore,
    'trendHistory': trendHistory,
    'riskProjection': riskProjection,
  };

  factory TwinState.fromJson(Map<String, dynamic> json) {
    var history = json['trendHistory'];
    List<double> list = [];
    if (history is List) {
      list = history.map((e) => (e as num).toDouble()).toList();
    }
    return TwinState(
      fieldId: (json['fieldId'] ?? json['id'] ?? '').toString(),
      healthScore: (json['healthScore'] as num? ?? 0).toInt(),
      trendHistory: list,
      riskProjection: json['riskProjection'] as String? ?? 'No major risks detected',
    );
  }
}
