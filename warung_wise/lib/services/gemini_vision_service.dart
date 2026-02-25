import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/extracted_item.dart';
// Note: If api_config.dart still shows red, ensure the file exists in lib/api_config.dart
import '../api_config.dart';

class GeminiVisionService {
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: ApiConfig
        .geminiApiKey, // Ensure this matches your class in api_config.dart
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      temperature: 0.1, // Lower temperature is better for data extraction
    ),
  );

  Future<List<ExtractedItem>> analyzeReceipt(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();

      final prompt = TextPart("""
        Extract items and prices from this receipt image. 
        Return ONLY a JSON array of objects.
        Required fields: "name", "price" (string).
        Example: [{"name": "Ayam", "price": "12.50"}]
      """);

      final imagePart = DataPart('image/jpeg', imageBytes);
      final response = await _model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      final String raw = response.text ?? "[]";
      final List<dynamic> decoded = jsonDecode(raw);

      // ✅ Fix: Format the date as a String (YYYY-MM-DD)
      final String todayDate = DateTime.now().toString().split(' ')[0];

      return decoded
          .map(
            (item) => ExtractedItem(
              name: item['name'] ?? "Unknown",
              price: item['price']?.toString() ?? "0.00",
              date: DateTime.now(), // 🔥 FIXED: Passing required String date
              //category: "Lain-lain", // Default category
            ),
          )
          .toList();
    } catch (e) {
      debugPrint("AI Vision Error: $e");
      return [];
    }
  }
}
