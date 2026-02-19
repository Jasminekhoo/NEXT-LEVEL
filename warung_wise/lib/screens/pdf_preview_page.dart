import 'package:flutter/material.dart';
import '../app_colors.dart'; // 确保路径正确

class PdfPreviewPage extends StatelessWidget {
  const PdfPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // 模拟看 PDF 时的灰色背景
      appBar: AppBar(
        title: const Text("Pratonton Dokumen (TEKUN)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.jungleGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // 模拟分享功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Laporan berjaya dikongsi ke WhatsApp!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 模拟一张 A4 纸
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 报表头部 (Header)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("WARUNG WISE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.deepTeal)),
                          Text("Sistem Kewangan AI Mikro", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.jungleGreen),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text("TEKUN READY", style: TextStyle(color: AppColors.jungleGreen, fontWeight: FontWeight.bold, fontSize: 10)),
                      )
                    ],
                  ),
                  
                  const Divider(height: 40, thickness: 2),

                  // 商家信息
                  const Center(
                    child: Text("PENYATA UNTUNG RUGI (PROFIT & LOSS)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow("Nama Perniagaan:", "Nasi Lemak Mak Cik Kiah"),
                  _buildInfoRow("Tempoh Laporan:", "01 Feb 2026 - 28 Feb 2026"),
                  _buildInfoRow("Skor Kredit Warung:", "750 (Sihat)"),

                  const SizedBox(height: 30),

                  // 财务数据表格
                  const Text("Ringkasan Kewangan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(1),
                    },
                    children: [
                      _buildTableRow("Total Pendapatan (Jualan)", "RM 4,250.00", isHeader: true),
                      _buildTableRow("Tolak: Kos Bahan Mentah", "- RM 1,500.00"),
                      _buildTableRow("Tolak: Kos Utiliti & Sewa", "- RM 350.00"),
                      _buildTableRow("Keuntungan Bersih (Net Profit)", "RM 2,400.00", isBold: true, textColor: AppColors.jungleGreen),
                    ],
                  ),

                  const SizedBox(height: 50),

                  // 底部签名与 AI 认证
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        children: [
                          Container(width: 100, height: 1, color: Colors.black),
                          const SizedBox(height: 5),
                          const Text("Tandatangan Pemilik", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Column(
                        children: const [
                          Icon(Icons.verified, color: AppColors.successBlue, size: 40),
                          SizedBox(height: 5),
                          Text("Disahkan oleh\nGemini AI", textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 底部操作按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // 返回上一页
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF dimuat turun ke peranti anda.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.jungleGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text("Simpan PDF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // 辅助方法：构建信息行
  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
  }

  // 辅助方法：构建表格行
  TableRow _buildTableRow(String title, String value, {bool isHeader = false, bool isBold = false, Color? textColor}) {
    return TableRow(
      decoration: BoxDecoration(color: isHeader ? Colors.grey.shade100 : Colors.white),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(title, style: TextStyle(fontWeight: isBold || isHeader ? FontWeight.bold : FontWeight.normal)),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: isBold || isHeader ? FontWeight.bold : FontWeight.normal, color: textColor ?? Colors.black)),
        ),
      ],
    );
  }
}