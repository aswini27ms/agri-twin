import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/grid_cell.dart';
import 'weather_intel_screen.dart';
import 'soil_analysis_screen.dart';
import 'crop_vision_screen.dart';
import 'yield_predict_screen.dart';
import 'twin_dashboard_screen.dart';
import 'tasks_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);
    final profile = ref.watch(userProfileProvider);
    final twinGridAsync = ref.watch(twinGridProvider);

    // Determine greeting
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final userName = profile.userName.isNotEmpty ? profile.userName : 'Farmer';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFA),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ──────────────────────────────────────────────────────────────
            // TOP APP BAR
            // ──────────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, $userName 👋',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFF008000), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              profile.location.isNotEmpty ? profile.location : 'Tamil Nadu, India',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                          ],
                        )
                      ],
                    ),
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFF008000),
                      child: Text("S", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),

            // ──────────────────────────────────────────────────────────────
            // SEARCH BAR
            // ──────────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search fields, crop issues...",
                      hintStyle: const TextStyle(color: Colors.black38),
                      prefixIcon: const Icon(Icons.search, color: Colors.black54),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF008000),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic, color: Colors.white, size: 20),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),
            ),

            // ──────────────────────────────────────────────────────────────
            // HERO LANDING BANNER
            // ──────────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B421A), Color(0xFF1A7A30), Color(0xFF008000)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF008000).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon badge
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.eco, color: Color(0xFF00FF87), size: 36),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'AgriTwin Intelligence',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'AI-powered digital twin for smarter farming decisions — real-time insights for your fields, crops & soil.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _heroStat('4', 'Active Fields'),
                          _divider(),
                          _heroStat('92%', 'Crop Health'),
                          _divider(),
                          _heroStat('3', 'AI Alerts'),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Live weather pill from WeatherAPI
                      weatherAsync.when(
                        loading: () => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2)),
                              SizedBox(width: 8),
                              Text('Loading weather...', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (weather) {
                          if (weather == null) return const SizedBox.shrink();
                          final temp = weather['temperature_2m']?.toStringAsFixed(0) ?? '--';
                          final desc = weather['description'] ?? '';
                          final city = weather['city'] ?? '';
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherIntelScreen())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.wb_sunny_outlined, color: Color(0xFFFFD54F), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$temp°C · $desc${city.isNotEmpty ? ' · $city' : ''}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.chevron_right, color: Colors.white60, size: 16),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ──────────────────────────────────────────────────────────────
            // LIVE HARDWARE TELEMETRY (Arduino UNO Q)
            // ──────────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Consumer(
                builder: (context, ref, child) {
                  final sensorAsync = ref.watch(sensorProvider);
                  return sensorAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (sensorData) {
                      if (sensorData == null) return const SizedBox.shrink();
                      final temp = sensorData.temperature != null ? '${sensorData.temperature!.toStringAsFixed(1)}°C' : '--';
                      final humidity = sensorData.humidity != null ? '${sensorData.humidity!.toStringAsFixed(1)}%' : '--';
                      final soil = sensorData.soilMoisture != null ? '${sensorData.soilMoisture!.toStringAsFixed(0)}' : '--';
                      
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade900, const Color(0xFF0B421A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.router, color: Color(0xFF00FF87), size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Live Hardware Node (Arduino)',
                                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.wifi, color: Colors.greenAccent, size: 10),
                                        SizedBox(width: 4),
                                        Text('ONLINE', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _telemetryItem(Icons.thermostat, 'Temp', temp, Colors.orange),
                                  _telemetryItem(Icons.air, 'Humidity', humidity, Colors.teal),
                                  _telemetryItem(Icons.water_drop, 'Soil Raw', soil, Colors.blue),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // ──────────────────────────────────────────────────────────────
            // ACTIVE PLOTS — live from Digital Twin grid
            // ──────────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Row(
                      children: [
                        const Text(
                          'Active Plots',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TwinDashboardScreen()),
                          ),
                          child: const Row(
                            children: [
                              Text('View Twin', style: TextStyle(color: Color(0xFF008000), fontSize: 13, fontWeight: FontWeight.w600)),
                              SizedBox(width: 2),
                              Icon(Icons.chevron_right, color: Color(0xFF008000), size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 160,
                    child: twinGridAsync.when(
                      loading: () => _buildPlotsLoading(),
                      error: (_, __) => _buildPlotsFallback(context),
                      data: (cells) {
                        if (cells.isEmpty) return _buildPlotsFallback(context);
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: cells.length,
                          itemBuilder: (context, i) => _buildGridPlotCard(context, cells[i]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ──────────────────────────────────────────────────────────────
            // FIELD HEALTH OVERVIEW
            // ──────────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Field Health Overview",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHealthDial(label: "Soil", value: 85, color: Colors.brown.shade400),
                          _buildHealthDial(label: "Water", value: 65, color: Colors.blue.shade400),
                          _buildHealthDial(label: "Crop", value: 92, color: const Color(0xFF008000)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ──────────────────────────────────────────────────────────────
            // AI FIELD SERVICES (4 functional cards)
            // ──────────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "AI Field Services",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      children: [
                        _buildServiceCard(
                          context: context,
                          icon: Icons.grass,
                          title: "Soil Analysis",
                          color: Colors.orange.shade100,
                          iconColor: Colors.orange.shade800,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SoilAnalysisScreen())),
                        ),
                        _buildServiceCard(
                          context: context,
                          icon: Icons.cloud,
                          title: "Weather Intel",
                          color: Colors.blue.shade100,
                          iconColor: Colors.blue.shade800,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherIntelScreen())),
                        ),
                        _buildServiceCard(
                          context: context,
                          icon: Icons.camera_alt,
                          title: "Crop Vision",
                          color: Colors.green.shade100,
                          iconColor: const Color(0xFF008000),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CropVisionScreen())),
                        ),
                        _buildServiceCard(
                          context: context,
                          icon: Icons.trending_up,
                          title: "Yield Predict",
                          color: Colors.purple.shade100,
                          iconColor: Colors.purple.shade800,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const YieldPredictScreen())),
                        ),
                        _buildServiceCard(
                          context: context,
                          icon: Icons.event_note,
                          title: "Tasks & Notes",
                          color: Colors.teal.shade100,
                          iconColor: Colors.teal.shade800,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen())),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ──────────────────────────────────────────────────────────────
            // AI DIAGNOSTIC CHAMBER BANNER
            // ──────────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CropVisionScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0B421A), Color(0xFF008000)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("AI Diagnostic Chamber", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text("Scan your crops for instant disease detection.", style: TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.document_scanner, color: Colors.white, size: 32),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: Colors.white24);

  // ── Grid Plot card — from Digital Twin data ──────────────────────────────
  Widget _buildGridPlotCard(BuildContext context, GridCell cell) {
    final riskColor = _riskColor(cell.riskLevel);
    final moisture = cell.soilMoisture != null ? '${cell.soilMoisture!.toStringAsFixed(0)}%' : '--';
    final temp = cell.temperature != null ? '${cell.temperature!.toStringAsFixed(1)}°C' : '--';
    final humidity = cell.humidity != null ? '${cell.humidity!.toStringAsFixed(0)}%' : '--';
    final cropLabel = (cell.crop?.isNotEmpty == true) ? cell.crop! : 'Unknown Crop';
    final diseaseLabel = cell.disease == 'Unscanned' || cell.disease == 'Healthy' ? cell.disease : cell.disease;
    final severityPct = (cell.severity * 100).toStringAsFixed(0);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TwinDashboardScreen())),
      child: Container(
        width: 210,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: riskColor.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grid ID + Risk badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B421A).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Grid ${cell.gridId}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0B421A))),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(cell.riskLevel, style: TextStyle(color: riskColor, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Crop name
            Text(cropLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
            // Disease status
            Row(
              children: [
                Icon(
                  cell.disease == 'Healthy' || cell.disease == 'Unscanned' ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                  size: 12,
                  color: cell.disease == 'Healthy' ? Colors.green : cell.disease == 'Unscanned' ? Colors.grey : Colors.orange,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(diseaseLabel, style: TextStyle(color: Colors.black54, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const Spacer(),
            // Severity bar (only if not Unscanned)
            if (cell.disease != 'Unscanned') ...[
              Row(
                children: [
                  const Text('Severity ', style: TextStyle(fontSize: 10, color: Colors.black45)),
                  const Spacer(),
                  Text('$severityPct%', style: TextStyle(fontSize: 10, color: riskColor, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: cell.severity.clamp(0.0, 1.0),
                  backgroundColor: riskColor.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 6),
            ],
            // Sensor readings
            Row(
              children: [
                const Icon(Icons.water_drop, color: Colors.blue, size: 13),
                const SizedBox(width: 3),
                Text(moisture, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
                const Icon(Icons.thermostat, color: Colors.orange, size: 13),
                const SizedBox(width: 3),
                Text(temp, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
                const Icon(Icons.air, color: Colors.teal, size: 13),
                const SizedBox(width: 3),
                Text(humidity, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low': return Colors.green;
      case 'medium': return Colors.orange;
      case 'high': return Colors.red;
      case 'critical': return const Color(0xFF8B0000);
      default: return Colors.grey;
    }
  }

  // Loading skeleton for plots
  Widget _buildPlotsLoading() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        width: 210,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // Fallback static plots when backend unavailable
  Widget _buildPlotsFallback(BuildContext context) {
    final plots = [
      {'title': 'Corn Field A', 'crop': 'Sweet Corn', 'risk': 'Low', 'moisture': '42%', 'temp': '28.0°C', 'humidity': '65%'},
      {'title': 'Tomato Plot 2', 'crop': 'Roma Tomato', 'risk': 'Medium', 'moisture': '28%', 'temp': '31.0°C', 'humidity': '58%'},
    ];
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: plots.length,
      itemBuilder: (_, i) {
        final p = plots[i];
        final riskColor = _riskColor(p['risk']!);
        return Container(
          width: 210,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
            border: Border.all(color: riskColor.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF0B421A).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                    child: Text(p['title']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0B421A))),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: riskColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: Text(p['risk']!, style: TextStyle(color: riskColor, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(p['crop']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
              const Text('Healthy', style: TextStyle(color: Colors.black54, fontSize: 11)),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.water_drop, color: Colors.blue, size: 13),
                  const SizedBox(width: 3),
                  Text(p['moisture']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                  const Icon(Icons.thermostat, color: Colors.orange, size: 13),
                  const SizedBox(width: 3),
                  Text(p['temp']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                  const Icon(Icons.air, color: Colors.teal, size: 13),
                  const SizedBox(width: 3),
                  Text(p['humidity']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildHealthDial({required String label, required double value, required Color color}) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value / 100,
                backgroundColor: color.withOpacity(0.2),
                color: color,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Text(
                  "${value.toInt()}%",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
      ],
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }

  Widget _telemetryItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
