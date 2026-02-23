import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_colors.dart';
import 'pdf_preview_page.dart';

// ==========================================
// 主页面：Laporan & Kredit (Stateless)
// ==========================================
class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan & Kredit", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.offWhite,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // 1. 信用仪表盘
            _buildCreditHeader(),
            const SizedBox(height: 30),

            // 2. Gemini 商业洞察卡片
            _buildAIInsightCard(),
            const SizedBox(height: 30),

            // 3. 财务摘要
            _buildFinanceSummary(),
            const SizedBox(height: 30),

            // 4. ✨✨ 新增：AI 支出分析饼图 (可互动) ✨✨
            const ExpensePieChartCard(),
            const SizedBox(height: 30),

            // 5. 双柱状图 (Income vs Expense)
            const IncomeExpenseChartCard(),
            const SizedBox(height: 40),

            // 6. 交互式贷款模拟器
            const LoanSimulatorCard(),
            const SizedBox(height: 40),

            // 7. 贷款选项 (TEKUN)
            _buildTekunCard(),
            const SizedBox(height: 30),

            // 8. 下载按钮 (跳转到 PDF)
            _buildDownloadButton(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- 模块 1: 信用仪表盘 ---
  Widget _buildCreditHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 220, height: 220,
              child: CircularProgressIndicator(
                value: 0.8,
                strokeWidth: 20,
                backgroundColor: Colors.grey[300],
                color: AppColors.jungleGreen,
              ),
            ),
            const Column(
              children: [
                Text("Sihat", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.jungleGreen)),
                Text("Skor: 750", style: TextStyle(fontSize: 22, color: Colors.grey)),
              ],
            )
          ],
        ),
        const SizedBox(height: 20),
        const Text("Layak memohon pinjaman ✅", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
      ],
    );
  }

  // --- 模块 2: AI 洞察卡片 ---
  Widget _buildAIInsightCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.jungleGreen, Color(0xFF2E7D32)]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.lightOrange, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Prestasi perniagaan anda meningkat 15% bulan ini. Aliran tunai stabil dan layak untuk memohon Mikro-Kredit TEKUN.",
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // --- 模块 3: 财务摘要 ---
  Widget _buildFinanceSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ringkasan Februari 2026", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        _buildFinanceRow("Total Jualan", "+ RM 4,250.00", AppColors.successGreen),
        _buildFinanceRow("Total Kos", "- RM 1,850.00", AppColors.warningRed),
        const Divider(),
        _buildFinanceRow("Untung Bersih", "RM 2,400.00", AppColors.jungleGreen, isBold: true),
      ],
    );
  }

  Widget _buildFinanceRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: valueColor)),
        ],
      ),
    );
  }

  // --- 模块 7: TEKUN 选项 ---
  Widget _buildTekunCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(color: Colors.blue[900], borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text("TEKUN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Skim TEKUN", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text("Dokumen dah siap!", style: TextStyle(fontSize: 16, color: Colors.green)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- 模块 8: 下载按钮 ---
  Widget _buildDownloadButton(BuildContext context) { 
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PdfPreviewPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.jungleGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
        ),
        icon: const Icon(Icons.download, color: Colors.white, size: 30),
        label: const Text("Muat Turun Laporan PDF", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ==========================================
// ✨ 模块：AI 支出分析饼图 (StatefulWidget)
// ==========================================
class ExpensePieChartCard extends StatefulWidget {
  const ExpensePieChartCard({super.key});

  @override
  State<ExpensePieChartCard> createState() => _ExpensePieChartCardState();
}

class _ExpensePieChartCardState extends State<ExpensePieChartCard> {
  int touchedIndex = -1; 

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Pecahan Perbelanjaan (AI)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.deepTeal)),
          const SizedBox(height: 5),
          const Text("Klik pada carta untuk butiran lanjut", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 30),
          
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2, 
                centerSpaceRadius: 40, 
                sections: showingSections(),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          Column(
            children: [
              _buildLegend(color: AppColors.warningRed, text: 'Bahan Mentah (Ayam, Nasi, dll)', percentage: '60%'),
              const SizedBox(height: 8),
              _buildLegend(color: AppColors.lightOrange, text: 'Sewa Tapak & Utiliti', percentage: '25%'),
              const SizedBox(height: 8),
              _buildLegend(color: AppColors.deepTeal, text: 'Lain-lain (Minyak Motor, Plastik)', percentage: '15%'),
            ],
          ),
          
          const Divider(height: 30),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb, color: AppColors.lightOrange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Tinjauan AI: Kos Bahan Mentah anda meningkat 5% minggu ini. Pertimbangkan untuk borong ayam dari Pembekal X untuk lebih penjimatan.",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(3, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 60.0 : 50.0; 
      const shadows = [Shadow(color: Colors.black26, blurRadius: 2)];

      switch (i) {
        case 0:
          return PieChartSectionData(
            color: AppColors.warningRed,
            value: 60,
            title: '60%',
            radius: radius,
            titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, shadows: shadows),
          );
        case 1:
          return PieChartSectionData(
            color: AppColors.lightOrange,
            value: 25,
            title: '25%',
            radius: radius,
            titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, shadows: shadows),
          );
        case 2:
          return PieChartSectionData(
            color: AppColors.deepTeal,
            value: 15,
            title: '15%',
            radius: radius,
            titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, shadows: shadows),
          );
        default:
          throw Error();
      }
    });
  }

  Widget _buildLegend({required Color color, required String text, required String percentage}) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey))),
        Text(percentage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

// ==========================================
// ✨ 模块：Income vs Expense 双柱状图 (StatefulWidget)
// ==========================================
class IncomeExpenseChartCard extends StatefulWidget {
  const IncomeExpenseChartCard({super.key});

  @override
  State<IncomeExpenseChartCard> createState() => _IncomeExpenseChartCardState();
}

class _IncomeExpenseChartCardState extends State<IncomeExpenseChartCard> {
  bool isMonthly = true; 

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Prestasi Jualan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.deepTeal)),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildToggleButton("Bulan", true),
                    _buildToggleButton("Tahun", false),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.successGreen, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 6),
              const Text("Pendapatan", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(width: 20),
              Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.warningRed, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 6),
              const Text("Perbelanjaan", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 30),

          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: isMonthly ? 6000 : 60000, 
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11);
                        Widget text;
                        if (isMonthly) {
                          switch (value.toInt()) {
                            case 0: text = const Text('Jan', style: style); break;
                            case 1: text = const Text('Feb', style: style); break;
                            case 2: text = const Text('Mac', style: style); break;
                            case 3: text = const Text('Apr', style: style); break;
                            case 4: text = const Text('Mei', style: style); break;
                            case 5: text = const Text('Jun', style: style); break;
                            default: text = const Text('', style: style); break;
                          }
                        } else {
                          switch (value.toInt()) {
                            case 0: text = const Text('2022', style: style); break;
                            case 1: text = const Text('2023', style: style); break;
                            case 2: text = const Text('2024', style: style); break;
                            case 3: text = const Text('2025', style: style); break;
                            case 4: text = const Text('2026', style: style); break;
                            default: text = const Text('', style: style); break;
                          }
                        }
                        //return SideTitleWidget(axisSide: meta.axisSide, child: text);
                        return SideTitleWidget(meta: meta, child: text);
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: isMonthly ? _getMonthlyData() : _getYearlyData(),
              ),
              swapAnimationDuration: const Duration(milliseconds: 350), 
              swapAnimationCurve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String title, bool isMonthButton) {
    bool isActive = isMonthly == isMonthButton;
    return GestureDetector(
      onTap: () {
        setState(() {
          isMonthly = isMonthButton; 
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.jungleGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _getMonthlyData() {
    return [
      _makeGroupData(0, 4000, 2500),
      _makeGroupData(1, 4500, 2800),
      _makeGroupData(2, 3800, 3000), 
      _makeGroupData(3, 5000, 2600),
      _makeGroupData(4, 5200, 2700),
      _makeGroupData(5, 5800, 2900),
    ];
  }

  List<BarChartGroupData> _getYearlyData() {
    return [
      _makeGroupData(0, 35000, 20000),
      _makeGroupData(1, 42000, 24000),
      _makeGroupData(2, 40000, 25000),
      _makeGroupData(3, 52000, 28000),
      _makeGroupData(4, 58000, 31000),
    ];
  }

  BarChartGroupData _makeGroupData(int x, double income, double expense) {
    return BarChartGroupData(
      barsSpace: 4,
      x: x,
      barRods: [
        BarChartRodData(toY: income, color: AppColors.successGreen, width: 10, borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3))),
        BarChartRodData(toY: expense, color: AppColors.warningRed, width: 10, borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3))),
      ],
    );
  }
}

