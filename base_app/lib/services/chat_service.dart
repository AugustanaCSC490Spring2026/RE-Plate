import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatService {
  final String _apiKey = dotenv.env['GEMINI_KEY']!;

  ChatSession? _chat;

  Future<void> init() async {
    final model = GenerativeModel(
      model: 'gemini-2.0-flash-lite',
      apiKey: _apiKey,
    );
    _chat = model.startChat();
  }

  Future<String> sendMessage(String message) async {
    if (_chat == null) await init();
    final response = await _chat!.sendMessage(Content.text(message));
    return response.text ?? 'Sorry, I could not get a response.';
  }
}