import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_providers.dart';
import '../models/grid_cell.dart';
import '../models/farm_health.dart';

final selectedGridProvider = StateProvider<String?>((ref) => null);

class TwinDashboardScreen extends ConsumerStatefulWidget {
  const TwinDashboardScreen({super.key});

  @override
  ConsumerState<TwinDashboardScreen> createState() =>
      _TwinDashboardScreenState();
}

class _TwinDashboardScreenState extends ConsumerState<TwinDashboardScreen> {
  Timer? _refreshTimer;
  final ImagePicker _picker = ImagePicker();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (ref.read(simModeProvider) == 'live') {
        ref.read(twinGridProvider.notifier).fetchTwinGrid();
        ref.read(farmHealthProvider.notifier).fetchFarmHealth();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickAndScanImage() async {
    final currentGrid = ref.read(selectedGridProvider);
    final imageSource = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Pick from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (imageSource == null) return;

    final pickedFile =
        await _picker.pickImage(source: imageSource, imageQuality: 85);
    if (pickedFile == null) return;

    if (!mounted) return;

    final gridIdController = TextEditingController(text: currentGrid ?? 'A1');
    final cropAgeController = TextEditingController(text: '30');
    final previousSeverityController = TextEditingController(text: '0.3');
    final tempController = TextEditingController(text: '28.0');
    final humController = TextEditingController(text: '65.0');
    final moistController = TextEditingController(text: '45.0');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Scan grid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gridIdController,
              decoration:
                  const InputDecoration(labelText: 'Grid ID', hintText: 'A1'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: cropAgeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Crop age (days)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: previousSeverityController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Previous severity (0.0–1.0)'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: tempController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Temp (°C)'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: humController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Humidity (%)'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: moistController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Moisture (%)'))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, {
              'grid_id': gridIdController.text.trim().toUpperCase(),
              'crop_age_days': int.tryParse(cropAgeController.text) ?? 30,
              'previous_severity': double.tryParse(previousSeverityController.text) ?? 0.3,
              'temperature': double.tryParse(tempController.text),
              'humidity': double.tryParse(humController.text),
              'soil_moisture': double.tryParse(moistController.text),
            }),
            child: const Text('Upload'),
          ),
        ],
      ),
    );

    if (result == null) return;

    setState(() => _isScanning = true);
    try {
      final imageBytes = await pickedFile.readAsBytes();
      final filename = pickedFile.name;
      await ref.read(apiServiceProvider).scanCrop(
            imageBytes,
            filename,
            result['grid_id'] as String,
            result['crop_age_days'] as int,
            previousSeverity: (result['previous_severity'] as num).toDouble(),
            temperature: result['temperature'] as double?,
            humidity: result['humidity'] as double?,
            soilMoisture: result['soil_moisture'] as double?,
          );
      if (!mounted) return;
      ref.invalidate(twinGridProvider);
      ref.invalidate(farmHealthProvider);
      ref.invalidate(analyticsProvider);
      ref.invalidate(timelineProvider);
      ref.invalidate(healthHistoryProvider);
      await ref.read(twinGridProvider.notifier).fetchTwinGrid();
      await ref.read(farmHealthProvider.notifier).fetchFarmHealth();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan uploaded for ${result['grid_id']}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan upload failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gridState = ref.watch(twinGridProvider);
    final healthState = ref.watch(farmHealthProvider);
    final analyticsState = ref.watch(analyticsProvider);
    final simMode = ref.watch(simModeProvider);
    final simState = ref.watch(simStateProvider);

    final isSim = simMode != 'live';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, ref),
              const SizedBox(height: 16),
              if (healthState.value != null)
                _buildStatsRow(
                    context, healthState.value!, isSim ? simState.value : null),
              const SizedBox(height: 16),
              if (healthState.value != null)
                _buildHealthBreakdown(context, healthState.value!),
              const SizedBox(height: 16),
              _buildTrendChart(context, ref),
              const SizedBox(height: 16),
              if (analyticsState.value != null)
                _buildAnalyticsRow(
                    context,
                    isSim
                        ? _computeSimAnalytics(simState.value)
                        : analyticsState.value!),
              const SizedBox(height: 24),
              _buildSimBar(context, ref, simMode),
              const SizedBox(height: 16),
              if (gridState.value != null)
                _buildFarmGridAndPanel(context, ref, gridState.value!,
                    isSim ? simState.value : null),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(twinGridProvider).value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isConnected ? "Connected to AgriTwin server" : "Not connected",
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                    fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _pickAndScanImage,
              icon: _isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.camera_alt_rounded, size: 18),
              label: Text(_isScanning ? 'Scanning...' : 'Scan Grid'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withValues(alpha: 0.2)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(apiServiceProvider).resetTwin();
                ref.read(twinGridProvider.notifier).fetchTwinGrid();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.2)),
              child: const Text("Reset Twin",
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(
      BuildContext context, FarmHealth health, Map<String, dynamic>? simState) {
    final score = simState != null
        ? simState['projected_farm_health']
        : health.farmHealthScore;

    double? avgRisk;
    int infected = health.infectedGrids;
    if (simState != null) {
      final grid = simState['projected_grid'] as Map<String, dynamic>;
      double totalRisk = 0;
      int scannedCount = 0;
      int projInfected = 0;
      grid.forEach((key, value) {
        if (value['disease'] != 'Unscanned') {
          totalRisk += (value['projected_severity'] as num).toDouble();
          scannedCount++;
          if (value['disease'] != 'Tomato_Healthy' && value['disease'] != null) {
              projInfected++;
          }
        }
      });
      if (scannedCount > 0) avgRisk = totalRisk / scannedCount;
      infected = projInfected;
    } else {
      avgRisk = health.averageRisk;
    }

    return Row(
      children: [
        Expanded(
            child: _statCard("Farm Health", "${score.round()}%",
                simState != null ? Colors.orange : Colors.green)),
        const SizedBox(width: 8),
        Expanded(
            child: _statCard("Scanned",
                "${health.gridsScanned}/${health.gridsTotal}", Colors.blue)),
        const SizedBox(width: 8),
        Expanded(
            child: _statCard(
                simState != null ? "Proj. Infected" : "Infected", 
                "$infected", 
                Colors.redAccent)),
        const SizedBox(width: 8),
        Expanded(
            child: _statCard(
                simState != null ? "Proj. Risk" : "Avg Moisture",
                simState != null ? "${avgRisk?.round() ?? 0}%" : "${health.averageSoilMoisture?.round() ?? '--'}%",
                simState != null ? Colors.orange : Colors.lightBlue)),
      ],
    );
  }

  Widget _statCard(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: 3,
              width: 30,
              color: accent,
              margin: const EdgeInsets.only(bottom: 8)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildHealthBreakdown(BuildContext context, FarmHealth health) {
    final bd = health.breakdown;
    if (bd == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("FARM HEALTH BREAKDOWN",
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
          const SizedBox(height: 12),
          _barRow(
              "Disease Impact", bd['disease_impact'] ?? 0, Colors.redAccent),
          _barRow(
              "Moisture Stress", bd['moisture_stress'] ?? 0, Colors.lightBlue),
          _barRow("Temp Stress", bd['temp_stress'] ?? 0, Colors.orangeAccent),
          _barRow("Healthy Area", bd['healthy_area_pct'] ?? 0, Colors.green),
        ],
      ),
    );
  }

  Widget _barRow(String label, dynamic value, Color color) {
    final val = (value as num).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.black87))),
          Expanded(
            child: LinearProgressIndicator(
              value: val / 100,
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
              width: 45,
              child: Text("${val.toStringAsFixed(1)}%",
                  style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Colors.black))),
        ],
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(healthHistoryProvider);
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("FARM HEALTH TREND",
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
          const SizedBox(height: 16),
          Expanded(
            child: historyState.when(
              data: (history) {
                if (history.isEmpty) {
                  return const Center(child: Text("No trend data yet."));
                }
                List<FlSpot> spots = [];
                for (int i = 0; i < history.length; i++) {
                  spots.add(FlSpot(i.toDouble(),
                      (history[i]['farm_health_score'] as num).toDouble()));
                }
                return LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.greenAccent,
                        barWidth: 2,
                        dotData: FlDotData(show: spots.length <= 1),
                        belowBarData: BarAreaData(
                            show: true,
                            color: Colors.greenAccent.withValues(alpha: 0.1)),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) =>
                  Center(child: Text("Error loading history: \$e")),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _computeSimAnalytics(Map<String, dynamic>? simState) {
    if (simState == null || simState['projected_grid'] == null) return {};
    int healthy = 0, low = 0, med = 0, high = 0, crit = 0;
    (simState['projected_grid'] as Map).forEach((k, v) {
      if (v['disease'] == 'Unscanned') return;
      if (v['disease'] == 'Tomato_Healthy') {
        healthy++;
        return;
      }
      double sev = (v['projected_severity'] as num).toDouble();
      if (sev >= 85)
        crit++;
      else if (sev >= 70)
        high++;
      else if (sev >= 40)
        med++;
      else if (sev > 0)
        low++;
      else
        healthy++;
    });
    return {
      'healthy': healthy,
      'low_risk': low,
      'medium_risk': med,
      'high_risk': high,
      'critical': crit
    };
  }

  Widget _buildAnalyticsRow(
      BuildContext context, Map<String, dynamic> analytics) {
    return Row(
      children: [
        _analyticsCard("Healthy", analytics['healthy'] ?? 0, Colors.green),
        _analyticsCard("Low Risk", analytics['low_risk'] ?? 0, Colors.yellow),
        _analyticsCard(
            "Med Risk", analytics['medium_risk'] ?? 0, Colors.orange),
        _analyticsCard(
            "High Risk", analytics['high_risk'] ?? 0, Colors.redAccent),
        _analyticsCard("Critical", analytics['critical'] ?? 0, Colors.red),
      ],
    );
  }

  Widget _analyticsCard(String label, dynamic value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          border: Border(top: BorderSide(color: color, width: 2)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text("$value",
                style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace')),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 9, color: Colors.black54),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSimBar(BuildContext context, WidgetRef ref, String simMode) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _simButton(ref, 'live', "Live", simMode == 'live'),
          const SizedBox(width: 8),
          _simButton(ref, '24', "+24 Hours", simMode == '24'),
          const SizedBox(width: 8),
          _simButton(ref, '48', "+48 Hours", simMode == '48'),
          const SizedBox(width: 8),
          _simButton(ref, '72', "+72 Hours", simMode == '72'),
        ],
      ),
    );
  }

  Widget _simButton(WidgetRef ref, String mode, String label, bool isActive) {
    return ElevatedButton(
      onPressed: () => ref.read(simModeProvider.notifier).state = mode,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.blueAccent : Colors.black12,
        foregroundColor: isActive ? Colors.white : Colors.black87,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  Widget _buildFarmGridAndPanel(BuildContext context, WidgetRef ref,
      List<GridCell> cells, Map<String, dynamic>? simState) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isWide = constraints.maxWidth > 800;
      Widget grid = _buildGrid(cells, simState, ref);
      Widget panel = _buildSidePanel(ref);

      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: grid),
            const SizedBox(width: 16),
            Expanded(flex: 1, child: panel),
          ],
        );
      } else {
        return Column(
          children: [
            grid,
            const SizedBox(height: 16),
            panel,
          ],
        );
      }
    });
  }

  Widget _buildGrid(
      List<GridCell> cells, Map<String, dynamic>? simState, WidgetRef ref) {
    final selectedGrid = ref.watch(selectedGridProvider);
    Map<String, dynamic>? projectedMap;
    if (simState != null && simState['projected_grid'] != null) {
      projectedMap = simState['projected_grid'] as Map<String, dynamic>;
    }

    // Convert list to map for easier rendering (6x6)
    Map<String, GridCell> cellMap = {for (var c in cells) c.gridId: c};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1,
        ),
        itemCount: 36,
        itemBuilder: (context, index) {
          int r = index ~/ 6;
          int c = index % 6;
          String gridId = "${String.fromCharCode(65 + r)}${c + 1}";

          GridCell? cell = cellMap[gridId];
          bool isSelected = selectedGrid == gridId;

          Color bgColor = Colors.black12;
          String label = gridId;
          String pct = "";
          bool isSimulated = false;

          if (cell != null && cell.disease != "Unscanned") {
            bgColor = _getColor(cell.statusColor);
            if (cell.disease != "Tomato_Healthy")
              pct = "${cell.severity.round()}%";

            if (projectedMap != null && projectedMap.containsKey(gridId)) {
              var p = projectedMap[gridId];
              if (p['disease'] != "Unscanned" &&
                  p['disease'] != "Tomato_Healthy") {
                bgColor = _getColor(p['projected_status_color']);
                pct = "${(p['projected_severity'] as num).round()}%";
                isSimulated = true;
              }
            }
          }

          return GestureDetector(
            onTap: () => ref.read(selectedGridProvider.notifier).state = gridId,
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2),
                boxShadow: isSimulated
                    ? [
                        BoxShadow(
                            color: bgColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2)
                      ]
                    : null,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      if (pct.isNotEmpty)
                        Text(pct,
                            style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 10,
                                fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow.shade700;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      default:
        return Colors.black12;
    }
  }

  Widget _buildSidePanel(WidgetRef ref) {
    final selectedGrid = ref.watch(selectedGridProvider);
    final timelineState = ref.watch(timelineProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Detail Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: selectedGrid == null
              ? const Text("Tap a grid cell to see details.",
                  style: TextStyle(color: Colors.black54))
              : _buildCellDetails(ref, selectedGrid),
        ),
        const SizedBox(height: 16),
        // Event Log
        Container(
          width: double.infinity,
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("TWIN EVENT LOG",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightGreen)),
              const SizedBox(height: 12),
              Expanded(
                child: timelineState.when(
                  data: (logs) {
                    if (logs.isEmpty)
                      return const Text("No events yet.",
                          style: TextStyle(color: Colors.black54));
                    return ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, i) {
                        final log = logs[i];
                        final time =
                            DateTime.tryParse(log['timestamp'])?.toLocal() ??
                                DateTime.now();
                        final timeStr =
                            "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(timeStr,
                                  style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 10,
                                      fontFamily: 'monospace')),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    "${log['grid_id']}: ${log['event']}",
                                    style: const TextStyle(
                                        color: Colors.black87, fontSize: 11)),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => const Text("Failed to load logs"),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCellDetails(WidgetRef ref, String gridId) {
    final cells = ref.read(twinGridProvider).value ?? [];
    final cell = cells.firstWhere(
      (c) => c.gridId == gridId,
      orElse: () => GridCell(
        gridId: gridId,
        disease: 'Unscanned',
        severity: 0.0,
        riskLevel: 'Unknown',
        statusColor: 'gray',
      ),
    );

    if (cell.disease == 'Unscanned') {
      return Text("Grid $gridId has not been scanned yet.",
          style: const TextStyle(color: Colors.black54));
    }

    final rec = cell.recommendation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Grid $gridId — ${cell.crop ?? ''}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(
            "${cell.disease?.replaceAll('_', ' ')} · ${((cell.confidence ?? 0) * 100).round()}% confidence",
            style: const TextStyle(color: Colors.black54, fontSize: 12)),
        const Divider(color: Colors.black12, height: 24),
        _detailRow("Spread Risk", "${cell.severity.toStringAsFixed(1)}%"),
        _detailRow("Temperature", "${cell.temperature}°C"),
        _detailRow("Humidity", "${cell.humidity}%"),
        _detailRow("Soil Moisture", "${cell.soilMoisture}%"),
        if (rec != null) ...[
          const Divider(color: Colors.black12, height: 24),
          _detailRow(
            "Water Needed",
            "${rec.waterRequired ?? '—'} (${rec.waterAmountLiters?.toStringAsFixed(0) ?? '—'}L)",
          ),
          _detailRow("Pesticide", rec.pesticide ?? '—'),
          _detailRow("Fertilizer", rec.fertilizerGuidance ?? '—'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text("${rec.priority ?? 'Low'} Priority",
                style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showExplanationModal(gridId),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text("Explain with AI"),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.withValues(alpha: 0.2),
                foregroundColor: Colors.amber,
              ),
            ),
          ),
        ]
      ],
    );
  }

  Widget _detailRow(String key, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key,
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
          Text(val,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _showExplanationModal(String gridId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber),
                const SizedBox(width: 8),
                const Text("AI Explanation", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetContext)),
              ],
            ),
            const Divider(color: Colors.black26),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: ref.read(apiServiceProvider).getCellExplanation(gridId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text("Gemma is analyzing this cell...", style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
                  } else if (snapshot.hasData) {
                    final data = snapshot.data!;
                    final farmerExplanation = data['farmer_explanation'] as Map<String, dynamic>?;
                    
                    if (farmerExplanation == null) {
                      return const Center(child: Text("No explanation returned.", style: TextStyle(color: Colors.black54)));
                    }

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildExplainSection("Summary", farmerExplanation['summary']),
                          _buildExplainSection("Reason", farmerExplanation['reason']),
                          _buildExplainSection("Action", farmerExplanation['action']),
                          _buildExplainSection("Warning", farmerExplanation['warning']),
                          _buildExplainSection("Next Scan", farmerExplanation['next_scan']),
                        ],
                      ),
                    );
                  } else {
                    return const SizedBox();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplainSection(String title, String? text) {
    if (text == null || text.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black)),
        ],
      ),
    );
  }
}
