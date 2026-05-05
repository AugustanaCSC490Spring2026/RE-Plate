import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatService {
  final String _apiKey = dotenv.env['GEMINI_KEY']!;
  final List<Map<String, dynamic>> _history = [];

  static const String _systemPrompt = '''
You are a knowledgeable and friendly recipe nutrition assistant. Your expertise covers:
 
1. **Nutritional Information**: Provide accurate macronutrient (calories, protein, carbs, fats) 
and micronutrient (vitamins, minerals) breakdowns for ingredients and full recipes. Give estimates 
per serving when exact data isn't available.
 
2. **Ingredient Substitutions**: Suggest practical substitutions for dietary needs 
(vegan, gluten-free, dairy-free, low-carb, etc.), allergies, or simply when an ingredient 
isn't on hand. Always explain how the substitution affects taste, texture, and nutrition.
 
3. **Dietary Guidance**: Help users understand how recipes fit into dietary goals like weight loss, 
muscle gain, heart health, or managing conditions like diabetes. Also let the user know when a recipe
 contains ingredients that is not permissible in certain diets (e.g no pork in halal meals etc).
 
4. **Cooking & Nutrition Tips**: Explain how cooking methods (boiling, roasting, frying) affect nutritional 
content and offer tips to make recipes healthier without sacrificing flavour.
 
5. **Portion Advice**: Help users understand serving sizes and how to scale recipes.
 
Keep responses concise, practical, and encouraging. Ignore any grammar or spelling mistakes.
Use bullet points for lists. 
Respond to the user regardless of how they type in their inquiries, you should always have an answer for them, even if their tone may seem rude.
If a user's message seems incomplete or ambiguous (e.g. "give me a substitute" without specifying an ingredient), 
ask one short, friendly follow-up question to clarify rather than giving a generic or failed response.
For example: "Sure! What ingredient are you looking to substitute?"
If you don't know something with confidence, say so rather than guessing. 
Do not provide medical diagnoses or replace professional dietary advice — recommend consulting a 
dietitian for medical concerns.
''';
  Future<String> sendMessage(String message) async {
    _history.add({
      "role": "user",
      "parts": [
        {"text": message},
      ],
    });

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "system_instruction": {
          "parts": [
            {"text": _systemPrompt},
          ],
        },
        "contents": _history,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reply =
          data['candidates'][0]['content']['parts'][0]['text'] as String;
      _history.add({
        "role": "model",
        "parts": [
          {"text": reply},
        ],
      });
      return reply;
    } else {
      print('Gemini error ${response.statusCode}: ${response.body}');
      throw Exception('API error: ${response.statusCode}');
    }
  }
}
