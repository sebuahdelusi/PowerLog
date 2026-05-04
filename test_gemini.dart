import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  final apiKey = 'AIzaSyDAdxRWnCaylSI54-1zGarbrI0grg9bIVE';
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
