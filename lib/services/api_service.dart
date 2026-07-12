import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/sensor_data.dart';
import '../models/grid_cell.dart';
import '../models/farm_health.dart';
import '../models/village_alert.dart';
import 'cache_service.dart';

class ApiService {
  final Dio _dio;
  final CacheService _cacheService;

  ApiService(this._cacheService)
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 180),
          receiveTimeout: const Duration(seconds: 180),
        ));

  String get baseUrl => _cacheService.getBackendIP();

  // --- Sensor ---
  Future<SensorData?> getLatestSensor() async {
    try {
      final response = await _dio.get('$baseUrl/sensors/latest');
      final data = SensorData.fromJson(response.data);
      await _cacheService.cacheSensorData(data);
      return data;
    } catch (e) {
      return _cacheService.getCachedSensorData();
    }
  }

  // --- Digital Twin ---
  Future<List<GridCell>> getTwinState() async {
    try {
      final response = await _dio.get('$baseUrl/farm/twin');
      final Map<String, dynamic> gridDict = response.data['grid'];
      final List<GridCell> cells = gridDict.values.map((e) => GridCell.fromJson(e)).toList();
      await _cacheService.cacheTwinGrid(cells);
      return cells;
    } catch (e) {
      return _cacheService.getCachedTwinGrid();
    }
  }

  Future<FarmHealth?> getFarmHealth() async {
    try {
      final response = await _dio.get('$baseUrl/farm/health');
      final health = FarmHealth.fromJson(response.data);
      await _cacheService.cacheFarmHealth(health);
      return health;
    } catch (e) {
      return _cacheService.getCachedFarmHealth();
    }
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final response = await _dio.get('$baseUrl/farm/analytics');
    return response.data;
  }

  Future<List<dynamic>> getTimeline() async {
    final response = await _dio.get('$baseUrl/farm/timeline');
    return response.data['timeline'];
  }

  Future<List<dynamic>> getHealthHistory() async {
    final response = await _dio.get('$baseUrl/farm/health/history');
    return response.data['history'];
  }

  Future<Map<String, dynamic>> simulateTwin(int hours) async {
    final response = await _dio.get('$baseUrl/farm/simulate?hours=$hours');
    return response.data;
  }

  Future<Map<String, dynamic>> getCellNeighbors(String gridId) async {
    final response = await _dio.get('$baseUrl/farm/twin/cell/$gridId/neighbors');
    return response.data;
  }

  Future<Map<String, dynamic>> getCellDetails(String gridId) async {
    final response = await _dio.get('$baseUrl/farm/twin/cell/$gridId');
    return response.data;
  }

  Future<void> resetTwin() async {
    await _dio.post('$baseUrl/farm/twin/reset');
  }

  Future<Map<String, dynamic>> scanCrop(
      Uint8List imageBytes, 
      String filename,
      String gridId, 
      int cropAgeDays,
      {double? temperature, double? humidity, double? soilMoisture, double previousSeverity = 0.3}
  ) async {
    try {
      final formData = FormData.fromMap({
        'grid_id': gridId,
        'image': MultipartFile.fromBytes(imageBytes, filename: filename),
        'crop_age_days': cropAgeDays,
        'previous_severity': previousSeverity,
        if (temperature != null) 'temperature': temperature,
        if (humidity != null) 'humidity': humidity,
        if (soilMoisture != null) 'soil_moisture': soilMoisture,
      });

      final response = await _dio.post('$baseUrl/predict/scan', data: formData);
      return response.data;
    } catch (e) {
      throw Exception('Failed to scan crop. Ensure backend is reachable. $e');
    }
  }

  // --- Alerts ---
  Future<List<VillageAlert>> getVillageAlerts() async {
    try {
      final response = await _dio.get('$baseUrl/village/alerts');
      final List<dynamic> alertsData = response.data['alerts'];
      final List<VillageAlert> alerts = alertsData.map((e) => VillageAlert.fromJson(e)).toList();
      await _cacheService.cacheAlerts(alerts);
      return alerts;
    } catch (e) {
      return _cacheService.getCachedAlerts();
    }
  }

  Future<Map<String, dynamic>> getVillageSummary({double hours = 24}) async {
    try {
      final response = await _dio.get('$baseUrl/village/summary?hours=$hours');
      return response.data;
    } catch (e) {
      return {
        'narrative': 'Unable to fetch village summary. Please check your connection.',
        'stats': null,
      };
    }
  }

  // --- Chat & Explainability ---
  Future<List<Map<String, String>>> getChatHistory() async {
    try {
      final response = await _dio.get('$baseUrl/gemma/chat');
      final List<dynamic> historyData = response.data['history'];
      return historyData.map((e) => ({
        'role': e['role'].toString(),
        'text': e['message'].toString(),
      })).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String> sendChatMessage(String message, String? gridId) async {
    try {
      final response = await _dio.post(
        '$baseUrl/gemma/chat',
        data: {
          'message': message,
          'grid_id': gridId,
        },
        options: Options(validateStatus: (s) => s != null && s < 600),
      );

      if (response.statusCode == 200) {
        return response.data['reply'];
      }

      // Surface the backend's detail message for 503 / other errors
      final detail = response.data is Map
          ? (response.data['detail'] ?? 'Gemma is unavailable.')
          : 'Gemma returned status ${response.statusCode}.';
      throw Exception(detail);
    } on DioException catch (e) {
      // Network-level failure (no connection to backend at all)
      final msg = e.response?.data is Map
          ? (e.response!.data['detail'] ?? 'Cannot reach backend.')
          : 'Backend is unreachable. Is the server running?';
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> getGemmaStatus() async {
    try {
      final response = await _dio.get(
        '$baseUrl/gemma/status',
        options: Options(validateStatus: (s) => s != null && s < 600),
      );
      if (response.statusCode == 200) return Map<String, dynamic>.from(response.data);
      return {'ollama_running': false, 'gemma_ready': false};
    } catch (_) {
      return {'ollama_running': false, 'gemma_ready': false};
    }
  }

  Future<Map<String, dynamic>> getCellExplanation(String gridId) async {
    try {
      final response = await _dio.get('$baseUrl/gemma/explain/$gridId');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get explanation: $e');
    }
  }

  Future<Map<String, dynamic>> getYieldPrediction(String crop) async {
    try {
      final response = await _dio.get(
        '$baseUrl/predict/yield',
        queryParameters: {'crop': crop},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch yield prediction: $e');
    }
  }
}
