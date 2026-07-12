import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class WeatherIntelScreen extends ConsumerWidget {
  const WeatherIntelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: weatherAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF4FC3F7)),
          ),
          error: (e, _) => _buildError(context, ref),
          data: (data) {
            if (data == null) return _buildError(context, ref);
            return _buildContent(context, ref, data);
          },
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          const Text('Unable to fetch weather', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.refresh(weatherProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4FC3F7)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Map<String, dynamic> data) {
    final temp = data['temperature_2m']?.toStringAsFixed(0) ?? '--';
    final feelsLike = data['feels_like']?.toStringAsFixed(0) ?? '--';
    final humidity = data['relative_humidity_2m']?.toString() ?? '--';
    final windSpeed = data['wind_speed_10m']?.toStringAsFixed(1) ?? '--';
    final windDir = data['wind_dir'] ?? '';
    final description = data['description'] ?? 'N/A';
    final city = data['city'] ?? 'Unknown';
    final region = data['region'] ?? '';
    final uv = data['uv_index']?.toString() ?? '--';
    final visibility = data['visibility']?.toString() ?? '--';
    final precip = data['precipitation']?.toString() ?? '0';
    final aqi = data['aqi'];
    final forecast = (data['forecast'] as List?) ?? [];
    final hourly = (data['hourly'] as List?) ?? [];
    final isDay = data['is_day'] == 1;

    final Color skyTop = isDay ? const Color(0xFF1565C0) : const Color(0xFF0D1B3E);
    final Color skyBottom = isDay ? const Color(0xFF42A5F5) : const Color(0xFF0A1628);

    return CustomScrollView(
      slivers: [
        // Hero header
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [skyTop, skyBottom],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              children: [
                // Top bar
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showLocationDialog(context, ref, city),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(city, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit_location_alt_outlined, color: Colors.white70, size: 16),
                            ],
                          ),
                          if (region.isNotEmpty)
                            Text(region, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () => ref.refresh(weatherProvider),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Big temperature
                Text(
                  '$temp°C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.w200,
                    letterSpacing: -2,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w300),
                ),
                const SizedBox(height: 8),
                Text(
                  'Feels like $feelsLike°C',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 28),
                // Quick stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _quickStat(Icons.water_drop_outlined, '$humidity%', 'Humidity'),
                    _quickStat(Icons.air, '$windSpeed km/h $windDir', 'Wind'),
                    _quickStat(Icons.umbrella_outlined, '${precip}mm', 'Precip'),
                    _quickStat(Icons.wb_sunny_outlined, 'UV $uv', 'UV Index'),
                  ],
                ),
              ],
            ),
          ),
        ),

        // AQI banner if available
        if (aqi != null)
          SliverToBoxAdapter(
            child: _buildAqiBanner(aqi as int),
          ),

        // Hourly section
        if (hourly.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildSection(
              title: 'Hourly Forecast',
              child: SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: hourly.length,
                  itemBuilder: (context, i) {
                    final h = hourly[i] as Map<String, dynamic>;
                    final time = (h['time'] as String).split(' ').last;
                    final hTemp = h['temp']?.toStringAsFixed(0) ?? '--';
                    final rain = h['rain_chance']?.toString() ?? '0';
                    return Container(
                      width: 72,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(time, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                          const SizedBox(height: 6),
                          const Icon(Icons.cloud, color: Color(0xFF4FC3F7), size: 20),
                          const SizedBox(height: 6),
                          Text('$hTemp°', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('$rain%', style: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 10)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

        // 3-Day forecast
        if (forecast.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildSection(
              title: '3-Day Forecast',
              child: Column(
                children: forecast.map((d) {
                  final day = d as Map<String, dynamic>;
                  final date = day['date'] as String? ?? '';
                  final maxT = day['max_temp']?.toStringAsFixed(0) ?? '--';
                  final minT = day['min_temp']?.toStringAsFixed(0) ?? '--';
                  final cond = day['condition'] ?? '';
                  final rain = day['rain_chance']?.toString() ?? '0';
                  final dayName = _dayName(date);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 70, child: Text(dayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                        const Icon(Icons.cloud, color: Color(0xFF4FC3F7), size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(cond, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                        Text('$rain%', style: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 12)),
                        const SizedBox(width: 12),
                        Text('$minT° / $maxT°', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

        // Details grid
        SliverToBoxAdapter(
          child: _buildSection(
            title: 'Weather Details',
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _detailCard('Visibility', '$visibility km', Icons.visibility_outlined, Colors.teal),
                _detailCard('Humidity', '$humidity%', Icons.water_drop_outlined, Colors.blue),
                _detailCard('Wind', '$windSpeed km/h', Icons.air, Colors.cyan),
                _detailCard('Precipitation', '${precip}mm', Icons.umbrella_outlined, Colors.indigo),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _quickStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _buildAqiBanner(int aqi) {
    final aqiLabels = ['Good', 'Moderate', 'Unhealthy for Sensitive', 'Unhealthy', 'Very Unhealthy', 'Hazardous'];
    final aqiColors = [Colors.green, Colors.yellow, Colors.orange, Colors.red, Colors.purple, Colors.brown];
    final idx = (aqi - 1).clamp(0, 5);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: aqiColors[idx].withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: aqiColors[idx].withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.air, color: aqiColors[idx], size: 20),
          const SizedBox(width: 10),
          Text('Air Quality: ${aqiLabels[idx]}', style: TextStyle(color: aqiColors[idx], fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('AQI $aqi', style: TextStyle(color: aqiColors[idx])),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _detailCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  String _dayName(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final today = DateTime.now();
      if (date.day == today.day) return 'Today';
      if (date.day == today.day + 1) return 'Tomorrow';
      return days[date.weekday - 1];
    } catch (_) {
      return dateStr;
    }
  }
  void _showLocationDialog(BuildContext context, WidgetRef ref, String currentCity) {
    final controller = TextEditingController(text: currentCity);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Location', style: TextStyle(color: Color(0xFF1E293B))),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter city (e.g., London, Chennai)',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.location_city, color: Colors.black45),
          ),
          autofocus: true,
          onSubmitted: (_) {
            if (controller.text.trim().isNotEmpty) {
              ref.read(userProfileProvider.notifier).updateProfile(location: controller.text.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(userProfileProvider.notifier).updateProfile(location: controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008000),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

