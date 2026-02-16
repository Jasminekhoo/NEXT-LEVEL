// lib/screens/report_page.dart

import 'package:flutter/material.dart';
import '../app_colors.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text("Laporan & Kredit", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // 不显示返回键，因为通常在底部导航栏里
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. 信用仪表盘 (AI Verified Score)
            // ==========================================
            const SizedBox(height: 10),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220, height: 220,
                    child: CircularProgressIndicator(
                      value: 0.8,
                      strokeWidth: 20,
                      backgroundColor: Colors.grey[200],
                      color: AppColors.jungleGreen,
                    ),
                  ),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Sihat", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.jungleGreen)),
                      Text("Skor: 750", style: TextStyle(fontSize: 22, color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text("Layak memohon pinjaman ✅", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
            ),
            
            const SizedBox(height: 30),

            // ==========================================
            // 2. Gemini AI Business Insight
            // ==========================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.jungleGreen, Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.lightOrange, size: 24),
                      const SizedBox(width: 10),
                      Text("Gemini Business Insight", 
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Prestasi perniagaan anda meningkat 15% bulan ini. Aliran tunai stabil dan layak untuk memohon Mikro-Kredit TEKUN.",
                    style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ==========================================
            // 3. Ringkasan Bulanan (月度收支总结 - P&L)
            // ==========================================
            const Text("Ringkasan Februari 2026", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.jungleGreen)),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _buildSummaryRow("Total Jualan", "+ RM 4,250.00", AppColors.successGreen),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _buildSummaryRow("Total Kos", "- RM 1,850.00", AppColors.warningRed),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _buildSummaryRow("Untung Bersih", "RM 2,400.00", AppColors.jungleGreen, isBold: true),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ==========================================
            // 4. Trend Untung (可视化数据图表)
            // ==========================================
            const Text("Trend Untung Bersih (7 Hari)", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.jungleGreen)),
            const SizedBox(height: 15),
            Container(
              height: 180,
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: CustomPaint(
                painter: ChartPainter(),
              ),
            ),

            const SizedBox(height: 30),

            // ==========================================
            // 5. 贷款选项 (TEKUN 银行卡片)
            // ==========================================
            Container(
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
                    decoration: BoxDecoration(
                      color: const Color(0xFF003399), 
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: const Center(
                      child: Text("TEKUN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Skim TEKUN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Dokumen dah siap!", style: TextStyle(fontSize: 14, color: AppColors.successGreen, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ==========================================
            // 6. 下载 Laporan PDF 按钮
            // ==========================================
            SizedBox(
              width: double.infinity,
              height: 65,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.jungleGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                icon: const Icon(Icons.download, color: Colors.white, size: 28),
                label: const Text("Muat Turun Laporan PDF", 
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 辅助组件：收支摘要行
  Widget _buildSummaryRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        Text(value, style: TextStyle(
          fontSize: 18, 
          fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, 
          color: color
        )),
      ],
    );
  }
}

// 简单的折线图绘制器
class ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.jungleGreen
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.lineTo(size.width * 0.2, size.height * 0.6);
    path.lineTo(size.width * 0.4, size.height * 0.7);
    path.lineTo(size.width * 0.6, size.height * 0.3);
    path.lineTo(size.width * 0.8, size.height * 0.4);
    path.lineTo(size.width, size.height * 0.1);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}