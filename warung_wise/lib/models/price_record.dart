class PriceRecord {
  final String itemName;
  final double oldPrice;
  final double newPrice;
  final List<double> history; // last 5 price points
  final String unit;
  final String date; // 原始日期 yyyy-MM-dd
  final String category;
  double? aiSuggestedPrice; // AI Gemini 给的价格
  bool isAiPrice = false;   // 是否是 AI 生成

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

  // ------------------ 工厂方法 ------------------
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

  // ------------------ 是否有最近三个月数据 ------------------
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

  // ------------------ 显示价格 ------------------
  double get displayPrice {
    return hasRecentData ? newPrice : (aiSuggestedPrice ?? newPrice);
  }

  // ------------------ 价格来源 ------------------
  String get priceSource {
    return hasRecentData ? "Pasaran" : "AI Gemini";
  }
}