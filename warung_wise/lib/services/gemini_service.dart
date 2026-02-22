import 'dart:convert';               // jsonEncode / jsonDecode
import 'package:http/http.dart' as http;  // http.post

class GeminiService {
  static const String _apiKey = "AIzaSyBi3JJAAN7GBKtm3hQKbwpsO0rtUxZsBn8";

  /// 增加 modelName 参数，可选，默认使用 gemini-flash-latest
  static Future<double?> getSuggestedPrice({
    required String itemName,
    required double lastPrice,
    required String category,
    String modelName = "models/gemini-flash-latest", // ✅ 默认模型
  }) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$_apiKey",
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
      ).timeout(const Duration(seconds: 10));

      print("📡 状态码: ${response.statusCode}");
      print("📡 返回: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? text =
            data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

        if (text != null) {
          final cleaned = text.trim().replaceAll(RegExp(r'[^0-9.]'), '');
          return double.tryParse(cleaned);
        }
      }
    } catch (e) {
      print("❌ 异常: $e");
    }

    return null;
  }
}