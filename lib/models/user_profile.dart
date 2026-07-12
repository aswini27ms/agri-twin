class UserProfile {
  final String userName;
  final String farmName;
  final String location;

  UserProfile({
    required this.userName,
    required this.farmName,
    required this.location,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userName: json['userName'] as String? ?? 'Farmer',
      farmName: json['farmName'] as String? ?? 'Demo Farm 1',
      location: json['location'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'farmName': farmName,
      'location': location,
    };
  }

  UserProfile copyWith({
    String? userName,
    String? farmName,
    String? location,
  }) {
    return UserProfile(
      userName: userName ?? this.userName,
      farmName: farmName ?? this.farmName,
      location: location ?? this.location,
    );
  }
}
