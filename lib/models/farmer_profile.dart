class FarmerProfile {
  final String name;
  final String phoneOrId;
  final String pin;

  FarmerProfile({required this.name, required this.phoneOrId, required this.pin});

  Map<String, dynamic> toJson() => {
    'name': name,
    'phoneOrId': phoneOrId,
    'pin': pin,
  };

  factory FarmerProfile.fromJson(Map<String, dynamic> json) => FarmerProfile(
    name: json['name'] as String,
    phoneOrId: json['phoneOrId'] as String,
    pin: json['pin'] as String,
  );
}
