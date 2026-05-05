// ignore_for_file: avoid_print

import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY');
  if (apiKey.isEmpty) {
    print('Missing GEMINI_API_KEY. Run with --dart-define=GEMINI_API_KEY=...');
    return;
  }
  final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: apiKey,
    systemInstruction: Content.system('You are a test bot.'),
  );
  
  final chat = model.startChat();
  try {
    final response = await chat.sendMessage(Content.text('Hello'));
    print('SUCCESS: ${response.text}');
  } catch (e) {
    print('ERROR: $e');
  }
}
