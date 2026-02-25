import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../api_config.dart';

class GeminiService {
  static const String _apiKey = ApiConfig.geminiApiKey;

  // =====================================================
  // 1️⃣ TEXT-ONLY: Get Suggested Market Price
  // =====================================================
  static Future<double?> getSuggestedPrice({
    required String itemName,
    required double lastPrice,
    required String category,
    String modelName = "models/gemini-1.5-flash",
  }) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/$modelName:generateContent?key=$_apiKey",
    );

    final prompt =
        """
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
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": prompt},
                  ],
                },
              ],
              "generationConfig": {"temperature": 0.2},
            }),
          )
          .timeout(const Duration(seconds: 12));

      print("📡 getSuggestedPrice status: ${response.statusCode}");
      print("📡 getSuggestedPrice body: ${response.body}");

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final String? text =
          data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

      if (text == null) return null;

      final cleaned = text.trim().replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleaned);
    } catch (e) {
      print("❌ getSuggestedPrice error: $e");
      return null;
    }
  }

  // =====================================================
  // 2️⃣ IMAGE + TEXT: Analyze Receipt Photo (OCR)
  // =====================================================
  static Future<List<Map<String, dynamic>>?> analyzeReceiptPhoto({
    required File imageFile,
    String modelName = "models/gemini-1.5-flash",
  }) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/$modelName:generateContent?key=$_apiKey",
    );

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = _guessMimeType(imageFile.path);

      final prompt = """
You are a receipt OCR + structuring assistant for Malaysian hawkers.
Extract purchased items and prices from the receipt image.

Return STRICT JSON only (no markdown, no explanation) in this format:
[
  {"item":"...", "price": 0.00}
]

Rules:
- If price missing/unclear, set price to null
- Remove currency symbols
- Keep item names as written
""";

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": prompt},
                    {
                      "inlineData": {"mimeType": mimeType, "data": base64Image},
                    },
                  ],
                },
              ],
              "generationConfig": {"temperature": 0.2},
            }),
          )
          .timeout(const Duration(seconds: 25));

      print("📡 analyzeReceiptPhoto status: ${response.statusCode}");
      print("📡 analyzeReceiptPhoto body: ${response.body}");

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final String? rawText =
          data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

      if (rawText == null) return null;

      final jsonText = _stripCodeFences(rawText).trim();
      final decoded = jsonDecode(jsonText);

      if (decoded is! List) return null;

      final items = <Map<String, dynamic>>[];

      for (final e in decoded) {
        if (e is Map) {
          final map = Map<String, dynamic>.from(e);
          final item = map["item"]?.toString().trim();
          final price = map["price"];

          if (item == null || item.isEmpty) continue;

          items.add({
            "item": item,
            "price": (price == null)
                ? null
                : (price is num)
                ? price.toDouble()
                : double.tryParse(
                    price.toString().replaceAll(RegExp(r'[^0-9.]'), ''),
                  ),
          });
        }
      }

      return items;
    } catch (e) {
      print("❌ analyzeReceiptPhoto error: $e");
      return null;
    }
  }

  // =====================================================
  // Helpers
  // =====================================================
  static String _stripCodeFences(String s) {
    return s
        .replaceAll(RegExp(r"^```(?:json)?\s*", multiLine: true), "")
        .replaceAll(RegExp(r"\s*```$", multiLine: true), "");
  }

  static String _guessMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith(".png")) return "image/png";
    if (lower.endsWith(".webp")) return "image/webp";
    return "image/jpeg";
  }
}