// ==========================================
// ✨ 模块：交互式贷款模拟器 (StatefulWidget)
// ==========================================
class LoanSimulatorCard extends StatefulWidget {
  const LoanSimulatorCard({super.key});

  @override
  State<LoanSimulatorCard> createState() => _LoanSimulatorCardState();
}

class _LoanSimulatorCardState extends State<LoanSimulatorCard> {
  double _loanAmount = 5000.0; 
  final double _netProfit = 2400.0; 
  final int _months = 12; 
  final double _interestRate = 0.04; 

  @override
  Widget build(BuildContext context) {
    double totalRepayment = _loanAmount + (_loanAmount * _interestRate);
    double monthlyInstallment = totalRepayment / _months;
    double debtRatio = (monthlyInstallment / _netProfit) * 100;
    bool isHealthy = debtRatio <= 30; 

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.jungleGreen.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calculate_outlined, color: AppColors.jungleGreen),
              SizedBox(width: 10),
              Text("Simulator Pinjaman AI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          
          Text("Saya ingin pinjam: RM ${_loanAmount.toStringAsFixed(0)}", 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.jungleGreen)),
          
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.jungleGreen,
              inactiveTrackColor: AppColors.jungleGreen.withOpacity(0.2),
              thumbColor: AppColors.jungleGreen,
              overlayColor: AppColors.jungleGreen.withOpacity(0.1),
            ),
            child: Slider(
              value: _loanAmount,
              min: 1000,
              max: 10000,
              divisions: 18, 
              onChanged: (value) {
                setState(() {
                  _loanAmount = value;
                });
              },
            ),
          ),
          
          const Divider(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Bayaran Bulanan (12 Bulan):", style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text("RM ${monthlyInstallment.toStringAsFixed(2)}", 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),

          const SizedBox(height: 15),

          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isHealthy ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(isHealthy ? Icons.check_circle : Icons.warning_amber_rounded, 
                     color: isHealthy ? Colors.green.shade700 : Colors.red.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isHealthy 
                      ? "Aliran tunai sihat. Anda mampu membayar jumlah ini." 
                      : "Amaran AI: Komitmen terlalu tinggi! Sila kurangkan jumlah.",
                    style: TextStyle(
                      color: isHealthy ? Colors.green.shade900 : Colors.red.shade900, 
                      fontSize: 12, fontWeight: FontWeight.w500
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}