import 'dart:convert';               // jsonEncode / jsonDecode
import 'package:http/http.dart' as http;  // http.post
import '../api_keys.dart';

class GeminiService {

static const String _apiKey = ApiKeys.geminiKey;

  static Future<double?> getSuggestedPrice({
    required String itemName,
    required double lastPrice,
    required String category,
  }) async {
    
 final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey",
    );

    final prompt = """
You are a senior market price analyst in Malaysia (February 2026).

Item: $itemName
Category: $category
Previous Market Price: RM ${lastPrice.toStringAsFixed(2)}

Rules:
- Adjust price realistically based on Malaysian inflation (2-5%)
- Small fluctuation allowed (max ±8%)
- Vegetables and fresh items may fluctuate slightly higher
- DO NOT exceed ±10% change
- Output ONLY a number
- No explanation
- No currency symbol

Return updated market price:
""";

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 30));

      print("📡 状态码: ${response.statusCode}");
      print("📡 返回: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? text =
            data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

        if (text != null) {
          final cleaned = text.trim().replaceAll(RegExp(r'[^0-9.]'), '');
          print("✅ [Gemini API] get the price: $cleaned");
          return double.tryParse(cleaned);
        }
      } else {
        print("❌ API、 failed with status code: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error: $e");
    }

    return null;
  }
}