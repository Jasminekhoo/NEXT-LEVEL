// lib/screens/transaction_detail_page.dart

import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../widgets/custom_widgets.dart';

class TransactionDetailPage extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text("Butiran Transaksi", style: TextStyle(fontWeight: FontWeight.bold)), // 交易详情
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. 状态图标
            const SizedBox(height: 20),
            Icon(
              Icons.check_circle, 
              size: 80, 
              color: transaction.isIncome ? AppColors.successGreen : AppColors.warningRed
            ),
            const SizedBox(height: 10),
            Text(
              transaction.isIncome ? "Bayaran Diterima" : "Bayaran Dibuat", // 收款成功 / 付款成功
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            
            // 2. 巨大金额
            Text(
              transaction.amount,
              style: TextStyle(
                fontSize: 40, 
                fontWeight: FontWeight.w900,
                color: transaction.isIncome ? AppColors.successGreen : AppColors.warningRed,
              ),
            ),
            const SizedBox(height: 40),

            // 3. 详细信息卡片
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _buildDetailRow("Perkara", transaction.title), // 事项
                  const Divider(height: 30),
                  _buildDetailRow("Tarikh", transaction.date),   // 日期
                  const Divider(height: 30),
                  _buildDetailRow("Masa", transaction.time),     // 时间
                  const Divider(height: 30),
                  _buildDetailRow("Kategori", transaction.isIncome ? "Jualan" : "Kos Bahan"), // 分类
                  const Divider(height: 30),
                  _buildDetailRow("Status", "Selesai (Verified by AI)"), // 状态
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 4. 收据图片 (模拟如果有的话)
            if (!transaction.isIncome) ...[
               const Align(
                 alignment: Alignment.centerLeft,
                 child: Text("Lampiran Resit:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
               ),
               const SizedBox(height: 10),
               Container(
                 height: 150,
                 width: double.infinity,
                 decoration: BoxDecoration(
                   color: Colors.grey[300],
                   borderRadius: BorderRadius.circular(10),
                   border: Border.all(color: Colors.grey),
                 ),
                 child: const Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.receipt_long, color: Colors.grey, size: 40),
                       Text("Resit Disimpan", style: TextStyle(color: Colors.grey)),
                     ],
                   ),
                 ),
               )
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}