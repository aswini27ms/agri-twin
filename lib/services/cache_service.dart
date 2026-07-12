import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/sensor_data.dart';
import '../models/grid_cell.dart';
import '../models/farm_health.dart';
import '../models/village_alert.dart';
import '../models/user_profile.dart';

class CacheService {
  static const String _sensorBox = 'sensor_cache';
  static const String _twinBox = 'twin_cache';
  static const String _healthBox = 'health_cache';
  static const String _alertsBox = 'alerts_cache';
  static const String _settingsBox = 'settings_cache';

  static const String _tasksBox = 'tasks_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_sensorBox);
    await Hive.openBox(_twinBox);
    await Hive.openBox(_healthBox);
    await Hive.openBox(_alertsBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_tasksBox);
  }

  // --- Settings ---
  Future<void> saveBackendIP(String ip) async {
    final box = Hive.box(_settingsBox);
    await box.put('backend_ip', ip);
  }

  String getBackendIP() {
    final box = Hive.box(_settingsBox);
    return box.get('backend_ip', defaultValue: 'http://127.0.0.1:8000') as String;
  }

  // --- User Profile ---
  Future<void> saveUserProfile(UserProfile profile) async {
    final box = Hive.box(_settingsBox);
    await box.put('userProfile', profile.toJson());
  }

  UserProfile? getUserProfile() {
    final box = Hive.box(_settingsBox);
    final data = box.get('userProfile');
    if (data != null) {
      return UserProfile.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  // --- Locale Settings ---
  Future<void> saveLanguage(String languageCode) async {
    final box = Hive.box(_settingsBox);
    await box.put('language_code', languageCode);
  }

  String getLanguage() {
    final box = Hive.box(_settingsBox);
    return box.get('language_code', defaultValue: 'en') as String;
  }

  // --- Sensor Data ---
  Future<void> cacheSensorData(SensorData data) async {
    final box = Hive.box(_sensorBox);
    await box.put('latest', jsonEncode(data.toJson()));
  }

  SensorData? getCachedSensorData() {
    final box = Hive.box(_sensorBox);
    final raw = box.get('latest');
    if (raw == null) return null;
    try {
      return SensorData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // --- Twin State (Grid Cells) ---
  Future<void> cacheTwinGrid(List<GridCell> cells) async {
    final box = Hive.box(_twinBox);
    final list = cells.map((e) => jsonEncode(e.toJson())).toList();
    await box.put('grid', list);
  }

  List<GridCell> getCachedTwinGrid() {
    final box = Hive.box(_twinBox);
    final raw = box.get('grid') as List<dynamic>?;
    if (raw == null) return [];
    try {
      return raw.map((e) => GridCell.fromJson(jsonDecode(e as String))).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Farm Health ---
  Future<void> cacheFarmHealth(FarmHealth health) async {
    final box = Hive.box(_healthBox);
    await box.put('latest', jsonEncode(health.toJson()));
  }

  FarmHealth? getCachedFarmHealth() {
    final box = Hive.box(_healthBox);
    final raw = box.get('latest');
    if (raw == null) return null;
    try {
      return FarmHealth.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // --- Alerts ---
  Future<void> cacheAlerts(List<VillageAlert> alerts) async {
    final box = Hive.box(_alertsBox);
    final list = alerts.map((e) => jsonEncode(e.toJson())).toList();
    await box.put('alerts', list);
  }

  List<VillageAlert> getCachedAlerts() {
    final box = Hive.box(_alertsBox);
    final raw = box.get('alerts') as List<dynamic>?;
    if (raw == null) return [];
    try {
      return raw.map((e) => VillageAlert.fromJson(jsonDecode(e as String))).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Tasks ---
  Future<void> saveTasks(List<Map<String, dynamic>> tasks) async {
    final box = Hive.box(_tasksBox);
    await box.put('tasks_list', jsonEncode(tasks));
  }

  List<Map<String, dynamic>> getTasks() {
    final box = Hive.box(_tasksBox);
    final str = box.get('tasks_list') as String?;
    if (str == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(str));
  }
}
