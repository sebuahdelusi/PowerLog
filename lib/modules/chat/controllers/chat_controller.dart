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
  late final ChatSession _chat;

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
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: AppConfig.geminiApiKey,
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

    messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
    inputCtrl.clear();
    isTyping.value = true;
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(text));
      final reply = response.text ?? 'Sorry, I could not generate a response.';
      messages.add(ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()));
    } catch (e) {
      final isKeyError = e.toString().contains('API_KEY') ||
          e.toString().contains('invalid') ||
          e.toString().contains('403');
      messages.add(ChatMessage(
        text: isKeyError
            ? '⚠️ Invalid API key. Please update AppConfig.geminiApiKey with a valid key from https://aistudio.google.com/apikey'
            : '⚠️ Error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
      ));
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
