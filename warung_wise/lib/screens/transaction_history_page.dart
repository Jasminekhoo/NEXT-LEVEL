// lib/screens/transaction_history_page.dart

import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../widgets/custom_widgets.dart';
import 'transaction_detail_page.dart';

class TransactionHistoryPage extends StatefulWidget {
  final List<Transaction> transactions;

  const TransactionHistoryPage({super.key, required this.transactions});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  // 1. 设定“历史底数” (模拟昨天以前的账)
  // 这样看起来 App 已经用了很久，而不是只有今天的数据
  double totalSales = 2200.00; 
  double totalCost = 800.00;

  @override
  void initState() {
    super.initState();
    _calculateTotals();
  }

  // 🔥 核心逻辑：把传进来的“今天”的数据，加到底数上
  void _calculateTotals() {
    for (var tx in widget.transactions) {
      // 1. 把字符串 "RM 150.00" 变成数字 150.00
      // 正则表达式：只保留数字和小数点
      String cleanAmount = tx.amount.replaceAll(RegExp(r'[^0-9.]'), '');
      double value = double.tryParse(cleanAmount) ?? 0.0;

      // 2. 分类累加
      if (tx.isIncome) {
        totalSales += value;
      } else {
        totalCost += value;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text("Sejarah Transaksi", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.jungleGreen,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                 BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
              ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Jumlah Jualan", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 5),
                    Text(
                      "+ RM ${totalSales.toStringAsFixed(2)}", 
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
                Container(height: 40, width: 1, color: Colors.white24), 
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Jumlah Kos", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 5),
                    Text(
                      "- RM ${totalCost.toStringAsFixed(2)}", 
                      style: const TextStyle(color: AppColors.lightOrange, fontSize: 20, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          const Text("Hari Ini", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 10),

          ...widget.transactions.map((tx) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TransactionTile(
              title: tx.title,
              amount: tx.amount,
              isIncome: tx.isIncome,
              time: tx.time,
              successColor: AppColors.successGreen,
              warningColor: AppColors.warningRed,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionDetailPage(transaction: tx)));
              },
            ),
          )),

          const SizedBox(height: 20),
          const Text("Semalam (Yesterday)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 10),

          TransactionTile(
            title: "Jual Nasi Lemak (80 pax)", 
            amount: "+ RM 240.00", 
            isIncome: true, 
            time: "07:30 PM", 
            successColor: AppColors.successGreen, 
            warningColor: AppColors.warningRed,
            onTap: () => _goToDetail(context, "Jual Nasi Lemak", "+ RM 240.00", true, "Semalam", "07:30 PM"),
          ),
          const SizedBox(height: 10),
          
          TransactionTile(
            title: "Beli Ayam & Santan", 
            amount: "- RM 120.00", 
            isIncome: false, 
            time: "06:00 AM", 
            successColor: AppColors.successGreen, 
            warningColor: AppColors.warningRed,
            onTap: () => _goToDetail(context, "Beli Ayam", "- RM 120.00", false, "Semalam", "06:00 AM"),
          ),
          
          const SizedBox(height: 20),
          const Text("Isnin, 12 Feb", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 10),
          
          TransactionTile(
            title: "Stok Mingguan (Beras)", 
            amount: "- RM 200.00", 
            isIncome: false, 
            time: "02:30 PM", 
            successColor: AppColors.successGreen, 
            warningColor: AppColors.warningRed,
            onTap: () => _goToDetail(context, "Stok Beras", "- RM 200.00", false, "12 Feb", "02:30 PM"),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _goToDetail(BuildContext context, String title, String amount, bool isIncome, String date, String time) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionDetailPage(
      transaction: Transaction(title: title, amount: amount, isIncome: isIncome, date: date, time: time)
    )));
  }
}