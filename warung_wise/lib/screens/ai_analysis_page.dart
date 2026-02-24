import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_colors.dart';
import '../models/price_record.dart';
import '../models/recipe.dart';
import '../models/extracted_item.dart';
import '../services/price_service_csv.dart';
import '../services/gemini_service.dart';
import 'recipe_page.dart';

import 'package:cloud_firestore/cloud_firestore.dart' as fs;

class AiAnalysisPage extends StatefulWidget {
  const AiAnalysisPage({super.key});

  @override
  State<AiAnalysisPage> createState() => _AiAnalysisPageState();
}

class _AiAnalysisPageState extends State<AiAnalysisPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final PriceServiceCsv _priceService = PriceServiceCsv();
  List<PriceRecord> _apiPrices = [];
  bool _isScanning = true;
  final List<Map<String, String>> _categories = [
    {
      "id": "Keperluan",
      "label": "Barangan Keperluan",
    }, // ID 对应 itemLookup 里的 "Keperluan"
    {"id": "Daging & Telur", "label": "Daging & Protein"}, // 保持一致
    {"id": "Sayur", "label": "Sayur-sayuran"}, // ID 对应 "Sayur"
    {"id": "Buah", "label": "Buah-buahan"}, // ID 对应 "Buah"
  ];

  // Default selected category
  String _selectedCategory = "";

  Map<String, List<PriceRecord>> _getGroupedPrices() {
    Map<String, List<PriceRecord>> grouped = {};
    for (var record in _apiPrices) {
      // 如果 record 没有 category 字段，可以给个默认值 "Lain-lain"
      String cat = record.category ?? "Umum";
      if (!grouped.containsKey(cat)) {
        grouped[cat] = [];
      }
      grouped[cat]!.add(record);
    }
    return grouped;
  }

  // List<ExtractedItem> _extractedItems = [];
  bool _isExtracting = true;
  bool _isLoading = true;
  bool _isCancelled = false;
  // bool _isConfirmed = false;
  final TextEditingController _newItemController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // ===================== Loading Dialog =====================
  final ValueNotifier<String> _loadingMessage = ValueNotifier(
    "Memuatkan harga semasa...",
  );

  // Future<void> _showLoadingDialog() async {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false, // 用户无法点击外部关闭
  //     builder: (_) => WillPopScope(
  //       onWillPop: () async => false, // 禁止返回键关闭
  //       child: Material(
  //         color: Colors.black26, // 半透明背景，突出卡片
  //         child: Center(
  //           child: Container(
  //             padding: const EdgeInsets.all(24),
  //             width: 220,
  //             decoration: BoxDecoration(
  //               color: AppColors.offWhite, // 卡片浅色背景
  //               borderRadius: BorderRadius.circular(20),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black26,
  //                   blurRadius: 8,
  //                   offset: Offset(0, 4),
  //                 ),
  //               ],
  //             ),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 RotationTransition(
  //                   turns: _controller,
  //                   child: Icon(
  //                     Icons.sync,
  //                     size: 50,
  //                     color: AppColors.jungleGreen,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 ValueListenableBuilder<String>(
  //                   valueListenable: _loadingMessage,
  //                   builder: (_, value, __) => Text(
  //                     value,
  //                     style: TextStyle(
  //                       color: AppColors.jungleGreen,
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                     textAlign: TextAlign.center,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 ClipRRect(
  //                   borderRadius: BorderRadius.circular(6),
  //                   child: SizedBox(
  //                     height: 6,
  //                     child: LinearProgressIndicator(
  //                       color: AppColors.jungleGreen,
  //                       backgroundColor: Colors.black12,
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

Future<void> _showLoadingDialog() async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => WillPopScope(
      onWillPop: () async => false,
      child: Material(
        color: Colors.black26,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 240,
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RotationTransition(
                  turns: _controller,
                  child: Icon(
                    Icons.sync,
                    size: 50,
                    color: AppColors.jungleGreen,
                  ),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<String>(
                  valueListenable: _loadingMessage,
                  builder: (_, value, __) => Text(
                    value,
                    style: TextStyle(
                      color: AppColors.jungleGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                // 🔴 BATAL BUTTON
                TextButton(
                  onPressed: () {
                    _isCancelled = true;
                    // 关闭 loading dialog
                    Navigator.of(context, rootNavigator: true).pop();

                  },
                  child: const Text(
                    "Batal",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  // 更新 loading 文字
  void _updateLoadingMessage(String msg) {
    _loadingMessage.value = msg;
  }

  // 隐藏 dialog
  Future<void> _hideLoadingDialog() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // ===================== initState =====================
  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first['id']!;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _isCancelled = false;

    // ⚡ 核心优化：UI 渲染首帧后再加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLoadingDialog(); // 先显示 dialog + 动画

      if (_isCancelled){
        if (mounted) Navigator.of(context).pop();
        return;
      }

      Future(() async {
        await _loadData(); // 异步加载数据，不阻塞 UI
        await _hideLoadingDialog();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _newItemController.dispose();
    super.dispose();
  }

  // // ===================== 收据提取 =====================
  // Future<void> _startAutoExtraction() async {
  //   setState(() => _isExtracting = true);

  //   await Future.delayed(const Duration(seconds: 2));

  //   final today = DateTime.now();
  //   final mockData = [
  //     ExtractedItem(name: "Beras 5kg", price: "RM 18.50", date: today),
  //     ExtractedItem(name: "Ayam 1kg", price: "RM 9.90", date: today),
  //     ExtractedItem(name: "Telur Gred A", price: "RM 12.00", date: today),
  //     ExtractedItem(name: "Minyak Masak", price: "RM 6.80", date: today),
  //   ];

  //   final newItems = mockData
  //       .where((item) =>
  //           !_extractedItems.any((e) =>
  //               e.name == item.name &&
  //               e.date.year == item.date.year &&
  //               e.date.month == item.date.month &&
  //               e.date.day == item.date.day))
  //       .toList();

  //   if (!mounted) return;

  //   setState(() {
  //     _extractedItems.addAll(newItems);
  //     _isExtracting = false;
  //   });

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text("Resit berjaya diproses ✅")),
  //   );
  // }

  // ===================== 1️⃣ AI 价格计算 =====================
  Future<double> getAiSuggestedPrice(
    String itemName,
    double lastPrice,
    String category,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300)); // 防止 429

      // 调用最新 GeminiService 模型
      double? aiPrice = await GeminiService.getSuggestedPrice(
        itemName: itemName,
        lastPrice: lastPrice,
        category: category,
        modelName: "models/gemini-flash-latest", // ✅ 最新模型
      );

      print("💡 GeminiService 返回 $aiPrice for $itemName");

      if (aiPrice != null && aiPrice > 0) {
        // 护栏：波动不超 30%
        if (lastPrice > 0) {
          if (aiPrice > lastPrice * 1.3) return lastPrice * 1.3;
          if (aiPrice < lastPrice * 0.7) return lastPrice * 0.7;
        }
        return double.parse(aiPrice.toStringAsFixed(2));
      }

      // AI 失败保底逻辑
      double factor = category.contains("Sayur") || category.contains("Buah")
          ? 1.10
          : 1.03;
      return lastPrice > 0
          ? double.parse((lastPrice * factor).toStringAsFixed(2))
          : 5.50;
    } catch (e) {
      print("🚑 getAiSuggestedPrice 崩溃: $e");
      return lastPrice > 0 ? lastPrice : 5.00;
    }
  }

  // ===================== 2️⃣ Generate AI prices =====================
  Future<void> _generateAiPrices() async {
    for (var record in _apiPrices) {
      if (!record.hasRecentData) {
        final suggestion = await getAiSuggestedPrice(
          record.itemName,
          record.newPrice,
          record.category,
        );

        record.aiSuggestedPrice = suggestion;
        record.isAiPrice = true;

        print("💡 AI 最终价格 for ${record.itemName}: ${record.aiSuggestedPrice}");
        await Future.delayed(const Duration(milliseconds: 50)); // 给 UI 渲染时间
      }
    }
    setState(() {});
  }

  /*
// ===================== 3️⃣ Load data =====================
Future<void> _loadData() async {
  setState(() => _isLoading = true);

  try {
    final currentMonthData = await _priceService.getLatestPrices();

    final Map<String, PriceRecord> currentMap = {
      for (var rec in currentMonthData) rec.itemName: rec
    };

    List<PriceRecord> finalList = [];
    const int batchSize = 5;
    final entries = PriceServiceCsv.itemLookup.entries.toList();

    for (int i = 0; i < entries.length; i += batchSize) {
      final batch = entries.sublist(i, (i + batchSize).clamp(0, entries.length));

      final batchProcessed = await Future.wait(batch.map((entry) async {
        final itemName = entry.value['name']!;
        final category = entry.value['cat']!;

        try {
          PriceRecord? record = currentMap[itemName];

          double basePrice = record?.oldPrice ?? 0;
          if (basePrice <= 0) {
            basePrice = (category == "Sayur" || category == "Buah") ? 6.5 : 8.0;
          }

          bool useAi = record == null || record.newPrice <= 0;
          double newPrice = useAi ? 0 : record.newPrice;
          String date = record?.date ?? "";

          if (useAi) {
            double aiPrice = await getAiSuggestedPrice(itemName, basePrice, category);
            newPrice = aiPrice;
            date = "Ramalan AI Gemini";
            print("💡 AI price for $itemName: $newPrice");
          }

          return PriceRecord(
            itemName: itemName,
            oldPrice: record?.oldPrice ?? basePrice,
            newPrice: newPrice,
            history: [record?.oldPrice ?? basePrice, newPrice],
            unit: "unit",
            date: date,
            category: category,
            isAiPrice: useAi,
            aiSuggestedPrice: useAi ? newPrice : 0,
          );
        } catch (e) {
          print("⚠️ AI processing failed for $itemName: $e");
          return null;
        }
      }));

      finalList.addAll(batchProcessed.whereType<PriceRecord>());

      _updateLoadingMessage("Memuatkan ${finalList.length}/${entries.length} item...");
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (!mounted) return;

    setState(() {
      _apiPrices = finalList;
      _isLoading = false;
    });

    _updateLoadingMessage("Selesai!");
  } catch (e) {
    print("‼️ _loadData failed: $e");
    if (mounted) setState(() => _isLoading = false);
  }
}
*/

  Future<void> _loadData() async {
  if (_isCancelled) return;

  setState(() => _isLoading = true);

  try {
    // ---------------------------------------------------------
    // A. Firebase 获取现实数据
    // ---------------------------------------------------------
    final firebaseSnapshot = await fs.FirebaseFirestore.instance
        .collection('ingredient_prices')
        .get();

    if (_isCancelled) return;

    final Map<String, dynamic> firebasePriceMap = {
      for (var doc in firebaseSnapshot.docs) doc.id: doc.data(),
    };

    // ---------------------------------------------------------
    // B. 获取 CSV 历史数据
    // ---------------------------------------------------------
    final currentMonthData = await _priceService.getLatestPrices();

    if (_isCancelled) return;

    final Map<String, PriceRecord> csvMap = {
      for (var rec in currentMonthData) rec.itemName: rec,
    };

    List<PriceRecord> finalList = [];
    final entries = PriceServiceCsv.itemLookup.entries.toList();

    // ---------------------------------------------------------
    // C. 合并逻辑
    // ---------------------------------------------------------
    for (var entry in entries) {
      if (_isCancelled) return;

      final String itemName = entry.value['name']!;
      final String category = entry.value['cat']!;
      final String lookupKey = itemName.trim().toLowerCase();

      PriceRecord? csvRecord = csvMap[itemName];

      double basePrice = csvRecord?.oldPrice ?? 0;
      if (basePrice <= 0) {
        basePrice = (category == "Sayur" || category == "Buah") ? 6.5 : 8.0;
      }

      double currentPrice;
      String dateLabel;
      bool isAi;

      if (firebasePriceMap.containsKey(lookupKey)) {
        currentPrice =
            (firebasePriceMap[lookupKey]['pricePerKg'] as num).toDouble();

        var ts = firebasePriceMap[lookupKey]['lastUpdated'];
        if (ts is fs.Timestamp) {
          dateLabel = _formatDate(ts.toDate().toIso8601String());
        } else {
          dateLabel = "Dikemas kini baru-baru ini";
        }

        isAi = false;
      } else {
        currentPrice = await getAiSuggestedPrice(
          itemName,
          basePrice,
          category,
        );

        if (_isCancelled) return;

        dateLabel = "Ramalan AI Gemini";
        isAi = true;
      }

      finalList.add(
        PriceRecord(
          itemName: itemName,
          oldPrice: basePrice,
          newPrice: currentPrice,
          history: [basePrice, currentPrice],
          unit: "kg/unit",
          date: dateLabel,
          category: category,
          isAiPrice: isAi,
          aiSuggestedPrice: isAi ? currentPrice : 0,
        ),
      );

      _updateLoadingMessage(
        "Memuatkan ${finalList.length}/${entries.length} item...",
      );
    }

    if (!mounted || _isCancelled) return;

    setState(() {
      _apiPrices = finalList;
      _isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() => _isLoading = false);
    print("‼️ _loadData failed: $e");
  }
}

  // ===================== Scaffold =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text(
          "Analisis Pintar Gemini",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.jungleGreen,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRecipeSimulatorButton(),
            _buildCategoryFilter(),
            if (_apiPrices.isEmpty && !_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    "Tiada rekod tersedia.",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              )
            else
              _buildResultsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPriceGrid() {
    final grouped = _getGroupedPrices();
    final filteredList = grouped[_selectedCategory] ?? [];

    if (filteredList.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("Tiada data untuk kategori ini.")),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          return _buildPriceCard(filteredList[index]);
        },
      ),
    );
  }

  // ------------------ RESULTS LIST ------------------
  Widget _buildResultsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_buildSectionTitle("Harga Semasa"), _buildCategoryPriceGrid()],
    );
  }

  // ------------------ CATEGORY FILTER ------------------

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          bool isSelected = _selectedCategory == cat['id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = cat['id']!;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.jungleGreen : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? AppColors.jungleGreen
                      : Colors.grey.shade300,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.jungleGreen.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  cat['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceCard(PriceRecord record) {
    bool useAi = record.isAiPrice || record.newPrice == 0;

    double lastMonth = record.oldPrice;
    double current = useAi ? (record.aiSuggestedPrice ?? 0) : record.newPrice;

    bool hasValidData = lastMonth > 0 && current > 0 && !useAi;

    double diff = current - lastMonth;
    double percent = hasValidData && lastMonth != 0
        ? (diff / lastMonth) * 100
        : 0;

    // =========================
    // 🎨 颜色逻辑
    // =========================
    Color trendColor;
    if (useAi) {
      trendColor = Colors.grey;
    } else if (!hasValidData) {
      trendColor = Colors.grey;
    } else if (diff > 0) {
      trendColor = Colors.red;
    } else if (diff < 0) {
      trendColor = Colors.green;
    } else {
      trendColor = Colors.amber.shade800;
    }

    String insight;
    if (useAi) {
      insight = "Harga dianggarkan menggunakan cadangan AI.";
    } else if (!hasValidData) {
      insight = "Tiada data mencukupi untuk perbandingan.";
    } else if (diff > 0) {
      insight =
          "Harga meningkat ${percent.abs().toStringAsFixed(1)}% berbanding bulan lepas.";
    } else if (diff < 0) {
      insight =
          "Harga menurun ${percent.abs().toStringAsFixed(1)}% berbanding bulan lepas.";
    } else {
      insight = "Harga kekal stabil berbanding bulan lepas.";
    }

    double maxY = (lastMonth > current ? lastMonth : current) * 1.3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 商品名
              Text(
                record.itemName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),

              // 时间显示
              Text(
                useAi
                    ? "Ramalan AI Gemini"
                    : "Tarikh: ${_formatDate(record.date)}",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),

              const SizedBox(height: 6),

              // 当前价格
              Text(
                "RM ${current.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: trendColor,
                ),
              ),

              const SizedBox(height: 12),

              // =========================
              // 📊 BAR CHART
              // =========================
              if (hasValidData)
                SizedBox(
                  height: 120,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              switch (value.toInt()) {
                                case 0:
                                  return const Text(
                                    "Bulan Lepas",
                                    style: TextStyle(fontSize: 10),
                                  );
                                case 1:
                                  return const Text(
                                    "Bulan Ini",
                                    style: TextStyle(fontSize: 10),
                                  );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: lastMonth,
                              width: 20,
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: current,
                              width: 20,
                              borderRadius: BorderRadius.circular(6),
                              color: trendColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // =========================
              // 💡 Insight（普通灰色）
              // =========================
              Flexible(
                child: Text(
                  insight,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  softWrap: true,
                ),
              ),
            ],
          ),

          // =========================
          // 📈 右上角百分比角标
          // =========================
          if (hasValidData)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trendColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${percent >= 0 ? "+" : ""}${percent.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.year}-"
          "${date.month.toString().padLeft(2, '0')}-"
          "${date.day.toString().padLeft(2, '0')}";
    } catch (_) {
      return dateString;
    }
  }

  // 辅助函数：月份转马来文缩写
  String _getMonthNameShort(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mac",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Ogos",
      "Sept",
      "Okt",
      "Nov",
      "Dis",
    ];
    return months[month - 1];
  }

  // ------------------ PROFIT SIMULATOR ------------------

  Widget _buildRecipeSimulatorButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightOrange,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        icon: const Icon(Icons.restaurant_menu),
        label: const Text(
          "Simulator Harga Resipi",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          if (_apiPrices.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Tiada data harga tersedia.")),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecipePage(latestPrices: _apiPrices),
            ),
          );
        },
      ),
    );
  }

  // ------------------ SECTION TITLE ------------------

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.jungleGreen,
        ),
      ),
    );
  }
}
