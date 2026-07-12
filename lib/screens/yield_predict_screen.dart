import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../providers/app_providers.dart';
import 'package:fl_chart/fl_chart.dart';

class YieldPredictScreen extends ConsumerStatefulWidget {
  const YieldPredictScreen({super.key});

  @override
  ConsumerState<YieldPredictScreen> createState() => _YieldPredictScreenState();
}

class _YieldPredictScreenState extends ConsumerState<YieldPredictScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _countAnim;

  String _selectedCrop = 'Sweet Corn';
  final List<String> _crops = ['Sweet Corn', 'Roma Tomato', 'Rice', 'Wheat'];

  bool _isLoading = true;
  Map<String, dynamic>? _predictionData;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _countAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _fetchPrediction();
  }

  Future<void> _fetchPrediction() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getYieldPrediction(_selectedCrop);
      final factors = List<Map<String, dynamic>>.from(data['factors']).map((f) => {
        'label': f['label'],
        'score': f['score'],
        'color': Color(f['color'] as int),
      }).toList();
      
      if (mounted) {
        setState(() {
          _predictionData = {
            'predicted': (data['predicted'] as num).toDouble(),
            'unit': data['unit'],
            'lastYear': (data['lastYear'] as num).toDouble(),
            'confidence': data['confidence'],
            'grade': data['grade'],
            'gradeColor': Color(data['gradeColor'] as int),
            'factors': factors,
            'monthly': List<double>.from((data['monthly'] as List).map((e) => (e as num).toDouble())),
          };
          _isLoading = false;
        });
        _animController.reset();
        _animController.forward();
      }
    } catch (e) {
      // In case of error, just set loading false and it will show empty/error state or we could show snackbar
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _predictionData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1240),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
        ),
      );
    }

    final data = _predictionData!;
    final predicted = data['predicted'] as double;
    final lastYear = data['lastYear'] as double;
    final change = ((predicted - lastYear) / lastYear * 100).toStringAsFixed(1);
    final gradeColor = data['gradeColor'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1240),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E1760), Color(0xFF4527A0)],
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
                        const Text('Yield Prediction', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('AI Model v2.1', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Crop selector
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _crops.map((crop) {
                          final selected = _selectedCrop == crop;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCrop = crop;
                                _fetchPrediction();
                              });
                              _animController.reset();
                              _animController.forward();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? Colors.white : Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                crop,
                                style: TextStyle(
                                  color: selected ? const Color(0xFF4527A0) : Colors.white70,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Big yield number
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedBuilder(
                          animation: _countAnim,
                          builder: (_, __) => Text(
                            (predicted * _countAnim.value).toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w200, letterSpacing: -2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(data['unit'] as String, style: const TextStyle(color: Colors.white60, fontSize: 16)),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: gradeColor.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: gradeColor.withOpacity(0.5)),
                              ),
                              child: Text('Grade ${data['grade']}', style: TextStyle(color: gradeColor, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.trending_up, color: Colors.green.shade300, size: 14),
                                const SizedBox(width: 4),
                                Text('+$change% vs last year', style: TextStyle(color: Colors.green.shade300, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text('Predicted yield for $_selectedCrop', style: const TextStyle(color: Colors.white60, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Confidence: ${data['confidence']}%', style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12)),
                  ],
                ),
              ),
            ),

            // Monthly projection chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Yield Projection Curve', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      height: 180,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            getDrawingHorizontalLine: (_) => const FlLine(color: Colors.white10, strokeWidth: 1),
                            getDrawingVerticalLine: (_) => const FlLine(color: Colors.transparent),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 36,
                                getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                  final idx = v.toInt();
                                  if (idx >= 0 && idx < months.length) {
                                    return Text(months[idx], style: const TextStyle(color: Colors.white38, fontSize: 10));
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: (data['monthly'] as List).asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value as double)).toList(),
                              isCurved: true,
                              gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFFE040FB)]),
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [const Color(0xFF9C27B0).withOpacity(0.3), const Color(0xFF9C27B0).withOpacity(0.0)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Yield factors
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Yield Factors', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    ...(data['factors'] as List).map((f) {
                      final factor = f as Map<String, dynamic>;
                      final score = factor['score'] as int;
                      final color = factor['color'] as Color;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(factor['label'] as String, style: const TextStyle(color: Colors.white70)),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: score / 100,
                                  backgroundColor: color.withOpacity(0.15),
                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('$score%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Comparison box
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _comparisonStat('Last Year', '${data['lastYear']} ${data['unit']}', Colors.white54)),
                      Container(width: 1, height: 40, color: Colors.white12),
                      Expanded(child: _comparisonStat('This Season', '${data['predicted']} ${data['unit']}', gradeColor)),
                      Container(width: 1, height: 40, color: Colors.white12),
                      Expanded(child: _comparisonStat('Growth', '+$change%', Colors.green.shade300)),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _comparisonStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11), textAlign: TextAlign.center),
      ],
    );
  }
}
