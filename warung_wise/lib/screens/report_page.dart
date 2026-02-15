import 'package:flutter/material.dart';
import '../app_colors.dart';

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
            const SizedBox(height: 40),

            // 2. 贷款选项 (TEKUN)
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
            ),
            const SizedBox(height: 30),

            // 3. 下载按钮
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
                icon: const Icon(Icons.download, color: Colors.white, size: 30),
                label: const Text("Muat Turun Laporan PDF", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}