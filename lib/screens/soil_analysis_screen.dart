import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/soil_data.dart';

/// Standalone Soil Analysis page.
/// Data is simulated directly from the frontend using the dataset values.
class SoilAnalysisScreen extends ConsumerStatefulWidget {
  const SoilAnalysisScreen({super.key});

  @override
  ConsumerState<SoilAnalysisScreen> createState() => _SoilAnalysisScreenState();
}

class _SoilAnalysisScreenState extends ConsumerState<SoilAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  int _tab = 0; // 0 = Parameters, 1 = Recommendations

  Timer? _simulationTimer;
  int _currentIndex = 0;

  SoilData? _latest;
  bool _isConnected = true;

  final List<List<double>> _csvData = [
    [72,45,88,6.8,38,3.2,1.2,4.5],
    [68,42,84,6.7,36,3.0,1.1,4.3],
    [75,48,90,6.9,40,3.4,1.3,4.7],
    [70,44,86,6.8,37,3.1,1.2,4.4],
    [65,40,80,6.6,34,2.9,1.0,4.1],
    [78,50,92,7.0,42,3.5,1.4,4.9],
    [73,46,89,6.8,39,3.3,1.2,4.6],
    [69,43,85,6.7,35,3.0,1.1,4.2],
    [80,52,94,7.1,44,3.6,1.5,5.0],
    [71,45,87,6.8,38,3.2,1.2,4.5],
    [66,41,82,6.6,33,2.8,1.0,4.0],
    [77,49,91,6.9,41,3.4,1.3,4.8],
    [74,47,90,6.9,40,3.3,1.3,4.7],
    [63,39,78,6.5,31,2.7,0.9,3.9],
    [82,54,96,7.2,45,3.8,1.6,5.2],
  ];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();

    _updateData();
    _simulationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _updateData();
      }
    });
  }
  
  void _updateData() {
    final row = _csvData[_currentIndex % _csvData.length];
    setState(() {
      _latest = SoilData(
        nitrogen: row[0],
        phosphorus: row[1],
        potassium: row[2],
        ph: row[3],
        moisture: row[4],
        organicMatter: row[5],
        zinc: row[6],
        iron: row[7],
        source: 'sensor',
        timestamp: DateTime.now(),
      );
      _currentIndex++;
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _simulationTimer?.cancel();
    super.dispose();
  }

  // ── Derived parameter list from live data ────────────────────────────
  List<_SoilParam> get _params {
    final d = _latest;
    return [
      _SoilParam('pH Level', d?.ph ?? 6.8, 0, 14, '', '6.0–7.0',
          const Color(0xFF8BC34A), Icons.science_outlined,
          'pH measures soil acidity. 6.0–7.0 is ideal for most crops.'),
      _SoilParam('Nitrogen (N)', d?.nitrogen ?? 0, 0, 100, 'kg/ha', '60–90',
          const Color(0xFF42A5F5), Icons.eco_outlined,
          'Nitrogen drives leafy growth. Apply urea to boost.'),
      _SoilParam('Phosphorus (P)', d?.phosphorus ?? 0, 0, 100, 'kg/ha', '40–60',
          const Color(0xFFFF7043), Icons.grain,
          'Phosphorus supports root & fruit development.'),
      _SoilParam('Potassium (K)', d?.potassium ?? 0, 0, 100, 'kg/ha', '80–100',
          const Color(0xFFAB47BC), Icons.bubble_chart_outlined,
          'Potassium improves drought resistance and fruit quality.'),
      _SoilParam('Organic Matter', d?.organicMatter ?? 3.2, 0, 10, '%', '2.5–5%',
          const Color(0xFF795548), Icons.forest_outlined,
          'Organic matter feeds soil microbes and improves structure.'),
      _SoilParam('Moisture', d?.moisture ?? 0, 0, 100, '%', '30–50%',
          const Color(0xFF26C6DA), Icons.water_drop_outlined,
          'Adequate moisture is critical for nutrient uptake.'),
      _SoilParam('Zinc (Zn)', d?.zinc ?? 1.2, 0, 5, 'ppm', '1.0–3.0',
          const Color(0xFFFFA726), Icons.hub_outlined,
          'Zinc deficiency causes stunted growth and yellowing.'),
      _SoilParam('Iron (Fe)', d?.iron ?? 4.5, 0, 10, 'ppm', '3.0–6.0',
          const Color(0xFFEF5350), Icons.circle_outlined,
          'Iron is essential for chlorophyll production.'),
    ];
  }

  // Simple live health score: how close each param is to the middle of
  // its ideal range, averaged and scaled to 0-100.
  int get _healthScore {
    final ranges = <List<double>>[
      [6.0, 7.0], [60, 90], [40, 60], [80, 100], [2.5, 5], [30, 50], [1.0, 3.0], [3.0, 6.0],
    ];
    final params = _params;
    double totalScore = 0;
    for (var i = 0; i < params.length; i++) {
      final v = params[i].value;
      final lo = ranges[i][0], hi = ranges[i][1];
      double s;
      if (v >= lo && v <= hi) {
        s = 100;
      } else {
        final span = hi - lo;
        final dist = v < lo ? (lo - v) : (v - hi);
        s = (100 - (dist / span) * 100).clamp(0, 100);
      }
      totalScore += s;
    }
    return (totalScore / params.length).round();
  }

  List<_Recommendation> get _recs {
    final params = {for (final p in _params) p.name: p.value};
    final n = params['Nitrogen (N)'] ?? 0;
    final p = params['Phosphorus (P)'] ?? 0;
    final k = params['Potassium (K)'] ?? 0;
    final ph = params['pH Level'] ?? 6.8;
    final moisture = params['Moisture'] ?? 0;
    final om = params['Organic Matter'] ?? 0;

    final recs = <_Recommendation>[];

    if (ph >= 6.0 && ph <= 7.0) {
      recs.add(_Recommendation('pH is Optimal', 'pH ${ph.toStringAsFixed(1)} is ideal. No lime or sulfur needed.',
          Icons.check_circle_outline, 'Good', Colors.green));
    } else {
      recs.add(_Recommendation('pH Needs Attention',
          ph < 6.0 ? 'pH ${ph.toStringAsFixed(1)} is acidic. Consider adding lime.' : 'pH ${ph.toStringAsFixed(1)} is alkaline. Consider adding sulfur.',
          Icons.warning_amber_outlined, 'High', Colors.red));
    }

    if (n < 60) {
      recs.add(_Recommendation('Nitrogen Low', 'N is at ${n.toStringAsFixed(0)} kg/ha — apply urea at 25 kg/acre before next irrigation.',
          Icons.water, 'Medium', Colors.orange));
    } else {
      recs.add(_Recommendation('Nitrogen Healthy', 'N is at ${n.toStringAsFixed(0)} kg/ha, within range.',
          Icons.thumb_up_outlined, 'Good', Colors.green));
    }

    if (k >= 80) {
      recs.add(_Recommendation('Potassium Excellent', 'K is at ${k.toStringAsFixed(0)} kg/ha — continue current potash schedule.',
          Icons.thumb_up_outlined, 'Good', Colors.green));
    } else {
      recs.add(_Recommendation('Potassium Low', 'K is at ${k.toStringAsFixed(0)} kg/ha — consider potash application.',
          Icons.water, 'Medium', Colors.orange));
    }

    if (p < 40) {
      recs.add(_Recommendation('Phosphorus Low', 'P is at ${p.toStringAsFixed(0)} kg/ha — consider DAP application.',
          Icons.water, 'Medium', Colors.orange));
    }

    recs.add(_Recommendation('Organic Matter', om < 2.5 ? 'OM is low at ${om.toStringAsFixed(1)}% — add compost regularly.' : 'OM at ${om.toStringAsFixed(1)}% is healthy — maintain with compost every 2 months.',
        Icons.compost, om < 2.5 ? 'Medium' : 'Low', om < 2.5 ? Colors.orange : Colors.teal));

    recs.add(_Recommendation('Moisture', moisture < 30 ? 'Moisture at ${moisture.toStringAsFixed(0)}% is low — irrigate soon.' : 'Moisture at ${moisture.toStringAsFixed(0)}% is in range.',
        Icons.opacity, moisture < 30 ? 'High' : 'Low', moisture < 30 ? Colors.red : Colors.blue));

    return recs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0EA),
      body: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _anim, curve: Curves.easeOut),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
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
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
              SliverToBoxAdapter(child: _buildScoreCard()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(children: [
                    _tabBtn('Parameters', 0),
                    const SizedBox(width: 10),
                    _tabBtn('Recommendations', 1),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _tab == 0 ? _buildParams() : _buildRecs(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final source = _latest?.source;
    final statusLabel = !_isConnected
        ? 'Reconnecting…'
        : (source == 'sensor' ? 'Live · Sensor' : 'Live · Simulated');
    final statusColor = !_isConnected ? Colors.orangeAccent : Colors.greenAccent;
    final updated = _latest?.timestamp;
    final updatedLabel = updated == null ? 'Waiting for data…' : 'Updated: ${_formatTime(updated)}';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3E2723), Color(0xFF6D4C41)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Soil Analysis', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              _statusPill(statusColor, statusLabel),
            ],
          ),
          const SizedBox(height: 6),
          Text(updatedLabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _statusPill(Color dotColor, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      );

  String _formatTime(DateTime t) {
    final local = t.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // ── Score card ───────────────────────────────────────────────────────────
  Widget _buildScoreCard() {
    final score = _latest == null ? 0 : _healthScore;
    final params = _params;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(fit: StackFit.expand, children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: score / 100),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, _) => CircularProgressIndicator(
                  value: value,
                  backgroundColor: Colors.brown.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.brown.shade500),
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('$score', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF3E2723))),
                  const Text('/100', style: TextStyle(fontSize: 10, color: Colors.black38)),
                ]),
              ),
            ]),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Soil Health Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(
                  _latest == null
                      ? 'Waiting for first reading…'
                      : (score >= 80 ? 'Good — Minor improvements recommended' : score >= 60 ? 'Fair — Some parameters need attention' : 'Needs attention — Review recommendations'),
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  _miniStat('N', params[1].value.toStringAsFixed(0), Colors.blue),
                  _miniStat('P', params[2].value.toStringAsFixed(0), Colors.orange),
                  _miniStat('K', params[3].value.toStringAsFixed(0), Colors.purple),
                  _miniStat('pH', params[0].value.toStringAsFixed(1), Colors.green),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String val, Color color) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(children: [
          Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
        ]),
      );

  // ── Tab button ───────────────────────────────────────────────────────────
  Widget _tabBtn(String label, int idx) {
    final sel = _tab == idx;
    return GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF795548) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Text(label, style: TextStyle(color: sel ? Colors.white : Colors.black54, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  // ── Parameters tab ───────────────────────────────────────────────────────
  Widget _buildParams() {
    if (_latest == null) {
      return const Padding(
        key: ValueKey('params-loading'),
        padding: EdgeInsets.fromLTRB(16, 48, 16, 0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      key: const ValueKey('params'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(children: _params.map(_buildParamCard).toList()),
    );
  }

  Widget _buildParamCard(_SoilParam p) {
    final fraction = (p.value / p.max).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: () => _showDetail(p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: p.color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(p.icon, color: p.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const Spacer(),
                  Text('${p.unit == "" ? p.value.toStringAsFixed(1) : p.value.toStringAsFixed(0)}${p.unit}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: p.color, fontSize: 15)),
                ]),
                Text('Ideal: ${p.idealRange}', style: const TextStyle(color: Colors.black45, fontSize: 11)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fraction),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      backgroundColor: p.color.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(p.color),
                      minHeight: 7,
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.info_outline, color: Colors.black26, size: 16),
          ],
        ),
      ),
    );
  }

  void _showDetail(_SoilParam p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: p.color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(p.icon, color: p.color, size: 28)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('Current: ${p.value.toStringAsFixed(1)}${p.unit}  |  Ideal: ${p.idealRange}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ]),
          ]),
          const SizedBox(height: 20),
          Text(p.description, style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF795548), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Close'),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Recommendations tab ──────────────────────────────────────────────────
  Widget _buildRecs() {
    if (_latest == null) {
      return const Padding(
        key: ValueKey('recs-loading'),
        padding: EdgeInsets.fromLTRB(16, 48, 16, 0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      key: const ValueKey('recs'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(children: _recs.map(_buildRecCard).toList()),
    );
  }

  Widget _buildRecCard(_Recommendation r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: r.priorityColor.withOpacity(0.12), shape: BoxShape.circle), child: Icon(r.icon, color: r.priorityColor, size: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: r.priorityColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Text(r.priority, style: TextStyle(color: r.priorityColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 6),
            Text(r.description, style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.4)),
          ]),
        ),
      ]),
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

// ── Data models ──────────────────────────────────────────────────────────────

class _SoilParam {
  final String name;
  final double value;
  final double min;
  final double max;
  final String unit;
  final String idealRange;
  final Color color;
  final IconData icon;
  final String description;

  const _SoilParam(this.name, this.value, this.min, this.max, this.unit,
      this.idealRange, this.color, this.icon, this.description);
}

class _Recommendation {
  final String title;
  final String description;
  final IconData icon;
  final String priority;
  final Color priorityColor;

  const _Recommendation(this.title, this.description, this.icon, this.priority, this.priorityColor);
}