import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../api_config.dart';

class GeminiService {
  static const String _apiKey = ApiConfig.geminiApiKey;

  static Future<double?> getSuggestedPrice({
    required String itemName,
    required double lastPrice,
    required String category,
  }) async {
    const String modelName = "gemini-2.5-flash";
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$_apiKey",
    );

    // 稍微调整 Prompt，明确叫它不要在思考后废话
    final promptText = """
User: You are a market analyst. 
Item: $itemName, Category: $category, Last Price: RM $lastPrice.
Rules: Realistic Malaysian inflation adjustment. 
Output ONLY the price as a number. No text.

Assistant: 
""";

    final Map<String, dynamic> body = {
      "contents": [
        {
          "role": "user",
          "parts": [{"text": promptText}]
        }
      ],
      "generationConfig": {
        "temperature": 0.1,
        "maxOutputTokens": 200, // 👈 重要：增加到 200，防止被 thoughts 占满
        "topP": 0.95,
      }
    };

    try {
      print("📡 发送请求至 Gemini 2.5 Flash...");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        print("❌ 错误: ${response.body}");
        return null;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      
      // 检查是否有内容
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;

      final content = candidates[0]['content'];
      if (content == null || content['parts'] == null) {
        // 如果没有 parts，可能是被 thoughts 阻塞了
        print("⚠️ 响应中没有 parts。原因: ${candidates[0]['finishReason']}");
        return null;
      }

      final String? aiText = content['parts'][0]['text'];
      if (aiText != null) {
        print("🤖 AI 返回: ${aiText.trim()}");
        // 提取数字
        final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(aiText);
        if (match != null) {
          return double.tryParse(match.group(0)!);
        }
      }
      return null;
    } catch (e) {
      print("❌ 异常: $e");
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> analyzeReceiptPhoto({
    required File imageFile,
    String modelName = "gemini-2.5-flash",
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
