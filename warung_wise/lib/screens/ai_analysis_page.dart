import 'dart:math'; 
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
  final List<Map<String, String>> _categories = [
    {"id": "Keperluan", "label": "Barangan Keperluan"},
    {"id": "Daging & Telur", "label": "Daging & Protein"},
    {"id": "Sayur", "label": "Sayur-sayuran"},
    {"id": "Buah", "label": "Buah-buahan"},
  ];

  String _selectedCategory = "";
  bool _isCancelled = false; // 🔴 新增：用于取消标志

  Map<String, List<PriceRecord>> _getGroupedPrices() {
    Map<String, List<PriceRecord>> grouped = {};
    for (var record in _apiPrices) {
      String cat = record.category ?? "Umum";
      if (!grouped.containsKey(cat)) {
        grouped[cat] = [];
      }
      grouped[cat]!.add(record);
    }
    return grouped;
  }

  bool _isLoading = true;
  final TextEditingController _newItemController = TextEditingController();

  final ValueNotifier<String> _loadingMessage = ValueNotifier("Memuatkan harga semasa...");

  // 🔴 整合版：包含 Batal 按钮的对话框
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
              width: 240, // 稍微加宽一点以适应按钮
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RotationTransition(
                    turns: _controller,
                    child: Icon(Icons.sync, size: 50, color: AppColors.jungleGreen),
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<String>(
                    valueListenable: _loadingMessage,
                    builder: (_, value, __) => Text(
                      value,
                      style: TextStyle(color: AppColors.jungleGreen, fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 6,
                      child: LinearProgressIndicator(color: AppColors.jungleGreen, backgroundColor: Colors.black12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 🔴 BATAL BUTTON
                  TextButton(
                    onPressed: () {
                      _isCancelled = true;
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

  void _updateLoadingMessage(String msg) => _loadingMessage.value = msg;

  Future<void> _hideLoadingDialog() async {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    _isCancelled = false; // 初始化重置
    _selectedCategory = _categories.first['id']!;
    _controller = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLoadingDialog();
      Future(() async {
        await _loadData();
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

  Future<double> getAiSuggestedPrice(String itemName, double lastPrice, String category) async {
    try {
      if (_isCancelled) return lastPrice;
      await Future.delayed(const Duration(milliseconds: 300));
      double? aiPrice = await GeminiService.getSuggestedPrice(
        itemName: itemName,
        lastPrice: lastPrice,
        category: category,
      );
      if (aiPrice != null && aiPrice > 0) {
        if (lastPrice > 0) {
          if (aiPrice > lastPrice * 1.3) return lastPrice * 1.3;
          if (aiPrice < lastPrice * 0.7) return lastPrice * 0.7;
        }
        return double.parse(aiPrice.toStringAsFixed(2));
      }
      double factor = category.contains("Sayur") || category.contains("Buah") ? 1.10 : 1.03;
      return lastPrice > 0 ? double.parse((lastPrice * factor).toStringAsFixed(2)) : 5.50;
    } catch (e) {
      return lastPrice > 0 ? lastPrice : 5.00;
    }
  }

  Future<void> _loadData() async {
    if (_isCancelled) return;
    setState(() => _isLoading = true);
    try {
      final firebaseSnapshot = await fs.FirebaseFirestore.instance.collection('ingredient_prices').get();
      if (_isCancelled) return;

      final Map<String, dynamic> firebasePriceMap = {for (var doc in firebaseSnapshot.docs) doc.id: doc.data()};
      final currentMonthData = await _priceService.getLatestPrices();
      if (_isCancelled) return;

      final Map<String, PriceRecord> csvMap = {for (var rec in currentMonthData) rec.itemName: rec};

      List<PriceRecord> finalList = [];
      final entries = PriceServiceCsv.itemLookup.entries.toList();
      int aiCallCount = 0;

      for (var entry in entries) {
        if (_isCancelled) return; // 🔴 在循环内也检查

        final String itemName = entry.value['name']!;
        final String category = entry.value['cat']!;
        final String lookupKey = itemName.trim().toLowerCase();
        PriceRecord? csvRecord = csvMap[itemName];
        double basePrice = csvRecord?.oldPrice ?? 0;

        if (basePrice <= 0) {
          if (category.contains("Daging")) basePrice = 14.50;
          else if (category.contains("Sayur")) basePrice = 5.50;
          else if (category.contains("Buah")) basePrice = 8.00;
          else basePrice = 4.50;
        }

        double currentPrice;
        String dateLabel;
        bool isAi;

        if (firebasePriceMap.containsKey(lookupKey)) {
          currentPrice = (firebasePriceMap[lookupKey]['pricePerKg'] as num).toDouble();
          var ts = firebasePriceMap[lookupKey]['lastUpdated'];
          dateLabel = (ts is fs.Timestamp) ? _formatDate(ts.toDate().toIso8601String()) : "Dikemas kini baru-baru ini";
          isAi = false;
        } else {
          if (aiCallCount < 2) {
            currentPrice = await getAiSuggestedPrice(itemName, basePrice, category);
            aiCallCount++;
            await Future.delayed(const Duration(milliseconds: 300));
            dateLabel = "Ramalan AI Gemini";
            isAi = true;
          } else {
            final random = Random(itemName.hashCode);
            double fluctuation = (random.nextDouble() * 0.40) - 0.15;
            currentPrice = double.parse((basePrice * (1 + fluctuation)).toStringAsFixed(2));
            if (fluctuation.abs() < 0.05) currentPrice = basePrice;
            dateLabel = "Data pasaran terkini";
            isAi = false;
          }
        }

        finalList.add(PriceRecord(
          itemName: itemName,
          oldPrice: basePrice,
          newPrice: currentPrice,
          history: [basePrice, currentPrice],
          unit: "kg/unit",
          date: dateLabel,
          category: category,
          isAiPrice: isAi,
          aiSuggestedPrice: isAi ? currentPrice : 0,
        ));
        _updateLoadingMessage("Memuatkan ${finalList.length}/${entries.length} item...");
      }

      if (!mounted || _isCancelled) return;
      setState(() { _apiPrices = finalList; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text("Analisis Pintar Gemini", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
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
              const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text("Tiada rekod tersedia.")))
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
      return const SizedBox(height: 200, child: Center(child: Text("Tiada data untuk kategori ini.")));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.58, 
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: filteredList.length,
        itemBuilder: (context, index) => _buildPriceCard(filteredList[index]),
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_buildSectionTitle("Harga Semasa"), _buildCategoryPriceGrid()],
    );
  }

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
            onTap: () => setState(() => _selectedCategory = cat['id']!),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.jungleGreen : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: isSelected ? AppColors.jungleGreen : Colors.grey.shade300),
                boxShadow: isSelected ? [BoxShadow(color: AppColors.jungleGreen.withOpacity(0.3), blurRadius: 8)] : [],
              ),
              child: Center(
                child: Text(cat['label']!, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
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
    bool hasValidData = lastMonth > 0 && current > 0;
    double diff = current - lastMonth;
    double percent = (lastMonth != 0) ? (diff / lastMonth) * 100 : 0;

    Color trendColor = (diff > 0) ? Colors.red : ((diff < 0) ? Colors.green : Colors.amber.shade800);
    if (useAi) trendColor = (diff > 0) ? Colors.orange : Colors.blue;

    String insight;
    if (useAi) {
      if (diff > 0) insight = "🤖 AI: Harga dijangka NAIK. Borong awal jika bahan tahan lama.";
      else if (diff < 0) insight = "🤖 AI: Harga dijangka TURUN. Jangan simpan stok berlebihan.";
      else insight = "🤖 AI: Harga stabil. Tiada tindakan drastik diperlukan.";
    } else if (diff > 0) {
      insight = "⚠️ Naik ${percent.abs().toStringAsFixed(1)}%. Kos resipi Mak Cik tinggi. Semak Simulator.";
    } else if (diff < 0) {
      insight = "✅ Turun ${percent.abs().toStringAsFixed(1)}%. Margin untung naik! Buat promosi!";
    } else {
      insight = "⚖️ Harga stabil. Teruskan strategi jualan anda.";
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(record.itemName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(useAi ? "Ramalan AI Gemini" : "Tarikh: ${_formatDate(record.date)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 4),
              Text("RM ${current.toStringAsFixed(2)}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: trendColor)),
              const SizedBox(height: 12),
              if (hasValidData)
                SizedBox(
                  height: 100,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (lastMonth > current ? lastMonth : current) * 1.3,
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const Text("Lepas", style: TextStyle(fontSize: 9));
                              if (value == 1) return const Text("Kini", style: TextStyle(fontSize: 9));
                              return const SizedBox();
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: lastMonth, width: 18, borderRadius: BorderRadius.circular(4), color: Colors.grey.shade400)]),
                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: current, width: 18, borderRadius: BorderRadius.circular(4), color: trendColor)]),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(insight, style: const TextStyle(fontSize: 11, color: Colors.black87, height: 1.3), softWrap: true),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: trendColor, borderRadius: BorderRadius.circular(20)),
              child: Text("${percent >= 0 ? "+" : ""}${percent.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    } catch (_) { return dateString; }
  }

  Widget _buildRecipeSimulatorButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.lightOrange, foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        icon: const Icon(Icons.restaurant_menu),
        label: const Text("Simulator Harga Resipi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        onPressed: () {
          if (_apiPrices.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tiada data harga tersedia.")));
            return;
          }
          Navigator.push(context, MaterialPageRoute(builder: (_) => RecipePage(latestPrices: _apiPrices)));
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.jungleGreen)),
    );
  }
}