import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? initialPrompt;
  const ChatScreen({super.key, this.initialPrompt});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _gemmaReady = false;
  bool _checkingStatus = true;
  Timer? _statusTimer;

  // Quick prompt chips
  final List<String> _quickPrompts = [
    'Farm health summary',
    'Any diseases detected?',
    'Irrigation advice',
    'Yield forecast',
    'Pest risk today',
  ];

  @override
  void initState() {
    super.initState();
    _checkGemmaStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_gemmaReady) {
        _checkGemmaStatus();
      }
    });
    if (widget.initialPrompt != null) {
      _controller.text = widget.initialPrompt!;
    }
    _loadHistory();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Gemma status polling ─────────────────────────────────────────────────

  Future<void> _checkGemmaStatus() async {
    setState(() => _checkingStatus = true);
    final api = ref.read(apiServiceProvider);
    final status = await api.getGemmaStatus();
    final ready = status['ollama_running'] == true || status['gemma_ready'] == true;
    if (mounted) {
      setState(() {
        _gemmaReady = ready;
        _checkingStatus = false;
      });
    }
    // If not ready, keep polling every 5s until Gemma comes up
    if (!ready) {
      _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        final s = await api.getGemmaStatus();
        final r = s['ollama_running'] == true || s['gemma_ready'] == true;
        if (mounted) {
          setState(() => _gemmaReady = r);
          if (r) {
            _statusTimer?.cancel();
            _showSnack('🤖 Gemma is online! You can now chat.', Colors.green);
          }
        }
      });
    }
  }

  // ── Load history ─────────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    try {
      final api = ref.read(apiServiceProvider);
      final history = await api.getChatHistory();
      if (mounted && history.isNotEmpty) {
        setState(() {
          _messages = history.map((h) => _ChatMessage(
            role: h['role'] ?? 'assistant',
            text: h['text'] ?? '',
          )).toList();
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  // ── Send message ─────────────────────────────────────────────────────────

  void _sendMessage([String? overrideText]) async {
    final text = (overrideText ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(role: 'user', text: text));
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    final api = ref.read(apiServiceProvider);
    try {
      final reply = await api.sendChatMessage(text, null);
      setState(() => _messages.add(_ChatMessage(role: 'assistant', text: reply)));
    } catch (e) {
      final errStr = e.toString().replaceFirst('Exception: ', '');
      final isWarmup = errStr.toLowerCase().contains('starting up') ||
          errStr.toLowerCase().contains('offline');
      setState(() => _messages.add(_ChatMessage(
        role: 'assistant',
        text: errStr,
        isError: true,
        isWarmup: isWarmup,
      )));
      if (isWarmup && !_gemmaReady) _checkGemmaStatus();
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            if (!_gemmaReady) _buildWarmupBanner(),
            Expanded(child: _buildMessageList()),
            if (_isLoading) _buildTypingIndicator(),
            _buildQuickPrompts(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B421A), Color(0xFF1A7A30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_outlined, color: Color(0xFF00FF87), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AgriTwin AI',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                Row(children: [
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: _checkingStatus ? Colors.yellow : (_gemmaReady ? const Color(0xFF00FF87) : Colors.red.shade300),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _checkingStatus ? 'Checking…' : (_gemmaReady ? 'Online · Gemma 2 9B' : 'Warming up…'),
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  if (!_gemmaReady && !_checkingStatus) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _checkGemmaStatus,
                      child: const Text('Retry', style: TextStyle(color: Color(0xFF00FF87), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ]),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
            onPressed: _checkGemmaStatus,
            tooltip: 'Refresh status',
          ),
        ],
      ),
    );
  }

  // ── Warmup banner ────────────────────────────────────────────────────────

  Widget _buildWarmupBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFFFF3CD),
      child: Row(
        children: [
          const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF856404)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Gemma is loading — this takes 10–30s on first start. Your message will send automatically once ready.',
              style: TextStyle(color: Color(0xFF856404), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Message list ─────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    if (_messages.isEmpty) return _buildEmptyState();
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF008000).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.agriculture_outlined, color: Color(0xFF008000), size: 48),
          ),
          const SizedBox(height: 20),
          Text('Ask anything about your farm',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text('Crop health · Disease analysis · Irrigation · Yield',
            style: TextStyle(color: Colors.black45, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF008000)
              : msg.isError
                  ? const Color(0xFFFFF3CD)
                  : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
          border: msg.isError ? Border.all(color: const Color(0xFFFFD700), width: 1) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.isError && msg.isWarmup)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  const Icon(Icons.hourglass_top, size: 14, color: Color(0xFF856404)),
                  const SizedBox(width: 4),
                  Text('Gemma is warming up', style: TextStyle(color: const Color(0xFF856404), fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
            Text(
              msg.text,
              style: TextStyle(
                color: isUser ? Colors.white : (msg.isError ? const Color(0xFF856404) : const Color(0xFF1E293B)),
                fontSize: 14.5,
                height: 1.45,
              ),
            ),
            if (msg.isError && msg.isWarmup) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _sendMessage(_messages.reversed
                    .firstWhere((m) => m.role == 'user', orElse: () => _ChatMessage(role: 'user', text: ''))
                    .text),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF008000),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Retry', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Typing indicator ─────────────────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _dot(0),
          const SizedBox(width: 4),
          _dot(150),
          const SizedBox(width: 4),
          _dot(300),
        ]),
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: Duration(milliseconds: 600 + delayMs),
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(color: Color(0xFF008000), shape: BoxShape.circle),
        ),
      ),
    );
  }

  // ── Quick prompts ─────────────────────────────────────────────────────────

  Widget _buildQuickPrompts() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _quickPrompts.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _sendMessage(_quickPrompts[i]),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF008000).withOpacity(0.3)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
            ),
            child: Text(_quickPrompts[i], style: const TextStyle(color: Color(0xFF008000), fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  // ── Input bar ────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Colors.black12)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: _gemmaReady ? 'Ask about your farm…' : 'Gemma is warming up…',
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: (_isLoading || !_gemmaReady) ? Colors.grey.shade300 : const Color(0xFF008000),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isLoading ? Icons.hourglass_top : Icons.send_rounded,
                color: (_isLoading || !_gemmaReady) ? Colors.grey : Colors.white,
                size: 22,
              ),
              onPressed: (_isLoading || !_gemmaReady) ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _ChatMessage {
  final String role;
  final String text;
  final bool isError;
  final bool isWarmup;

  _ChatMessage({
    required this.role,
    required this.text,
    this.isError = false,
    this.isWarmup = false,
  });
}
