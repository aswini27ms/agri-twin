import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/farmer_profile.dart';
import 'dart:convert';

class AuthService {
  final _secureStorage = const FlutterSecureStorage();
  static const _profileKey = 'farmer_profile';
  static const _sessionKey = 'is_logged_in';

  Future<void> saveProfile(FarmerProfile profile) async {
    await _secureStorage.write(key: _profileKey, value: jsonEncode(profile.toJson()));
    await _secureStorage.write(key: _sessionKey, value: 'true');
  }

  Future<FarmerProfile?> getProfile() async {
    final data = await _secureStorage.read(key: _profileKey);
    if (data == null) return null;
    try {
      return FarmerProfile.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final value = await _secureStorage.read(key: _sessionKey);
    return value == 'true';
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _profileKey);
    await _secureStorage.delete(key: _sessionKey);
  }
}
