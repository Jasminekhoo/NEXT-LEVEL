import 'package:flutter/material.dart';
import '../app_colors.dart';

class AiAnalysisPage extends StatelessWidget {
  const AiAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analisa AI", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.offWhite,
        centerTitle: true,
        automaticallyImplyLeading: false, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 收据扫描图
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.jungleGreen, width: 2),
                image: const DecorationImage(
                  // 模拟收据图片
                  image: NetworkImage('https://cdn.dribbble.com/users/1393666/screenshots/14995982/media/643f8485295c02604618778642055106.jpg?compress=1&resize=400x300'),
                  fit: BoxFit.cover,
                  opacity: 0.5,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.jungleGreen, size: 60),
                    SizedBox(height: 10),
                    Text("Scan Berjaya!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.jungleGreen))
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // 2. AI 识别结果
            const Text("AI Temui Ini:", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.jungleGreen)),
            const SizedBox(height: 15),
            
            // 警告卡片
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.warningRed, width: 1),
                boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const Text("🥚", style: TextStyle(fontSize: 40)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Telur Gred A", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Text("Harga: RM 18.00", style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(5)),
                          child: const Text("⚠️ Naik RM 2.00!", style: TextStyle(color: AppColors.warningRed, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 3. Gemini 建议
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE0F2F1), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.jungleGreen, width: 1.5),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.jungleGreen, size: 28),
                      SizedBox(width: 10),
                      Text("Gemini Insight", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.jungleGreen)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Mak Cik, kos telur dah naik! Kos sepinggan nasi lemak sekarang RM 2.80.\n\nKalau jual RM 3.00, untung sikit sangat. Cadangan: Naikkan harga ke RM 3.50.",
                    style: TextStyle(fontSize: 18, height: 1.4, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.jungleGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("Kira Harga Baru", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}