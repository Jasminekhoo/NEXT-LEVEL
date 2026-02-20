import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_colors.dart';
import '../models/price_record.dart';
import '../models/extracted_item.dart';
import '../services/price_service_csv.dart';

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
  double _suggestedPrice = 3.50;
  String _selectedCategory = "Keperluan";

  final List<Map<String, String>> _categories = [
    {"id": "Keperluan", "label": "Barangan Keperluan"},
    {"id": "Protein", "label": "Daging & Protein"},
    {"id": "Sayur", "label": "Sayur-sayuran"},
    {"id": "Buah", "label": "Buah-buahan"},
  ];

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
  List<ExtractedItem> _extractedItems = [];
  bool _isExtracting = true;
  bool _isLoading = true;
  bool _isConfirmed = false; 
  final TextEditingController _newItemController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // ===================== Loading Dialog =====================
  final ValueNotifier<String> _loadingMessage = ValueNotifier("Memuatkan resit...");

  Future<void> _showLoadingDialog() async {
  showDialog(
    context: context,
    barrierDismissible: false, // 用户无法点击外部关闭
    builder: (_) => WillPopScope(
      onWillPop: () async => false, // 禁止返回键关闭
      child: Material(
        color: Colors.black26, // 半透明背景，突出卡片
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 220,
            decoration: BoxDecoration(
              color: AppColors.offWhite, // 卡片浅色背景
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
                  child: Icon(Icons.sync, size: 50, color: AppColors.jungleGreen),
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
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 6,
                    child: LinearProgressIndicator(
                      color: AppColors.jungleGreen,
                      backgroundColor: Colors.black12,
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
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    Future.microtask(() async {
      await _showLoadingDialog();
      _updateLoadingMessage("Memuatkan resit...");
      await _startAutoExtraction();

      _updateLoadingMessage("Memuat turun harga...");
      await _loadData();

      await _hideLoadingDialog();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _newItemController.dispose();
    super.dispose();
  }

  // ===================== 收据提取 =====================
  Future<void> _startAutoExtraction() async {
    setState(() => _isExtracting = true);

    await Future.delayed(const Duration(seconds: 2));

    final today = DateTime.now();
    final mockData = [
      ExtractedItem(name: "Beras 5kg", price: "RM 18.50", date: today),
      ExtractedItem(name: "Ayam 1kg", price: "RM 9.90", date: today),
      ExtractedItem(name: "Telur Gred A", price: "RM 12.00", date: today),
      ExtractedItem(name: "Minyak Masak", price: "RM 6.80", date: today),
    ];

    final newItems = mockData
        .where((item) =>
            !_extractedItems.any((e) =>
                e.name == item.name &&
                e.date.year == item.date.year &&
                e.date.month == item.date.month &&
                e.date.day == item.date.day))
        .toList();

    if (!mounted) return;

    setState(() {
      _extractedItems.addAll(newItems);
      _isExtracting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Resit berjaya diproses ✅")),
    );
  }

  // ===================== 加载价格数据 =====================
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final data = await _priceService.getLatestPrices();
      final processed = await compute(_processPriceDataSync, data);

      if (!mounted) return;

      setState(() {
        _apiPrices = processed;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Load data error: $e")),
      );
    }
  }

  static List<PriceRecord> _processPriceDataSync(List<PriceRecord> data) {
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    List<PriceRecord> processed = [];

    for (var record in data) {
      DateTime? lastDate;
      try {
        lastDate = DateTime.parse(record.date);
      } catch (_) {
        lastDate = null;
      }

      if (lastDate == null || lastDate.isBefore(cutoff)) {
        double aiPrice = record.oldPrice > 0 ? record.oldPrice * 1.2 : 3.50;
        processed.add(PriceRecord(
          itemName: record.itemName,
          oldPrice: 0,
          newPrice: aiPrice,
          history: [],
          unit: record.unit,
          date: "",
          category: record.category.isEmpty ? "Umum" : record.category,
          isAiPrice: true,
          aiSuggestedPrice: aiPrice,
        ));
      } else {
        processed.add(record);
      }
    }

    return processed;
  }

  Future<double> getAiSuggestedPrice(String itemName, double lastPrice) async {
    return lastPrice > 0 ? lastPrice * 1.2 : 3.50;
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
            _buildReceiptExtractionSection(),
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

// 顶部 Receipt Extraction Section
Widget _buildReceiptExtractionSection() {
  return Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题 + Scan Button
        Row(
          children: [
            Icon(Icons.receipt_long, color: AppColors.jungleGreen),
            const SizedBox(width: 8),
            const Text(
              "AI Receipt Scanner",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: _isExtracting ? null : _startAutoExtraction,
              child: const Text(
                "Scan",
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 如果没有数据
        if (_extractedItems.isEmpty)
          const Text(
            "Belum ada resit diimbas.",
            style: TextStyle(color: Colors.grey),
          ),

        // 显示已提取的 items
        if (_extractedItems.isNotEmpty)
          Column(
            children: _extractedItems.asMap().entries.map((entry) {
              int idx = entry.key;
              ExtractedItem item = entry.value;
              final nameController = TextEditingController(text: item.name);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // 名称编辑
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _extractedItems[idx] = _extractedItems[idx].copyWith(name: val);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 价格显示
                    Expanded(
                      flex: 1,
                      child: Text(
                        item.price,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 删除按钮
                    InkWell(
                      onTap: () {
                        setState(() {
                          _extractedItems.removeAt(idx);
                        });
                      },
                      child: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 12),

        // Tambah 新 item 按钮
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.jungleGreen,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    onPressed: () {
      showDialog(
        context: context,
        builder: (_) {
          final nameController = TextEditingController();
          final priceController = TextEditingController();

          return AlertDialog(
            title: const Text("Tambah Item Baru"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Nama Item",
                    hintText: "Masukkan nama barang",
                  ),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: "Harga (RM)",
                    hintText: "0.00",
                  ),
                  // 限制只能输入数字和点
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                    setState(() {
                      _extractedItems.add(
                        ExtractedItem(
                          name: nameController.text,
                          // 格式化价格为两位小数
                          price: "RM ${double.tryParse(priceController.text)?.toStringAsFixed(2) ?? "0.00"}",
                          date: DateTime.now(),
                        ),
                      );
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text("Tambah"),
              ),
            ],
          );
        },
      );
    },
    icon: const Icon(Icons.add),
    label: const Text("Tambah Item"),
  ),
),
        const SizedBox(height: 12),

        // Sahkan Data Button
        if (_extractedItems.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: _isConfirmed
                  ? null
                  : () async {
                      setState(() => _isConfirmed = true);

                      // 弹 loading dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => Dialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          child: Padding(
                            padding: const EdgeInsets.all(30),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                CircularProgressIndicator(),
                                SizedBox(height: 20),
                                Text(
                                  "Mengesahkan Data...",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );

                      await Future.delayed(const Duration(seconds: 2));

                      if (!mounted) return;

                      Navigator.pop(context); // 关闭 dialog

                      setState(() => _isConfirmed = false);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Resit berjaya disahkan ✅"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
              child: const Text(
                "Sahkan Data",
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ),
      ],
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
        childAspectRatio: 1.2,
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
    children: [
      _buildSectionTitle("Keputusan Analisis"),
      _buildCategoryPriceGrid(),
      _buildProfitSimulatorCard(),
    ],
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

    final filtered = _apiPrices
        .where((item) => item.category == _selectedCategory)
        .toList();

    if (filtered.isNotEmpty) {
      _suggestedPrice = filtered.first.oldPrice * 1.2;
    }
  });
},

            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.jungleGreen : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? AppColors.jungleGreen : Colors.grey.shade300,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.jungleGreen.withOpacity(0.3), blurRadius: 8)]
                    : [],
              ),
              child: Center(
                child: Text(
                  cat['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
  final bool hasData = record.hasRecentData;
  final double displayPrice = record.displayPrice;

  // 1. 提取历史数据
  List<double> validHistory = record.history.where((p) => p > 0).toList();
  if (validHistory.isEmpty) validHistory = [displayPrice];
  if (validHistory.length > 3) {
    validHistory = validHistory.sublist(validHistory.length - 3);
  }

  // 2. 核心算法逻辑：修正 Pisang Emas 等起价显红、降价显绿的问题
  // ✅ 永远以最后一个柱子的值为 current
double current = validHistory.isNotEmpty
    ? validHistory.last
    : displayPrice;

// 前一个月价格
double prev;
if (validHistory.length >= 2) {
  prev = validHistory[validHistory.length - 2];
} else {
  prev = current;
}

double diff = current - prev;
double percent = prev != 0 ? (diff / prev) * 100 : 0;

Color mainThemeColor;
String arrow = "";

if (!hasData) {
  mainThemeColor = Colors.grey;
} else if (diff > 0.001) {
  mainThemeColor = Colors.red.shade700; // 涨价
  arrow = "↑";
} else if (diff < -0.001) {
  mainThemeColor = Colors.green.shade700; // 降价
  arrow = "↓";
} else {
  mainThemeColor = Colors.amber.shade800; // ✅ 持平黄色
  arrow = ""; 
}


// 最后一个柱子颜色用 mainThemeColor，历史柱子保持灰色
Color getBarColor(int index) {
  if (!hasData) return Colors.grey;
  if (index == validHistory.length - 1) return mainThemeColor;
  return Colors.grey.shade300;
}

  // 计算图表最大高度，预留空间给柱子顶部的价格文字
  double maxY = validHistory.reduce((a, b) => a > b ? a : b) * 1.35;

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 商品名称
            Text(
              record.itemName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15, // 略微调大的字号
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 2),

            // 价格大字体
            Text(
              "RM ${current.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: mainThemeColor,
              ),
            ),

            // 日期
            Text(
              hasData ? record.date : "Ramalan AI Gemini",
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),

            const SizedBox(height: 12),

            // 饱满的 Bar Chart
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: false,
                    touchTooltipData: BarTouchTooltipData(
                      // 💡 移除灰色背景：设置透明
                      tooltipBgColor: Colors.transparent, 
                      tooltipPadding: EdgeInsets.zero,
                      tooltipMargin: 2,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        bool isLast = groupIndex == validHistory.length - 1;
                        return BarTooltipItem(
                          rod.toY.toStringAsFixed(2),
                          TextStyle(
                            // 💡 价格字体调小至 9，视觉更精致
                            fontSize: 9, 
                            fontWeight: FontWeight.bold,
                            color: isLast ? mainThemeColor : Colors.black54,
                          ),
                        );
                      },
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        getTitlesWidget: (value, meta) {
                          int idx = value.toInt();
                          if (idx >= 0 && idx < validHistory.length) {
                            String label = hasData
                                ? _getMonthNameShort(DateTime.parse(record.date)
                                    .subtract(Duration(days: 30 * (validHistory.length - 1 - idx)))
                                    .month)
                                : "AI";
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                label.length >= 3 ? label.substring(0, 3) : label,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: List.generate(validHistory.length, (index) {
                    bool isLast = index == validHistory.length - 1;
                    return BarChartGroupData(
                      x: index,
                      showingTooltipIndicators: [0], // 始终在柱子上显示价格
                      barRods: [
                        BarChartRodData(
                          toY: validHistory[index],
                          width: 16, // 饱满的柱状宽度
                          color: isLast ? mainThemeColor : Colors.grey.shade300,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        )
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),

        // 右上角涨跌 Badge
        if (hasData)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: mainThemeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$arrow${percent.abs().toStringAsFixed(1)}%",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: mainThemeColor,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

// 辅助函数：月份转马来文缩写
String _getMonthNameShort(int month) {
  const months = [
    "Jan", "Feb", "Mac", "Apr", "Mei", "Jun",
    "Jul", "Ogos", "Sept", "Okt", "Nov", "Dis"
  ];
  return months[month - 1];
}

  // ------------------ PROFIT SIMULATOR ------------------

  Widget _buildProfitSimulatorCard() {
  final filteredList = _apiPrices
      .where((item) => item.category == _selectedCategory)
      .toList();

  if (filteredList.isEmpty) return const SizedBox();

  double cost = filteredList.first.oldPrice;
  bool hasValidPrice = cost > 0;

  double minPrice = hasValidPrice ? cost : 0;
  double maxPrice = hasValidPrice ? cost * 2 : 0;

  double safeSuggested = hasValidPrice
      ? _suggestedPrice.clamp(minPrice, maxPrice)
      : 0;

  double marginPercent = hasValidPrice
      ? ((safeSuggested - cost) / cost) * 100
      : 0;

  Color statusColor;
  if (!hasValidPrice) {
    statusColor = Colors.grey; // ❌ 无效价格
  } else if (marginPercent < 0) {
    statusColor = AppColors.warningRed;
  } else if (marginPercent < 20) {
    statusColor = AppColors.lightOrange;
  } else {
    statusColor = AppColors.successGreen;
  }

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: statusColor, width: 2),
    ),
    child: Column(
      children: [
        Text(
          "Simulator Harga Jualan",
          style: TextStyle(
              color: AppColors.jungleGreen,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          "RM ${safeSuggested.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
        Slider(
          value: safeSuggested,
          min: minPrice,
          max: maxPrice,
          divisions: hasValidPrice ? 40 : 1,
          onChanged: hasValidPrice
              ? (value) {
                  setState(() {
                    _suggestedPrice = value;
                  });
                }
              : null, // ❌ 禁用 slider
        ),
        Text(
          hasValidPrice
              ? "Margin Untung: ${marginPercent.toStringAsFixed(1)}%"
              : "Tiada data harga",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: statusColor),
        ),
      ],
    ),
  );
}

  // ------------------ SECTION TITLE ------------------

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(title,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.jungleGreen)),
    );
  }
}
