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

            // 4. 趋势图表 (fl_chart)
            _buildTrendChart(),
            const SizedBox(height: 40),

            // 5. ✨✨ 交互式贷款模拟器 ✨✨
            const LoanSimulatorCard(),
            const SizedBox(height: 40),

            // 6. 贷款选项 (TEKUN)
            _buildTekunCard(),
            const SizedBox(height: 30),

            // 7. 下载按钮 (✅ 修复：加上了 context)
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

  // --- 模块 4: 趋势折线图 ---
  Widget _buildTrendChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Trend Untung Bersih (7 Hari)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Container(
          height: 200,
          width: double.infinity,
          padding: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    const FlSpot(0, 1), const FlSpot(1, 1.5), const FlSpot(2, 1.2),
                    const FlSpot(3, 1.8), const FlSpot(4, 1.6), const FlSpot(5, 2.2), const FlSpot(6, 2.5),
                  ],
                  isCurved: true,
                  color: AppColors.jungleGreen,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: AppColors.jungleGreen.withOpacity(0.1)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 模块 6: TEKUN 选项 ---
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

  // --- 模块 7: 下载按钮 (✅ 修复：移回了正确的类里) ---
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
// ✨ 新功能：交互式贷款模拟器 (StatefulWidget)
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