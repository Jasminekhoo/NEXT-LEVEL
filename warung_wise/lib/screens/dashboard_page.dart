// lib/screens/dashboard_page.dart

import 'package:flutter/material.dart';
import 'dart:async'; 
import '../app_colors.dart';
import '../widgets/custom_widgets.dart'; 
import 'transaction_history_page.dart'; 
import 'transaction_detail_page.dart'; 
import '../models/extracted_item.dart';
import 'receipt_review_page.dart';
import 'profile_page.dart'; 


class DashboardPage extends StatefulWidget {
  final VoidCallback onScanTap;

  const DashboardPage({
    super.key,
    required this.onScanTap,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ValueNotifier<String> _loadingText =
      ValueNotifier("Memulakan imbasan...");
  // 初始净赚金额
  double totalUntung = 145.50;

  // 2. 初始数据 (🔥 必须加上 time，否则报错)
  List<Transaction> transactions = [
    Transaction(title: "Beli Telur Gred A", amount: "- RM 18.00", isIncome: false, date: "Hari Ini", time: "08:30 AM"),
    Transaction(title: "Jual Nasi Lemak (50 pax)", amount: "+ RM 150.00", isIncome: true, date: "Hari Ini", time: "11:45 AM"),
    Transaction(title: "Beli Beras (10kg)", amount: "- RM 38.00", isIncome: false, date: "Hari Ini", time: "09:00 AM"),
  ];

  // ==========================================
  // 📸 Snap Receipt Flow
  // ==========================================
  Future<void> _handleSnapReceipt() async {
  // 1️⃣ 显示 Loading Dialog
  _showScanLoading();

  _loadingText.value = "Mengambil gambar...";
  await Future.delayed(const Duration(seconds: 1));

  _loadingText.value = "Mengekstrak teks...";
  await Future.delayed(const Duration(seconds: 1));

  _loadingText.value = "Menganalisis dengan AI Gemini...";
  await Future.delayed(const Duration(seconds: 1));

  // 2️⃣ 模拟提取的物品
  final today = DateTime.now();
  final extractedItems = [
    ExtractedItem(name: "Beras 5kg", price: "RM 18.50", date: today),
    ExtractedItem(name: "Ayam 1kg", price: "RM 9.90", date: today),
    ExtractedItem(name: "Telur Gred A", price: "RM 12.00", date: today),
  ];

  if (!mounted) return;

  // 3️⃣ 关闭 Loading
  Navigator.pop(context);

  // 4️⃣ 跳转到 ReceiptReviewPage，并等待用户确认/修改
  final result = await Navigator.push<List<ExtractedItem>>(
    context,
    MaterialPageRoute(
      builder: (_) => ReceiptReviewPage(extractedItems: extractedItems),
    ),
  );

  // 5️⃣ 如果用户确认有数据
  if (result != null && result.isNotEmpty) {
    setState(() {
      for (var item in result) {
        // 转成 Transaction（成本支出）
        transactions.insert(
          0,
          Transaction(
            title: "Beli ${item.name}",
            amount: item.price.startsWith("RM") ? "- ${item.price}" : "- RM ${item.price}",
            isIncome: false, // 🔴 支出
            date: "Hari Ini",
            time: _getCurrentTime(),
          ),
        );

        // 更新净赚金额（扣掉成本）
        totalUntung -= double.tryParse(item.price.replaceAll("RM", "").trim()) ?? 0;
      }
    });

    // 6️⃣ 显示 SnackBar 提示
    _showSuccessSnackBar(
      isIncome: false, // 🔴 成本
      text: "Resit berjaya direkod",
      subText: "${result.length} item ditambah ke transaksi.",
    );
  }
}

  void _showScanLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              ValueListenableBuilder<String>(
                valueListenable: _loadingText,
                builder: (_, value, __) => Text(
                  value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 🟢 场景 A: 语音记收入 (Jual)
  // ==========================================
  void _simulateSalesInput() {
    _showListeningDialog("Sedang mendengar...", "'Tadi jual 20 bungkus Nasi Lemak...'");

    Timer(const Duration(seconds: 2), () {
      Navigator.pop(context); 

      // 假设：销售 RM 100，成本 RM 60 -> 净赚 RM 40
      double untungBaru = 40.00;

      setState(() {
        // A. 更新顶部大数字
        totalUntung += untungBaru; 
        
        // B. 🔥 插入新数据 (带上当前时间)
        transactions.insert(0, Transaction(
          title: "Jual Nasi Lemak (20 pax)", 
          amount: "+ RM 100.00", 
          isIncome: true,
          date: "Hari Ini",
          time: _getCurrentTime() // 获取当前时间
        ));
      });

      _showSuccessSnackBar(
        isIncome: true,
        text: "Rekod: 20x Nasi Lemak",
        subText: "Gemini: Untung bersih +RM 40.00 direkodkan."
      );
    });
  }

  // ==========================================
  // 🔴 场景 B: 语音记成本 (Beli/Kos)
  // ==========================================
  void _simulateCostInput() {
    _showListeningDialog("Mencatat Kos...", "'Beli santan & daun pandan RM 25...'");

    Timer(const Duration(seconds: 2), () {
      Navigator.pop(context); 

      double kosBaru = 25.00;

      setState(() {
        // A. 更新顶部大数字 (扣钱)
        totalUntung -= kosBaru; 

        // B. 🔥 插入新数据 (带上当前时间)
        transactions.insert(0, Transaction(
          title: "Beli Santan (Tunai)", 
          amount: "- RM 25.00", 
          isIncome: false,
          date: "Hari Ini",
          time: _getCurrentTime() // 获取当前时间
        ));
      });

      _showSuccessSnackBar(
        isIncome: false, 
        text: "Rekod: Beli Santan (Pasar)",
        subText: "Gemini: Kos RM 25.00 ditolak."
      );
    });
  }

  // 🔥 辅助函数：获取当前时间字符串 (比如 "02:30 PM")
  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final period = now.hour >= 12 ? "PM" : "AM";
    final minute = now.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  }

  // --- 辅助函数：显示弹窗 ---
  void _showListeningDialog(String title, String subtitle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.lightOrange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, size: 40, color: AppColors.lightOrange),
              ),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(subtitle, 
                style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              const LinearProgressIndicator(color: AppColors.lightOrange), 
            ],
          ),
        );
      },
    );
  }

  // --- 辅助函数：显示 SnackBar ---
  void _showSuccessSnackBar({required bool isIncome, required String text, required String subText}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isIncome ? Icons.check_circle : Icons.remove_circle, 
                  color: Colors.white, size: 20
                ),
                const SizedBox(width: 10),
                Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 4),
              child: Text(
                subText, 
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: isIncome ? AppColors.successGreen : AppColors.warningRed, 
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. Header (Untung Bersih)
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 50, left: 24, right: 24),
            decoration: const BoxDecoration(
              color: AppColors.jungleGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                 BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
              ]
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                   // 讓頭像可以被點擊
GestureDetector(
  onTap: () {
    // 點擊後跳轉到 ProfilePage
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  },
  child: Container(
    padding: const EdgeInsets.all(2),
    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
    child: const CircleAvatar(
      radius: 24,
      backgroundImage: NetworkImage('https://tse3.mm.bing.net/th/id/OIP.kp5huS9dTrQdcZH_FcqMTQHaHa?rs=1&pid=ImgDetMain&o=7&rm=3'), 
    ),
  ),
),
                    Stack(
                      children: [
                        const Icon(Icons.notifications_outlined, color: Colors.white, size: 30),
                        Positioned(
                          right: 2, top: 2,
                          child: Container(
                            width: 10, height: 10,
                            decoration: const BoxDecoration(color: AppColors.warningRed, shape: BoxShape.circle),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Untung Bersih",
                            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 5),
                        Text("RM ${totalUntung.toStringAsFixed(2)}", 
                            style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(
                          width: 60, height: 60,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                               CircularProgressIndicator(
                                value: (totalUntung / 200).clamp(0.0, 1.0),
                                backgroundColor: Colors.white24,
                                color: AppColors.lightOrange, 
                                strokeWidth: 6,
                              ),
                              Text("${((totalUntung/200)*100).toInt()}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("Target", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),

          // 2. AI Warning Card
          Transform.translate(
            offset: const Offset(0, -30), 
            child: GestureDetector(
              onTap: widget.onScanTap, 
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.warningRed.withOpacity(0.3)), 
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warningRed.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.campaign_rounded, color: AppColors.warningRed, size: 24),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Amaran AI (Gemini)", 
                            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text("Telur naik harga! Ketik untuk lihat.", 
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                            maxLines: 2, 
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),

          // 3. Big Buttons Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: BigCardButton(
                    icon: Icons.camera_alt_rounded,
                    label: "Snap Resit",
                    color: Colors.white,
                    textColor: AppColors.jungleGreen,
                    onTap: _handleSnapReceipt,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: GestureDetector(
                    onTap: _simulateSalesInput,       // Single Tap -> Sales
                    onLongPress: _simulateCostInput,  // Long Press -> Cost
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.lightOrange,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic_rounded, size: 50, color: Colors.black),
                          SizedBox(height: 10),
                          Text(
                            "Cakap\n(Jual / Beli)", 
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Recent Transactions List
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Urusniaga Terkini",
                        style: TextStyle(color: AppColors.jungleGreen, fontSize: 20, fontWeight: FontWeight.w800)),
                    
                    // Navigation to History Page
                    InkWell(
                      onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionHistoryPage(
                                transactions: transactions // Pass the current list
                              ),
                            ),
                          );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Text("Lihat Semua >", 
                          style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                
                // 🔥 动态生成列表 (关键修改：传入 time 和 onTap)
                ...transactions.map((tx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12), 
                    child: TransactionTile(
                      title: tx.title, 
                      amount: tx.amount, 
                      isIncome: tx.isIncome,
                      time: tx.time, // ✅ 传入时间 (必须！)
                      successColor: AppColors.successGreen,
                      warningColor: AppColors.warningRed,
                      onTap: () {
                        // ✅ 点击跳转到详情页 (必须！)
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (context) => TransactionDetailPage(transaction: tx)
                          )
                        );
                      },
                    ),
                  );
                }).toList(),

              ],
            ),
          ),
        ],
      ),
    );
  }
}