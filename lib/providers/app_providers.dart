import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/cache_service.dart';
import '../services/api_service.dart';
import '../services/weather_service.dart';
import '../models/sensor_data.dart';
import '../models/grid_cell.dart';
import '../models/farm_health.dart';
import '../models/village_alert.dart';
import '../models/user_profile.dart';
import '../models/task_item.dart';

// --- Services ---
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  return ApiService(cache);
});

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

// --- State Providers ---

class LocaleNotifier extends StateNotifier<String> {
  final CacheService cacheService;
  
  LocaleNotifier(this.cacheService) : super(cacheService.getLanguage());

  Future<void> setLocale(String languageCode) async {
    await cacheService.saveLanguage(languageCode);
    state = languageCode;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  return LocaleNotifier(ref.watch(cacheServiceProvider));
});

// Sensor Provider
final sensorProvider = StateNotifierProvider<SensorNotifier, AsyncValue<SensorData?>>((ref) {
  return SensorNotifier(ref.watch(apiServiceProvider));
});

class SensorNotifier extends StateNotifier<AsyncValue<SensorData?>> {
  final ApiService api;
  Timer? _timer;

  SensorNotifier(this.api) : super(const AsyncValue.loading()) {
    fetchSensorData();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => fetchSensorData());
  }

  Future<void> fetchSensorData() async {
    try {
      final data = await api.getLatestSensor();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Digital Twin Grid Provider
final twinGridProvider = StateNotifierProvider<TwinGridNotifier, AsyncValue<List<GridCell>>>((ref) {
  return TwinGridNotifier(ref.watch(apiServiceProvider));
});

class TwinGridNotifier extends StateNotifier<AsyncValue<List<GridCell>>> {
  final ApiService api;
  TwinGridNotifier(this.api) : super(const AsyncValue.loading()) {
    fetchTwinGrid();
  }

  Future<void> fetchTwinGrid() async {
    try {
      final cells = await api.getTwinState();
      state = AsyncValue.data(cells);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Farm Health Provider
final farmHealthProvider = StateNotifierProvider<FarmHealthNotifier, AsyncValue<FarmHealth?>>((ref) {
  return FarmHealthNotifier(ref.watch(apiServiceProvider));
});

class FarmHealthNotifier extends StateNotifier<AsyncValue<FarmHealth?>> {
  final ApiService api;
  FarmHealthNotifier(this.api) : super(const AsyncValue.loading()) {
    fetchFarmHealth();
  }

  Future<void> fetchFarmHealth() async {
    try {
      final health = await api.getFarmHealth();
      state = AsyncValue.data(health);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Village Alerts Provider
final alertsProvider = StateNotifierProvider<AlertsNotifier, AsyncValue<List<VillageAlert>>>((ref) {
  return AlertsNotifier(ref.watch(apiServiceProvider));
});

class AlertsNotifier extends StateNotifier<AsyncValue<List<VillageAlert>>> {
  final ApiService api;
  AlertsNotifier(this.api) : super(const AsyncValue.loading()) {
    fetchAlerts();
  }

  Future<void> fetchAlerts() async {
    try {
      final alerts = await api.getVillageAlerts();
      state = AsyncValue.data(alerts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Village Summary Provider
final villageSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(alertsProvider); // Re-fetch summary if alerts change/refresh
  final api = ref.watch(apiServiceProvider);
  return await api.getVillageSummary();
});

// Simulation Mode Provider (live, 24, 48, 72)
final simModeProvider = StateProvider<String>((ref) => 'live');

// Simulation State Provider
final simStateProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final mode = ref.watch(simModeProvider);
  if (mode == 'live') return null;
  final api = ref.watch(apiServiceProvider);
  return await api.simulateTwin(int.parse(mode));
});

// Analytics Provider
final analyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(twinGridProvider); // refresh on twin update
  final api = ref.watch(apiServiceProvider);
  return await api.getAnalytics();
});

// Timeline Provider
final timelineProvider = FutureProvider<List<dynamic>>((ref) async {
  ref.watch(twinGridProvider);
  final api = ref.watch(apiServiceProvider);
  return await api.getTimeline();
});

// Health History Provider
final healthHistoryProvider = FutureProvider<List<dynamic>>((ref) async {
  ref.watch(twinGridProvider);
  final api = ref.watch(apiServiceProvider);
  return await api.getHealthHistory();
});

// Navigation Provider
final navigationIndexProvider = StateProvider<int>((ref) => 0);

// --- Profile Provider ---

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final CacheService cacheService;
  
  UserProfileNotifier(this.cacheService) : super(
    cacheService.getUserProfile() ?? UserProfile(userName: 'Farmer', farmName: 'Demo Farm 1', location: '')
  );

  Future<void> updateProfile({String? userName, String? farmName, String? location}) async {
    final updated = state.copyWith(
      userName: userName,
      farmName: farmName,
      location: location,
    );
    await cacheService.saveUserProfile(updated);
    state = updated;
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier(ref.watch(cacheServiceProvider));
});

// --- Weather Provider ---
final weatherProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final weatherService = ref.watch(weatherServiceProvider);
  final profile = ref.watch(userProfileProvider);

  String? cityStr = profile.location.isNotEmpty ? profile.location : null;

  // Use city name if available (WeatherAPI handles geocoding internally)
  if (cityStr != null && cityStr.isNotEmpty) {
    final data = await weatherService.getWeatherByCity(cityStr);
    if (data != null) return data;
  }

  // Fallback: auto-detect via IP, then fetch with coords
  final autoLoc = await weatherService.getAutoLocation();
  if (autoLoc != null) {
    final city = autoLoc['city'] as String?;
    final lat = autoLoc['lat'] as double?;
    final lon = autoLoc['lon'] as double?;

    if (cityStr == null || cityStr.isEmpty) {
      ref.read(userProfileProvider.notifier).updateProfile(location: city ?? '');
    }

    if (lat != null && lon != null) {
      return await weatherService.getWeatherByCoords(lat, lon);
    }
  }
  return null;
});

// --- Crop Vision Scan History Provider ---
class ScanHistoryNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  ScanHistoryNotifier() : super([]);

  void addScan(Map<String, dynamic> scanResult) {
    state = [scanResult, ...state];
  }
}

final scanHistoryProvider = StateNotifierProvider<ScanHistoryNotifier, List<Map<String, dynamic>>>((ref) {
  return ScanHistoryNotifier();
});

// --- Tasks Provider ---
class TasksNotifier extends StateNotifier<List<TaskItem>> {
  final CacheService cache;

  TasksNotifier(this.cache) : super([]) {
    _loadTasks();
  }

  void _loadTasks() {
    final rawTasks = cache.getTasks();
    state = rawTasks.map((e) => TaskItem.fromJson(e)).toList();
  }

  void addTask({
    required String field,
    required String taskType,
    required DateTime date,
    required String time,
    required String recurrence,
    required String notes,
  }) {
    final newTask = TaskItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      field: field,
      taskType: taskType,
      date: date,
      time: time,
      recurrence: recurrence,
      notes: notes,
    );
    state = [newTask, ...state];
    _saveTasks();
  }

  void toggleTaskComplete(String id) {
    state = state.map((t) {
      if (t.id == id) {
        return t.copyWith(isCompleted: !t.isCompleted);
      }
      return t;
    }).toList();
    _saveTasks();
  }

  void deleteTask(String id) {
    state = state.where((t) => t.id != id).toList();
    _saveTasks();
  }

  void _saveTasks() {
    cache.saveTasks(state.map((t) => t.toJson()).toList());
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, List<TaskItem>>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  return TasksNotifier(cache);
});

