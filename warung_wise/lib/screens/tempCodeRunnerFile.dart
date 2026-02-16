import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../widgets/custom_widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. 顶部 Header
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
            decoration: const BoxDecoration(
              color: AppColors.jungleGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 头像
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=29'), 
                      ),
                    ),
                    // 铃铛
                    Stack(
                      children: [
                        const Icon(Icons.notifications, color: Colors.white, size: 32),
                        Positioned(
                          right: 0, top: 0,
                          child: Container(
                            width: 12, height: 12,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                        )
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 25),
                const Text("Untung Bersih Hari Ini",
                    style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text("RM 145.50",
                    style: TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900)),
              ],
            ),
          ),

          // 2. 巨大按钮区
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: BigCardButton(
                    icon: Icons.camera_alt,
                    label: "Snap Resit",
                    color: Colors.white,
                    textColor: AppColors.jungleGreen,
                    onTap: () {
                      // 这里可以通过 Parent Widget 切换 Tab，或者跳转
                      print("Navigating to Scan...");
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: BigCardButton(
                    icon: Icons.mic,
                    label: "Cakap Jual",
                    color: AppColors.lightOrange,
                    textColor: Colors.black,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),

          // 3. 最近交易列表
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Urusniaga Terkini",
                    style: TextStyle(color: AppColors.jungleGreen, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                const TransactionTile(
                  title: "Beli Telur", 
                  amount: "- RM 18.00", 
                  isIncome: false,
                  successColor: AppColors.successGreen,
                  warningColor: AppColors.warningRed,
                ),
                const SizedBox(height: 10),
                const TransactionTile(
                  title: "Jual Nasi Lemak", 
                  amount: "+ RM 150.00", 
                  isIncome: true,
                  successColor: AppColors.successGreen,
                  warningColor: AppColors.warningRed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}