class ChatMessage {
  final String sender; // 'user' or 'ai'
  final String message;
  final DateTime timestamp;

  ChatMessage({required this.sender, required this.message, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'sender': sender,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    sender: json['sender'] as String,
    message: json['message'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class Diagnosis {
  final String id;
  final String imagePath;
  final String disease;
  final double confidence;
  final String adviceText;
  final DateTime timestamp;
  final List<ChatMessage> chatHistory;
  final String fieldId;

  Diagnosis({
    required this.id,
    required this.imagePath,
    required this.disease,
    required this.confidence,
    required this.adviceText,
    required this.timestamp,
    required this.chatHistory,
    required this.fieldId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'disease': disease,
    'confidence': confidence,
    'adviceText': adviceText,
    'timestamp': timestamp.toIso8601String(),
    'chatHistory': chatHistory.map((e) => e.toJson()).toList(),
    'fieldId': fieldId,
  };

  factory Diagnosis.fromJson(Map<String, dynamic> json) => Diagnosis(
    id: json['id'] as String,
    imagePath: json['imagePath'] as String,
    disease: json['disease'] as String,
    confidence: (json['confidence'] as num).toDouble(),
    adviceText: json['adviceText'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    chatHistory: (json['chatHistory'] as List?)
            ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    fieldId: json['fieldId'] as String? ?? 'default',
  );
}
