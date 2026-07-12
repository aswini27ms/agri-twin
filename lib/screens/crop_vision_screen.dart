import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../providers/app_providers.dart';
import 'chat_screen.dart';

class CropVisionScreen extends ConsumerStatefulWidget {
  const CropVisionScreen({super.key});

  @override
  ConsumerState<CropVisionScreen> createState() => _CropVisionScreenState();
}

class _CropVisionScreenState extends ConsumerState<CropVisionScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  String _selectedGrid = 'A1';
  double _cropAgeDays = 40;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Use real-time history from scanHistoryProvider in build()

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _analysisResult = null;
        _isAnalyzing = true;
      });
      
      try {
        final api = ref.read(apiServiceProvider);
        final bytes = await image.readAsBytes();
        final result = await api.scanCrop(
          bytes,
          image.name,
          _selectedGrid,
          _cropAgeDays.toInt(),
        );
        
        final pipeline = result['pipeline_result'];
        final isHealthy = pipeline['disease'] == 'Tomato_Healthy' || pipeline['disease'] == 'None detected';
        final statusColor = isHealthy ? const Color(0xFF4CAF50) : const Color(0xFFFF5722);
        
        // Call Groq API for Expert Insight
        String groqComment = '';
        try {
          final dio = Dio();
          final response = await dio.post(
            'https://api.groq.com/openai/v1/chat/completions',
            options: Options(
              headers: {
                'Authorization': 'Bearer YOUR_GROQ_API_KEY',
                'Content-Type': 'application/json',
              },
            ),
            data: {
              "model": "llama-3.1-8b-instant",
              "messages": [
                {
                  "role": "system",
                  "content": "You are a professional agronomist. Provide a concise, highly actionable 2-sentence insight about the disease. Be direct."
                },
                {
                  "role": "user",
                  "content": "My crop scan detected ${pipeline['disease']}. Risk is ${pipeline['risk_level']} (${pipeline['spread_risk']}%). Priority: ${pipeline['recommendation']['priority']}."
                }
              ]
            }
          );
          groqComment = response.data['choices'][0]['message']['content'];
        } catch (e) {
          groqComment = 'Could not fetch Groq AI insights: $e';
        }

        final analysis = {
            'status': pipeline['disease']?.replaceAll('_', ' ') ?? 'Unknown',
            'confidence': (pipeline['confidence'] * 100).toInt(),
            'statusColor': statusColor,
            'diseaseRaw': pipeline['disease'],
            'riskScore': pipeline['spread_risk'],
            'details': [
              {'key': 'Spread Risk', 'value': pipeline['risk_level'], 'ok': isHealthy},
              {'key': 'Risk Score', 'value': '${pipeline['spread_risk']}%', 'ok': isHealthy},
              {'key': 'Priority', 'value': pipeline['recommendation']['priority'], 'ok': isHealthy},
              {'key': 'Water Required', 'value': pipeline['recommendation']['water_required'], 'ok': pipeline['recommendation']['water_required'] == 'NO'},
            ],
            'recommendations': 'Pesticide: ${pipeline['recommendation']['pesticide']}\n\n'
                'Fertilizer: ${pipeline['recommendation']['fertilizer_guidance']}\n\n'
                'Nitrogen: ${pipeline['recommendation']['nitrogen_advice']}',
            'ai_comment': groqComment,
        };

        setState(() {
          _isAnalyzing = false;
          _analysisResult = analysis;
        });
        
        // Add to History
        final now = DateTime.now();
        final historyItem = {
          'crop': 'Grid $_selectedGrid',
          'date': '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
          'status': analysis['status'],
          'confidence': analysis['confidence'],
          'statusColor': statusColor,
        };
        ref.read(scanHistoryProvider.notifier).addScan(historyItem);
        
        // Refresh grid so it shows the newly scanned status
        ref.invalidate(twinGridProvider);
      } catch (e) {
        setState(() {
          _isAnalyzing = false;
          _analysisResult = {
            'status': 'Analysis Failed',
            'confidence': 0,
            'statusColor': Colors.red,
            'details': [],
            'recommendations': 'Error connecting to AI Diagnostic Chamber.\n\n$e',
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F0D),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                        const Text('Crop Vision AI', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.5)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, color: Color(0xFF4CAF50), size: 8),
                              SizedBox(width: 5),
                              Text('AI Ready', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('Scan your crops for instant disease & health detection', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
            ),

            // Config area
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _buildConfigArea(),
              ),
            ),

            // Camera / image view area
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildScanArea(),
              ),
            ),

            // Action buttons
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _actionBtn(Icons.camera_alt, 'Take Photo', () => _pickImage(ImageSource.camera)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionBtn(Icons.photo_library_outlined, 'Gallery', () => _pickImage(ImageSource.gallery)),
                    ),
                  ],
                ),
              ),
            ),

            // Analysis result
            if (_isAnalyzing || _analysisResult != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildAnalysisResult(),
                ),
              ),

            // Recent scans
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Consumer(
                  builder: (context, ref, child) {
                    final recentScans = ref.watch(scanHistoryProvider);
                    if (recentScans.isEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Recent Scans', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text('No scans yet in this session.', style: TextStyle(color: Colors.white38)),
                            ),
                          )
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recent Scans', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...recentScans.map((scan) => _buildRecentScan(scan)),
                      ],
                    );
                  }
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigArea() {
    final grids = ref.watch(twinGridProvider).valueOrNull ?? [];
    final gridIds = grids.map((g) => g.gridId).toList();
    if (gridIds.isEmpty) {
      gridIds.addAll(['A1', 'A2', 'B1', 'B2', 'C1']);
    }
    
    // Ensure _selectedGrid is in the list
    if (!gridIds.contains(_selectedGrid)) {
      _selectedGrid = gridIds.first;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Target Grid:', style: TextStyle(color: Colors.white70)),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedGrid,
                dropdownColor: const Color(0xFF1A3A1A),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                underline: const SizedBox(),
                items: gridIds.map((id) => DropdownMenuItem(value: id, child: Text(id))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedGrid = val);
                },
              ),
            ],
          ),
          Row(
            children: [
              const Text('Crop Age (days):', style: TextStyle(color: Colors.white70)),
              Expanded(
                child: Slider(
                  value: _cropAgeDays,
                  min: 1,
                  max: 120,
                  activeColor: const Color(0xFF4CAF50),
                  inactiveColor: const Color(0xFF4CAF50).withOpacity(0.3),
                  onChanged: (val) => setState(() => _cropAgeDays = val),
                ),
              ),
              Text('${_cropAgeDays.toInt()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanArea() {
    return GestureDetector(
      onTap: () => _pickImage(ImageSource.camera),
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: _selectedImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  kIsWeb
                      ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                      : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                  
                  // Holographic scanning line effect
                  if (_isAnalyzing)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Stack(
                            children: [
                              Positioned(
                                top: _pulseController.value * 260,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50),
                                    boxShadow: [
                                      BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.8), blurRadius: 10, spreadRadius: 3),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                  if (_isAnalyzing)
                    Container(
                      color: Colors.black45,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ScaleTransition(
                              scale: _pulseAnim,
                              child: const Icon(Icons.document_scanner, color: Color(0xFF4CAF50), size: 48),
                            ),
                            const SizedBox(height: 12),
                            const Text('Analyzing Structure...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const CircularProgressIndicator(color: Color(0xFF4CAF50), strokeWidth: 2),
                          ],
                        ),
                      ),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF4CAF50), size: 44),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tap to scan your crop', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text('Supports: leaves, stems, fruits, soil', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A3A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF4CAF50), size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResult() {
    if (_isAnalyzing) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A3A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
        ),
        child: const Center(
          child: Text('Processing image with AI...', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    final result = _analysisResult!;
    final statusColor = result['statusColor'] as Color;
    final details = result['details'] as List;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: statusColor, size: 20),
              const SizedBox(width: 8),
              const Text('Analysis Result', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(result['status'] as String, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Confidence: ${result['confidence']}%', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 16),
          ...details.map((d) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(d['ok'] ? Icons.check_circle : Icons.warning, color: d['ok'] ? Colors.green : Colors.orange, size: 16),
                const SizedBox(width: 8),
                Text('${d['key']}: ', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text(d['value'] as String, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          )),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: Color(0xFFFFC107), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(result['recommendations'] as String, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4))),
              ],
            ),
          ),
          
          if (result['ai_comment'] != null && result['ai_comment'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF4CAF50).withOpacity(0.15), Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Color(0xFF4CAF50), size: 18),
                      SizedBox(width: 8),
                      Text('Groq AI Agronomist', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(result['ai_comment'] as String, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final prompt = "My Crop Vision scan just detected ${result['diseaseRaw']} on Grid $_selectedGrid with a Spread Risk of ${result['riskScore']}%. What should I do immediately?";
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatScreen(initialPrompt: prompt)),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white),
              label: const Text('Discuss with AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScan(Map<String, dynamic> scan) {
    final statusColor = scan['statusColor'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.eco, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scan['crop'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(scan['date'] as String, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(scan['status'] as String, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('${scan['confidence']}% confident', style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
