import 'package:flutter/material.dart';

// ============================================
// 1. Transaction Model
// ============================================
class Transaction {
  final String title;
  final String amount;
  final bool isIncome;
  final String date; 
  final String time;

  Transaction({
    required this.title, 
    required this.amount, 
    required this.isIncome,
    this.date = "Hari Ini", 
    this.time = "12:00 PM",
  });
}

// ============================================
// 2. BigCardButton (保持现状)
// ============================================
class BigCardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const BigCardButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: textColor),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// 3. TransactionTile (🔥 自动换行版 - 绝不截断)
// ============================================
class TransactionTile extends StatelessWidget {
  final String title;
  final String amount;
  final bool isIncome;
  final String time; 
  final VoidCallback? onTap; 
  final Color successColor;
  final Color warningColor;

  const TransactionTile({
    super.key,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.time, 
    this.onTap,
    required this.successColor,
    required this.warningColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap, 
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            // 🔥 关键改动：改为 Start 对齐。
            // 这样如果标题变两行，图标和金额会保持在第一行的高度，不会跑位。
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              // 1. 图标
              Padding(
                padding: const EdgeInsets.only(top: 2), // 微调图标位置，对齐文字第一行
                child: Icon(
                  isIncome ? Icons.trending_up : Icons.trending_down,
                  color: isIncome ? successColor : warningColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              
              // 2. 标题与时间区
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2, // 适当的行高
                      ),
                      // 🔥 删掉了 maxLines 和 overflow，让它自由换行
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time, 
                      style: TextStyle(
                        fontSize: 12, 
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. 金额部分
              const SizedBox(width: 12), 
              Padding(
                padding: const EdgeInsets.only(top: 2), // 对齐文字第一行
                child: Text(
                  amount,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isIncome ? successColor : warningColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}