class Field {
  final String fieldId;
  final String name;

  Field({required this.fieldId, required this.name});

  Map<String, dynamic> toJson() => {
    'fieldId': fieldId,
    'name': name,
  };

  factory Field.fromJson(Map<String, dynamic> json) {
    final rawId = json['fieldId'] ?? json['id'];
    return Field(
      fieldId: rawId?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
    );
  }
}
