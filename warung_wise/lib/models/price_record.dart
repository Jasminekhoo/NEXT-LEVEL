class PriceRecord {
  final String itemName;
  final double oldPrice;
  final double newPrice;
  final List<double> history; // last 5 price points
  final String unit;
  final String date; // yyyy-MM-dd
  final String category;
  double? aiSuggestedPrice; 
  bool isAiPrice = false; 

  PriceRecord({
    required this.itemName,
    required this.oldPrice,
    required this.newPrice,
    required this.history,
    required this.unit,
    required this.date,
    required this.category,
    this.aiSuggestedPrice,
    this.isAiPrice = false,
  });

  factory PriceRecord.fromJson(Map<String, dynamic> json) {
    return PriceRecord(
      itemName: (json['item'] ?? 'Barangan').toString().trim(),
      oldPrice: double.tryParse(json['old']?.toString() ?? '0') ?? 0,
      newPrice: double.tryParse(json['new']?.toString() ?? '0') ?? 0,
      history: (json['history'] as List<dynamic>? ?? [])
          .map((e) => double.tryParse(e.toString()) ?? 0)
          .toList(),
      unit: (json['unit'] ?? '-').toString(),
      date: (json['date'] ?? '').toString(),
      category: (json['category'] ?? 'Lain-lain').toString(),
    );
  }

  // check if have past 3 months data
  bool get hasRecentData {
    if (date.isEmpty) return false;
    try {
      final lastDate = DateTime.parse(date);
      final cutoff = DateTime.now().subtract(const Duration(days: 90));
      return lastDate.isAfter(cutoff);
    } catch (_) {
      return false;
    }
  }
 
  double get displayPrice {
    return hasRecentData ? newPrice : (aiSuggestedPrice ?? newPrice);
  }

  String get priceSource {
    return hasRecentData ? "Pasaran" : "AI Gemini";
  }
}