import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  //static const _apiKey ='AIzaSyDV3AV6p68RftlJGIpNn-PUqcxSfOWFHVk'; // Don't forget to paste your key!

  static Future<String> getWarungAdvice(String prompt) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);

      // We wrap the text in a Content object to satisfy the SDK
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return response.text ?? "AI tak ada respon...";
    } catch (e) {
      return "Error: $e";
    }
  }
}

/*import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  // 💡 HACKATHON TIP: Get your key from aistudio.google.com
  static const String _apiKey = 'AIzaSyDV3AV6p68RftlJGIpNn-PUqcxSfOWFHVk';

  static Future<String> getWarungAdvice(String userPrompt) async {
    try {
      // Use gemini-1.5-flash: it's free, fast, and perfect for business logic
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);

      // System Instructions: Tells Gemini to act like a Malaysian business expert
      final systemPrompt =
          "You are an expert Malaysian business consultant for 'Warung' (small food stall) owners. "
          "Keep advice short, practical, and use local terms like RM, untung, and modal.";

      final content = [
        Content.text("$systemPrompt\n\nUser Question: $userPrompt"),
      ];
      final response = await model.generateContent(content);

      return response.text ?? "Maaf, saya tak dapat berikan jawapan sekarang.";
    } catch (e) {
      return "AI Error: Check your internet or API key.";
    }
  }
}
*/

/*import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  // Replace with your real key from Google AI Studio
  static const _apiKey = 'AIzaSyDV3AV6p68RftlJGIpNn-PUqcxSfOWFHVk';

  static Future<String> getAIResponse(String prompt) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash', // Most efficient for Warung Wise
        apiKey: _apiKey,
      );

      // Wrap your prompt in a Content object
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return response.text ?? "AI couldn't generate a response.";
    } catch (e) {
      return "AI Error: $e";
    }
  }
}
*/
