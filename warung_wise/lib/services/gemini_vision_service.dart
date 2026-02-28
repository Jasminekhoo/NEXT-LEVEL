import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import '../models/extracted_item.dart';
import '../api_config.dart';
import 'package:http/http.dart' as http;

class GeminiVisionService {
  

  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: ApiConfig.geminiApiKey,
    httpClient: null,
    generationConfig: GenerationConfig(
      temperature: 0.1,
      responseMimeType: 'application/json',
    ),
  );

  GeminiVisionService() {
    debugListModels();
  }

  Future<void> debugListModels() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models?key=${ApiConfig.geminiApiKey}',
        ),
      );
      debugPrint("🔑 API Key check: ${response.statusCode}");
      debugPrint("📋 Models response: ${response.body}");
    } catch (e) {
      debugPrint("❌ Key check failed: $e");
    }
  }

  Future<List<ExtractedItem>> analyzeReceipt(dynamic pickedFile) async {
    try {
      final bytes = await _readImageBytes(pickedFile);

      // Pass 1: strong prompt for handwriting + strict JSON
      final pass1 = await _tryOnce(
        imageBytes: bytes,
        prompt: _handwritingPromptV1(),
      );

      if (pass1 != null && pass1.isNotEmpty) return pass1;

      // Small delay (avoid rate limit / give model time)
      await Future.delayed(const Duration(milliseconds: 450));

      // Pass 2 (RETRY): ultra-strict “ONLY JSON array” + fallback rules
      final pass2 = await _tryOnce(
        imageBytes: bytes,
        prompt: _handwritingPromptV2Retry(),
      );

      if (pass2 != null && pass2.isNotEmpty) return pass2;

      return [];
    } catch (e) {
      debugPrint("❌ analyzeReceipt error: $e");
      return [];
    }
  }

  // Internal helpers

  Future<List<ExtractedItem>?> _tryOnce({
    required Uint8List imageBytes,
    required String prompt,
  }) async {
    try {
      final response = await _model.generateContent([
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ]);

      final raw = (response.text ?? "").trim();
      if (raw.isEmpty) return null;

      final jsonText = _extractJsonArray(_stripCodeFences(raw)) ?? "";
      if (jsonText.isEmpty) return null;

      final decoded = jsonDecode(jsonText);
      if (decoded is! List) return null;

      final today = DateTime.now();
      final out = <ExtractedItem>[];

      for (final e in decoded) {
        if (e is! Map) continue;
        final map = Map<String, dynamic>.from(e);

        final name = (map["name"] ?? map["item"] ?? "").toString().trim();
        final priceRaw = (map["price"] ?? "").toString().trim();

        if (name.isEmpty) continue;

        // Normalize price to "RM x.xx" or "RM 0.00"
        final normalizedPrice = _normalizeRm(priceRaw);

        out.add(ExtractedItem(name: name, price: normalizedPrice, date: today));
      }

      // If everything became junk, treat as failure
      if (out.isEmpty) return null;

      return out;
    } catch (e) {
      debugPrint("⚠️ _tryOnce parse failed: $e");
      return null;
    }
  }

  Future<Uint8List> _readImageBytes(dynamic pickedFile) async {
    if (pickedFile is XFile) {
      return await pickedFile.readAsBytes();
    }
    if (pickedFile is File) {
      return await pickedFile.readAsBytes();
    }
    // fallback: try to read from path-like objects
    final path = pickedFile?.path?.toString();
    if (path != null && path.isNotEmpty) {
      return await File(path).readAsBytes();
    }
    throw Exception("Unsupported image input type: ${pickedFile.runtimeType}");
  }

  String _stripCodeFences(String s) {
    return s
        .replaceAll(RegExp(r"^```(?:json)?\s*", multiLine: true), "")
        .replaceAll(RegExp(r"\s*```$", multiLine: true), "")
        .trim();
  }

  String? _extractJsonArray(String s) {
    final start = s.indexOf('[');
    final end = s.lastIndexOf(']');
    if (start == -1 || end == -1 || end <= start) return null;
    return s.substring(start, end + 1).trim();
  }

  String _normalizeRm(String priceRaw) {
    if (priceRaw.isEmpty) return "RM 0.00";

    // keep only digits + dot
    final cleaned = priceRaw.replaceAll(RegExp(r'[^0-9.]'), '');
    final val = double.tryParse(cleaned);
    if (val == null) return "RM 0.00";

    return "RM ${val.toStringAsFixed(2)}";
  }

  // -------------------- Prompts --------------------

  String _handwritingPromptV1() => """
You are a Malaysian receipt OCR assistant specialized in HANDWRITTEN receipts.

Task:
Extract purchased items and prices from the receipt image.

Output:
Return STRICT JSON ONLY (no markdown, no explanation), exactly:
[
  {"name":"...", "price":"RM 0.00"},
  {"name":"...", "price":"RM 0.00"}
]

Handwriting rules:
- Handwritten item names may be messy or abbreviated (e.g., "Ayam Bsh", "Bwg", "Cili pdi"). Keep them as-is.
- If a line has a clear price, include it.
- If price is unclear/missing, set "RM 0.00".
- Ignore totals, change, tax, subtotal, cashier info.
- If there are quantities (e.g., "2x", "3 kg"), keep them inside the name string.

IMPORTANT:
Return ONLY the JSON array. Do NOT wrap in ```json. Do NOT add extra text.
""";

  String _handwritingPromptV2Retry() => """
RETRY MODE (HANDWRITING):
The previous output was invalid. You MUST return ONLY valid JSON array.

Return ONLY this format:
[
  {"name":"...", "price":"RM 0.00"}
]

Rules (strict):
- No markdown fences, no explanation, no trailing commas.
- Use double quotes for all keys/strings.
- Only keys allowed: "name", "price".
- "price" must look like "RM 12.50" OR "RM 0.00".
- Ignore totals/subtotal/tax/rounding/cash change.

If unsure about a line, still include it but set "RM 0.00".

Return ONLY the JSON array.
""";
}
