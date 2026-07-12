import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class WeatherService {
  final Dio _dio = Dio();
  static const String _apiKey = '1ee445f5f1f840dc96d24246242205';
  static const String _baseUrl = 'https://api.weatherapi.com/v1';

  /// Get current weather + forecast for a city name or lat,lon string
  Future<Map<String, dynamic>?> getWeatherByCity(String city) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/forecast.json',
        queryParameters: {
          'key': _apiKey,
          'q': city,
          'days': 3,
          'aqi': 'yes',
          'alerts': 'yes',
        },
      );
      if (response.statusCode == 200) {
        return _parseWeatherApiResponse(response.data);
      }
    } catch (e) {
      debugPrint("WeatherAPI fetch error: $e");
    }
    return null;
  }

  /// Get weather by coordinates
  Future<Map<String, dynamic>?> getWeatherByCoords(double lat, double lon) async {
    return getWeatherByCity('$lat,$lon');
  }

  /// Try to get location automatically based on IP
  Future<Map<String, dynamic>?> getAutoLocation() async {
    try {
      final response = await _dio.get('http://ip-api.com/json/');
      if (response.statusCode == 200) {
        return {
          'city': response.data['city'],
          'lat': response.data['lat'],
          'lon': response.data['lon'],
        };
      }
    } catch (e) {
      debugPrint("Auto location error: $e");
    }
    return null;
  }

  /// Geocode a city name (fallback using open-meteo)
  Future<Map<String, dynamic>?> geocodeCity(String city) async {
    try {
      final response = await _dio.get(
        'https://geocoding-api.open-meteo.com/v1/search',
        queryParameters: {
          'name': city,
          'count': 1,
          'language': 'en',
          'format': 'json',
        },
      );
      if (response.statusCode == 200 && response.data['results'] != null) {
        final result = response.data['results'][0];
        return {
          'lat': result['latitude'],
          'lon': result['longitude'],
        };
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
    return null;
  }

  /// Legacy method kept for compatibility
  Future<Map<String, dynamic>?> getWeather(double lat, double lon) async {
    return getWeatherByCoords(lat, lon);
  }

  Map<String, dynamic> _parseWeatherApiResponse(dynamic data) {
    final current = data['current'];
    final location = data['location'];
    final forecast = data['forecast']?['forecastday'] as List? ?? [];

    // Build 3-day forecast list
    final forecastDays = forecast.map((day) {
      return {
        'date': day['date'],
        'max_temp': day['day']['maxtemp_c'],
        'min_temp': day['day']['mintemp_c'],
        'avg_temp': day['day']['avgtemp_c'],
        'condition': day['day']['condition']['text'],
        'icon': 'https:${day['day']['condition']['icon']}',
        'rain_chance': day['day']['daily_chance_of_rain'],
        'humidity': day['day']['avghumidity'],
      };
    }).toList();

    // Hourly for today
    final todayHourly = (forecast.isNotEmpty ? forecast[0]['hour'] as List? ?? [] : [])
        .map((h) => {
              'time': h['time'],
              'temp': h['temp_c'],
              'condition': h['condition']['text'],
              'icon': 'https:${h['condition']['icon']}',
              'rain_chance': h['chance_of_rain'],
            })
        .toList();

    return {
      // Current
      'temperature_2m': current['temp_c'],
      'feels_like': current['feelslike_c'],
      'relative_humidity_2m': current['humidity'],
      'wind_speed_10m': current['wind_kph'],
      'wind_dir': current['wind_dir'],
      'precipitation': current['precip_mm'],
      'uv_index': current['uv'],
      'visibility': current['vis_km'],
      'description': current['condition']['text'],
      'icon': 'https:${current['condition']['icon']}',
      'is_day': current['is_day'],
      // Air Quality
      'aqi': data['current']?['air_quality']?['us-epa-index'],
      // Location
      'city': location['name'],
      'region': location['region'],
      'country': location['country'],
      'local_time': location['localtime'],
      // Forecast
      'forecast': forecastDays,
      'hourly': todayHourly,
    };
  }

  String getWeatherDescription(int code) {
    if (code == 0) return 'Clear Sky';
    if (code == 1 || code == 2 || code == 3) return 'Partly Cloudy';
    if (code == 45 || code == 48) return 'Foggy';
    if (code >= 51 && code <= 57) return 'Drizzle';
    if (code >= 61 && code <= 67) return 'Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Rain Showers';
    if (code >= 95 && code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }
}
