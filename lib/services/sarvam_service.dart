import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'cache_service.dart';

class SarvamService {
  final CacheService _cacheService;
  final Dio _dio;
  final AudioPlayer _audioPlayer = AudioPlayer();

  SarvamService(this._cacheService)
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://api.sarvam.ai',
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
        ));

  // We map the short locale names ('hi', 'ta', 'te', 'en') to the format Sarvam AI requires ('hi-IN', etc.)
  String _mapLanguageCode(String code) {
    switch (code) {
      case 'hi':
        return 'hi-IN';
      case 'ta':
        return 'ta-IN';
      case 'te':
        return 'te-IN';
      default:
        return 'en-IN';
    }
  }

  Future<String> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    final apiKey = _getSarvamApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      // Mock translation offline/no-key mode
      return _mockTranslation(text, sourceLang, targetLang);
    }

    try {
      final response = await _dio.post(
        '/translate',
        data: {
          'input': text,
          'source_language_code': _mapLanguageCode(sourceLang),
          'target_language_code': _mapLanguageCode(targetLang),
        },
        options: Options(
          headers: {
            'api-subscription-key': apiKey,
            'Content-Type': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200) {
        return response.data['translated_text'] as String;
      }
    } catch (e) {
      print('Sarvam translation error: $e');
    }
    return _mockTranslation(text, sourceLang, targetLang);
  }

  Future<Uint8List?> textToSpeech({
    required String text,
    required String languageCode,
  }) async {
    final apiKey = _getSarvamApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    try {
      final response = await _dio.post(
        '/text-to-speech',
        data: {
          'text': text,
          'target_language_code': _mapLanguageCode(languageCode),
          'speaker': 'shubh',
          'model': 'bulbul:v3',
        },
        options: Options(
          headers: {
            'api-subscription-key': apiKey,
            'Content-Type': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200) {
        final audios = response.data['audios'] as List?;
        if (audios != null && audios.isNotEmpty) {
          final base64String = audios.first as String;
          return base64Decode(base64String);
        }
      }
    } catch (e) {
      print('Sarvam TTS error: $e');
    }
    return null;
  }

  Future<void> playAudioBytes(Uint8List bytes) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(BytesSource(bytes));
    } catch (e) {
      print('Error playing audio bytes: $e');
    }
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
  }

  // Internal helper to access API Key
  String? _getSarvamApiKey() {
    try {
      // Let's implement getSarvamApiKey directly in CacheService.
      return (_cacheService as dynamic).getSarvamApiKey() as String?;
    } catch (_) {
      return null;
    }
  }

  String _mockTranslation(String text, String source, String target) {
    if (source == target) return text;
    final lower = text.toLowerCase();
    
    // Hindi fallback responses
    if (target == 'hi') {
      if (lower.contains('fertilizer') || lower.contains('khad')) {
        return "फसल के बेहतर स्वास्थ्य के लिए प्रति एकड़ 50 किलोग्राम यूरिया और 30 किलोग्राम डीएपी का छिड़काव करें।";
      }
      if (lower.contains('water') || lower.contains('irrigate')) {
        return "मिट्टी में अभी नमी मध्यम है, अगली सिंचाई 3 दिनों के बाद सुबह के समय करें।";
      }
      if (lower.contains('hello') || lower.contains('hi')) {
        return "नमस्कार! मैं कृषि मित्र हूँ। आज मैं आपकी क्या सहायता कर सकता हूँ?";
      }
      return "धन्यवाद! कृषि मित्र आपके प्रश्न \"$text\" पर कार्य कर रहा है। कृपया नियमित रूप से मिट्टी की नमी की जांच करें।";
    }

    // Tamil fallback responses
    if (target == 'ta') {
      if (lower.contains('fertilizer') || lower.contains('உரம்')) {
        return "பயிரின் சிறந்த வளர்ச்சிக்கு ஏக்கருக்கு 50 கிலோ யூரியா மற்றும் 30 கிலோ டிஏபி இட பரிந்துரைக்கப்படுகிறது.";
      }
      if (lower.contains('water') || lower.contains('தண்ணீர்')) {
        return "மண்ணில் தற்போது ஈரப்பதம் மிதமாக உள்ளது, அடுத்த நீர் பாசனத்தை 3 நாட்களுக்குப் பிறகு காலையில் செய்யவும்.";
      }
      if (lower.contains('hello') || lower.contains('வணக்கம்')) {
        return "வணக்கம்! நான் கிருஷிமித்ரா. உங்களுக்கு இன்று நான் எவ்வாறு உதவ முடியும்?";
      }
      return "நன்றி! உங்கள் கேள்வி \"$text\" குறித்து கிருஷிமித்ரா பதிலளிக்கிறது. மண்ணின் ஈரப்பதத்தை தொடர்ந்து கண்காணிக்கவும்.";
    }

    // Telugu fallback responses
    if (target == 'te') {
      if (lower.contains('fertilizer') || lower.contains('ఎరువు')) {
        return "పంట మంచి ఎదుగుదలకు ఎకరానికి 50 కిలోల యూరియా మరియు 30 కిలోల డీఏపీ వేయాలని సిఫార్సు చేయబడింది.";
      }
      if (lower.contains('water') || lower.contains('నీరు')) {
        return "ప్రస్తుతం నేలలో తేమ ఓ మోస్తరుగా ఉంది, తదుపరి నీటి తడిని 3 రోజుల తర్వాత ఉదయాన్నే అందించండి.";
      }
      if (lower.contains('hello') || lower.contains('నమస్కారం')) {
        return "నమస్కారం! నేను కృషిమిత్ర. మీకు ఈరోజు నేను ఎలా సహాయపడగలను?";
      }
      return "ధన్యవాదాలు! కృషిమిత్ర మీ ప్రశ్నకు \"$text\" సమాధానమిస్తోంది. నేల తేమను క్రమం తప్పకుండా గమనించండి.";
    }

    // English fallbacks
    if (target == 'en') {
      if (lower.contains('fertilizer') || lower.contains('fertilize')) {
        return "For optimal growth, apply 50 kg of Urea and 30 kg of DAP per acre.";
      }
      if (lower.contains('water') || lower.contains('irrigation') || lower.contains('irrigate')) {
        return "Soil moisture is moderate. Schedule the next irrigation session in 3 days during the early morning.";
      }
      return "Hello! I am KrishiMitra, your agricultural assistant. I'm processing your query: \"$text\".";
    }

    return text;
  }
}
