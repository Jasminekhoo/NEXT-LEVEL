import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_colors.dart';
import '../models/price_record.dart';
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

  final double scanningHeight = 220;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _loadData();
  }

  Future<void> _loadData() async {
  try {
    final data = await _priceService.getLatestPrices();

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
        // 没过去三个月数据 → AI 价格
        double aiPrice = await getAiSuggestedPrice(record.itemName, record.oldPrice);
        processed.add(PriceRecord(
          itemName: record.itemName,
          oldPrice: 0,
          newPrice: aiPrice,
          history: [],
          unit: record.unit,
          date: "",
          category: record.category,
          isAiPrice: true,
          aiSuggestedPrice: aiPrice,
        ));
      } else {
        processed.add(record);
      }
    }

    if (mounted) {
      setState(() {
        _apiPrices = processed;
        _isScanning = false;
      });
    }
  } catch (e, st) {
    if (mounted) {
      setState(() => _isScanning = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Sistem Error"),
          content: Text(e.toString()),
        ),
      );
    }
    print("Load Data Error: $e\n$st");
  }
}

Future<double> getAiSuggestedPrice(String itemName, double lastPrice) async {
  // 临时示例：原价 0 用 3.50，否则加 20%
  return lastPrice > 0 ? lastPrice * 1.2 : 3.50;
}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.offWhite,
    appBar: AppBar(
      title: const Text(
        "Analisis Pintar Gemini",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
      ),
      backgroundColor: AppColors.jungleGreen,
      centerTitle: true,
    ),
    body: Column(
      children: [
        _buildScanningSection(),
        Expanded(
          child: SafeArea(
            child: !_isScanning
                ? SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildCategoryFilter(),
                        if (_apiPrices.isNotEmpty) ...[
                          _buildResultsList(), // ✅ 改这里
                        ],
                        if (_apiPrices.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: Text("Tiada data harga tersedia.")),
                          ),
                      ],
                    ),
                  )
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
          ),
        ),
      ],
    ),
  );
}

// ------------------ CATEGORY PRICE GRID ------------------
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
// ------------------ SCANNING SECTION ------------------

Widget _buildScanningSection() {
  // 根据扫描状态动态调整容器高度
  double currentHeight = _isScanning ? 200.0 : 120.0; 

  return AnimatedContainer(
    // 💡 修复点：将 EdgeInsets.all(500) 改为 Duration
    duration: const Duration(milliseconds: 500), 
    width: double.infinity,
    height: currentHeight,
    margin: const EdgeInsets.all(16),
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
    child: Stack(
      children: [
        // 背景图标
        Center(
          child: Icon(
            Icons.receipt_long,
            size: 80,
            color: _isScanning ? AppColors.jungleGreen.withOpacity(0.1) : Colors.grey.shade200,
          ),
        ),

        // 扫描线动画
        // 在 _buildScanningSection 内部
if (_isScanning)
  RepaintBoundary( // 💡 关键：隔离重绘区域
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Align(
          alignment: Alignment(0, _controller.value * 2 - 1),
          child: child,
        );
      },
      child: Container(
        height: 3, // 线条细一点
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          boxShadow: [ // 💡 增加发光效果，掩盖微小掉帧
            BoxShadow(
              color: AppColors.jungleGreen.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            )
          ],
          gradient: LinearGradient(
            colors: [
              AppColors.jungleGreen.withOpacity(0),
              AppColors.jungleGreen,
              AppColors.jungleGreen.withOpacity(0),
            ],
          ),
        ),
      ),
    ),
  ),

        // 底部文字状态
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isScanning)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.jungleGreen),
                  ),
                if (_isScanning) const SizedBox(width: 8),
                Text(
                  _isScanning ? "Sedang Mengimbas..." : "Imbasan Selesai ✅",
                  style: TextStyle(
                    color: AppColors.jungleGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

void startScanning() {
  setState(() {
    _isScanning = true;
  });
  
  // 💡 启动动画：往返重复播放
  _controller.repeat(reverse: true);

  // 模拟扫描 3 秒后结束
  Future.delayed(const Duration(seconds: 3), () {
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
      // 💡 停止动画并复位
      _controller.stop();
      _controller.reset();
    }
  });
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
