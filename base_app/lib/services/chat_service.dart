import 'package:google_generative_ai/google_generative_ai.dart';

class ChatService {
  static const _apiKey = 'AIzaSyD9XK81acUtDYftxxWdi9rQ-KMPkqwpu20';

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