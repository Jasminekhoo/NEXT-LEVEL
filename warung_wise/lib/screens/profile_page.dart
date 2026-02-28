// lib/screens/profile_page.dart

import 'package:flutter/material.dart';
import '../app_colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text("Profil Warung", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // warung profile (avatar, name, category)
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage('https://tse3.mm.bing.net/th/id/OIP.kp5huS9dTrQdcZH_FcqMTQHaHa?rs=1&pid=ImgDetMain&o=7&rm=3'),
                  ),
                  const SizedBox(height: 15),
                  const Text("Warung Mak Cik Kiah", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.jungleGreen)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text("Kategori: Makanan & Minuman", style: TextStyle(color: AppColors.lightOrange, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // set init daily target (untung bersih harian)
            const Text("Sasaran Harian (Daily Target)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.track_changes, color: AppColors.jungleGreen),
                      SizedBox(width: 10),
                      Text("Untung Bersih", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Row(
                    children: [
                      const Text("RM 200.00", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.jungleGreen)),
                      const SizedBox(width: 10),
                      Icon(Icons.edit, size: 18, color: Colors.grey[400]),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 25),

            // set init menu & harga 
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Senarai Menu & Harga", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                TextButton.icon(
                  onPressed: () {}, 
                  icon: const Icon(Icons.add, size: 18, color: AppColors.lightOrange), 
                  label: const Text("Tambah", style: TextStyle(color: AppColors.lightOrange))
                )
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
              ),
              child: Column(
                children: [
                  _buildMenuItem("Nasi Lemak Biasa", "RM 6.00"),
                  const Divider(height: 1),
                  _buildMenuItem("Nasi Lemak Ayam", "RM 7.00"),
                  const Divider(height: 1),
                  _buildMenuItem("Teh O Ais", "RM 1.00"),
                  const Divider(height: 1),
                  _buildMenuItem("Kuih Muih (1 Keping)", "RM 1.00"),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // set init kos tetap (sewa tapak, bil air, dll)
            const Text("Kos Tetap (Fixed Costs)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
              ),
              child: Column(
                children: [
                  _buildMenuItem("Sewa Tapak (Harian)", "RM 30.00"),
                  const Divider(height: 1),
                  _buildMenuItem("Bil Air & Elektrik (Bulan)", "RM 80.00"),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // logout button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.warningRed),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                onPressed: () {},
                child: const Text("Log Keluar", style: TextStyle(color: AppColors.warningRed, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String name, String price) {
    return ListTile(
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.jungleGreen)),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        ],
      ),
      onTap: () {}, 
    );
  }
}