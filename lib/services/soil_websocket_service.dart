import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import '../models/soil_data.dart';

/// Handles live soil data delivery:
/// - Connects to `ws://<host>/soil/ws` for real-time push
/// - Auto-reconnects with backoff if the connection drops
/// - Falls back to `GET /soil/latest` once on startup so the UI has
///   something to show before the first WebSocket message arrives
class SoilWebSocketService {
  final String baseHttpUrl; // e.g. http://10.0.2.2:8000
  final String baseWsUrl; // e.g. ws://10.0.2.2:8000

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _manuallyClosed = false;
  int _reconnectAttempt = 0;

  final _dataController = StreamController<SoilData>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<SoilData> get dataStream => _dataController.stream;
  Stream<bool> get connectionStream => _connectionController.stream; // true = live

  SoilWebSocketService({required this.baseHttpUrl, required this.baseWsUrl});

  Future<void> start() async {
    _manuallyClosed = false;
    await _fetchInitial();
    _connect();
  }

  Future<void> _fetchInitial() async {
    try {
      final res = await http
          .get(Uri.parse('$baseHttpUrl/soil/latest'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        _dataController.add(SoilData.fromJson(json));
      }
    } catch (_) {
      // Silent — WebSocket connect will follow and populate data anyway
    }
  }

  void _connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('$baseWsUrl/soil/ws'));
      _channel!.stream.listen(
        (message) {
          _reconnectAttempt = 0;
          _connectionController.add(true);
          try {
            final json = jsonDecode(message as String) as Map<String, dynamic>;
            _dataController.add(SoilData.fromJson(json));
          } catch (_) {
            // ignore malformed frame
          }
        },
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _connectionController.add(false);
    if (_manuallyClosed) return;
    _reconnectAttempt++;
    final delaySeconds = _reconnectAttempt.clamp(1, 10); // simple backoff, max 10s
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), _connect);
  }

  void dispose() {
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close(ws_status.goingAway);
    _dataController.close();
    _connectionController.close();
  }
}