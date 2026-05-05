import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:powerlog/app/config/app_config.dart';
import 'package:powerlog/data/models/chat_message_model.dart';

class ChatController extends GetxController {
  // ── State ─────────────────────────────────────────────────────────────────
  final messages = <ChatMessage>[].obs;
  final isTyping = false.obs;

  // ── Form ──────────────────────────────────────────────────────────────────
  final inputCtrl = TextEditingController();
  final scrollCtrl = ScrollController();

  // ── Gemini ────────────────────────────────────────────────────────────────
  ChatSession? _chat;
  bool _apiKeyMissing = false;

  static const _systemPrompt = '''
You are an AI-powered Energy Saving Consultant embedded in the PowerLog app.
Your ONLY role is to help users with electricity and energy-related topics, including:
- Electricity usage optimization and energy saving strategies
- Understanding kWh consumption and electricity billing in Indonesia
- Recommending energy-efficient appliances and habits
- Explaining PLN tariffs, time-of-use pricing, and subsidy programs
- Tips for reducing electricity costs at home or in a business
- Explaining renewable energy options (solar panels, etc.)

If a user asks about anything outside of energy/electricity topics, politely decline
and redirect them back to energy consulting. Keep answers concise and practical.
Always respond in the same language the user writes in (Indonesian or English).
''';

  @override
  void onInit() {
    super.onInit();
    _initGemini();
    _addWelcome();
  }

  @override
  void onClose() {
    inputCtrl.dispose();
    scrollCtrl.dispose();
    super.onClose();
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  void _initGemini() {
    final apiKey = AppConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      _apiKeyMissing = true;
      return;
    }
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_systemPrompt),
    );
    _chat = model.startChat();
  }

  void _addWelcome() {
    messages.add(ChatMessage(
      text:
          "👋 Hi! I'm your **Energy Saving Consultant**.\n\nAsk me anything about:\n• Reducing electricity bills\n• kWh usage tips\n• PLN tariffs in Indonesia\n• Energy-efficient habits",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> sendMessage() async {
    final text = inputCtrl.text.trim();
    if (text.isEmpty || isTyping.value) return;

    if (_apiKeyMissing || _chat == null) {
      messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      inputCtrl.clear();
      messages.add(ChatMessage(
        text: 'API key is missing. Provide GEMINI_API_KEY via --dart-define.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _scrollToBottom();
      return;
    }

    messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
    inputCtrl.clear();
    isTyping.value = true;
    _scrollToBottom();

    int retries = 2;
    try {
      while (retries >= 0) {
        try {
          final response = await _chat!.sendMessage(Content.text(text));
          final reply = response.text ?? 'Sorry, I could not generate a response.';
          messages.add(ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()));
          break; // Success
        } catch (e) {
          final errStr = e.toString();
          final isHighDemand = errStr.contains('503') ||
              errStr.contains('high demand') ||
              errStr.contains('UNAVAILABLE');
          final isRateLimit = errStr.contains('429') ||
              errStr.contains('RESOURCE_EXHAUSTED') ||
              errStr.contains('rate limit');
          final isTimeout = errStr.contains('timed out') ||
              errStr.contains('Timeout') ||
              errStr.contains('deadline');
          final isOffline = errStr.contains('SocketException') ||
              errStr.contains('Failed host lookup') ||
              errStr.contains('Network is unreachable');

          if (isHighDemand && retries > 0) {
            retries--;
            await Future.delayed(const Duration(seconds: 2));
            continue; // Retry on 503
          }

          final isKeyError = errStr.contains('API_KEY') ||
              errStr.contains('invalid') ||
              errStr.contains('403') ||
              errStr.contains('UNAUTHENTICATED') ||
              errStr.contains('PERMISSION_DENIED');

          final isSafety = errStr.contains('SAFETY') ||
              errStr.contains('safety') ||
              errStr.contains('blocked');

          String errorMsg;
          if (isKeyError) {
            errorMsg = '⚠️ Invalid API key. Please update AppConfig.';
          } else if (isHighDemand) {
            errorMsg = '⏳ The AI server is experiencing high demand. Please try again in a moment.';
          } else if (isRateLimit) {
            errorMsg = '⏳ Rate limit reached. Please wait a moment and try again.';
          } else if (isTimeout || isOffline) {
            errorMsg = '⚠️ Unable to reach the AI service. Check your internet connection.';
          } else if (isSafety) {
            errorMsg = '⚠️ The request was blocked by safety filters. Try rephrasing.';
          } else {
            errorMsg = '⚠️ Unexpected error: $errStr';
          }

          messages.add(ChatMessage(
            text: errorMsg,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          break; // Exit loop on failure
        }
      }
    } finally {
      isTyping.value = false;
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(
          scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
