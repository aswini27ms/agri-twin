import 'dart:io';
import 'package:dio/dio.dart';

void main(List<String> args) async {
  final baseUrl = args.isNotEmpty ? args[0] : 'http://127.0.0.1:8080';
  final imagePath = args.length > 1 ? args[1] : 'test_assets/sample_crop.jpg';
  final audioPath = args.length > 2 ? args[2] : 'test_assets/sample_voice.wav';

  print("====================================================");
  print("AgriEdge AI - Local Hub Integration Contract Verifier");
  print("Target Host IP : $baseUrl");
  print("Sample Image   : $imagePath");
  print("Sample Audio   : $audioPath");
  print("====================================================\n");

  // Standardized connectTimeout (3s) and receiveTimeout (5s)
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 5),
  ));

  int passedCount = 0;
  int totalTests = 7;
  int skippedCount = 0;
  bool hasFailed = false;

  // --- [1] GET /fields ---
  print("[1] Testing GET /fields...");
  try {
    final response = await dio.get('$baseUrl/fields');
    if (response.statusCode == 200) {
      print("  ✓ SUCCESS: Received 200 OK");
      print("  ✓ Payload structure: ${response.data.runtimeType}");
      print("  ✓ Fields found: ${(response.data as List).length}");
      passedCount++;
    } else {
      print("  ✗ FAILURE: Server returned code ${response.statusCode}");
      hasFailed = true;
    }
  } catch (e) {
    print("  ✗ FAILURE: Request failed. Error details: $e");
    hasFailed = true;
  }
  print("");

  // --- [2] GET /soil ---
  print("[2] Testing GET /soil...");
  try {
    final response = await dio.get('$baseUrl/soil');
    if (response.statusCode == 200) {
      print("  ✓ SUCCESS: Soil telemetry received");
      print("  ✓ Data: ${response.data}");
      final n = response.data['nitrogen'];
      final p = response.data['phosphorus'];
      final k = response.data['potassium'];
      final m = response.data['moisture'];
      print("  ✓ NPK: ($n, $p, $k) ppm | Moisture: $m%");
      if (n == null || p == null || k == null || m == null) {
        print("  ⚠ WARNING: Payload fields (nitrogen, phosphorus, potassium, moisture) are missing!");
      }
      passedCount++;
    } else {
      print("  ✗ FAILURE: Server returned code ${response.statusCode}");
      hasFailed = true;
    }
  } catch (e) {
    print("  ✗ FAILURE: Request failed. Error details: $e");
    hasFailed = true;
  }
  print("");

  // --- [3] POST /diagnose ---
  print("[3] Testing POST /diagnose (Multipart Image Upload)...");
  final imageFile = File(imagePath);
  if (!imageFile.existsSync()) {
    print("  ⚠ SKIPPED — no sample image file found at $imagePath");
    skippedCount++;
  } else {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath, filename: 'crop_leaf.jpg'),
      });
      final response = await dio.post('$baseUrl/diagnose', data: formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final disease = data['disease'];
        final confidence = data['confidence'];
        print("  ✓ SUCCESS: Crop diagnosis received");
        print("  ✓ Disease: $disease");
        print("  ✓ Confidence: $confidence");
        
        if (disease is String && confidence is num && confidence >= 0.0 && confidence <= 1.0) {
          print("  ✓ Fields validated correctly");
          passedCount++;
        } else {
          print("  ✗ FAILURE: Response validation failed. Got disease: $disease (String?), confidence: $confidence (num between 0-1?)");
          hasFailed = true;
        }
      } else {
        print("  ✗ FAILURE: Server returned code ${response.statusCode}");
        hasFailed = true;
      }
    } catch (e) {
      print("  ✗ FAILURE: Request failed. Error details: $e");
      hasFailed = true;
    }
  }
  print("");

  // --- [4] POST /voice ---
  print("[4] Testing POST /voice (Multipart Audio Upload)...");
  final audioFile = File(audioPath);
  if (!audioFile.existsSync()) {
    print("  ⚠ SKIPPED — no sample audio file found at $audioPath");
    skippedCount++;
  } else {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(audioPath, filename: 'farmer_query.wav'),
      });
      final response = await dio.post('$baseUrl/voice', data: formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final transcription = data['transcribedText'];
        print("  ✓ SUCCESS: Voice response received");
        print("  ✓ Transcribed: \"$transcription\"");
        
        if (transcription is String && transcription.trim().isNotEmpty) {
          print("  ✓ Fields validated correctly");
          passedCount++;
        } else {
          print("  ✗ FAILURE: Response validation failed. transcribedText is empty or missing.");
          hasFailed = true;
        }
      } else {
        print("  ✗ FAILURE: Server returned code ${response.statusCode}");
        hasFailed = true;
      }
    } catch (e) {
      print("  ✗ FAILURE: Request failed. Error details: $e");
      hasFailed = true;
    }
  }
  print("");

  // --- [5] GET /twin/{fieldId} ---
  print("[5] Testing GET /twin/field_1...");
  try {
    final response = await dio.get('$baseUrl/twin/field_1');
    if (response.statusCode == 200) {
      print("  ✓ SUCCESS: Twin state loaded");
      print("  ✓ Health Score: ${response.data['healthScore']}");
      print("  ✓ Risk Projection: ${response.data['riskProjection']}");
      final trendHistory = response.data['trendHistory'];
      final trendLength = trendHistory is List ? trendHistory.length : 0;
      print("  ✓ Historical Trend Length: $trendLength");
      passedCount++;
    } else {
      print("  ✗ FAILURE: Server returned code ${response.statusCode}");
      hasFailed = true;
    }
  } catch (e) {
    print("  ✗ FAILURE: Request failed. Error details: $e");
    hasFailed = true;
  }
  print("");

  // --- [6] POST /twin/{fieldId}/simulate ---
  print("[6] Testing POST /twin/field_1/simulate...");
  try {
    final response = await dio.post(
      '$baseUrl/twin/field_1/simulate',
      data: {'scenario': 'irrigation'},
    );
    if (response.statusCode == 200) {
      print("  ✓ SUCCESS: Simulation response received");
      print("  ✓ Projected Health: ${response.data['healthScore']}");
      print("  ✓ Projected Risk: ${response.data['riskProjection']}");
      print("  ✓ Projected Trend: ${response.data['trendHistory'] ?? []}");
      passedCount++;
    } else {
      print("  ✗ FAILURE: Server returned code ${response.statusCode}");
      hasFailed = true;
    }
  } catch (e) {
    print("  ✗ FAILURE: Request failed. Error details: $e");
    hasFailed = true;
  }
  print("");

  // --- [7] POST /advice ---
  print("[7] Testing POST /advice (LLM Chat/Remedy Query)...");
  try {
    final response = await dio.post(
      '$baseUrl/advice',
      data: {
        'disease': 'Tomato Early Blight',
        'soilData': {'nitrogen': 40, 'phosphorus': 30, 'potassium': 50, 'moisture': 35},
        'language': 'en',
      },
    );
    if (response.statusCode == 200) {
      final adviceText = response.data['adviceText']?.toString() ?? '';
      // Safe truncation to avoid crash if advice string is shorter than 80 chars
      final truncated = adviceText.length > 80 ? '${adviceText.substring(0, 80)}...' : adviceText;
      print("  ✓ SUCCESS: LLM Advice generated");
      print("  ✓ Advice Output: $truncated");
      passedCount++;
    } else {
      print("  ✗ FAILURE: Server returned code ${response.statusCode}");
      hasFailed = true;
    }
  } catch (e) {
    print("  ✗ FAILURE: Request failed. Error details: $e");
    hasFailed = true;
  }
  print("\n====================================================");
  final effectiveTotal = totalTests - skippedCount;
  print("Result: $passedCount/$effectiveTotal endpoints passing${skippedCount > 0 ? ' ($skippedCount skipped)' : ''}");
  print("====================================================");

  if (hasFailed) {
    exit(1);
  } else {
    exit(0);
  }
}
