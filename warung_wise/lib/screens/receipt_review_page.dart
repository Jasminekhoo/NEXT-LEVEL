import 'package:flutter/material.dart';
import '../models/extracted_item.dart';
import '../app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;

class ReceiptReviewPage extends StatefulWidget {
  final List<ExtractedItem> extractedItems;

  const ReceiptReviewPage({super.key, required this.extractedItems});

  @override
  State<ReceiptReviewPage> createState() => _ReceiptReviewPageState();
}

class _ReceiptReviewPageState extends State<ReceiptReviewPage> {
  late List<ExtractedItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.extractedItems);
  }

  // ==========================================
  // 🟢 核心修改：确认并保存数据到 Firebase (支持历史追踪)
  // ==========================================
  Future<void> _confirmData() async {
    // 1. 显示加载圈，防止用户重复点击
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final firestore = fs.FirebaseFirestore.instance;
      // 使用 WriteBatch 提高效率，确保所有数据要么全部成功，要么全部失败
      final batch = firestore.batch();

      for (var item in _items) {
        // A. 提取价格数字 (去掉 "RM" 等非数字字符)
        double priceNum =
            double.tryParse(item.price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0.0;

        String ingredientId = item.name.trim().toLowerCase();

        // B. 🚀 更新 'ingredient_prices' (当前单价快照)
        // 这里的目的是为了让 RecipePage 能直接拿到最新单价
        var currentPriceRef = firestore
            .collection('ingredient_prices')
            .doc(ingredientId);
        batch.set(currentPriceRef, {
          'name': item.name.trim(),
          'pricePerKg': priceNum,
          'lastUpdated': fs.FieldValue.serverTimestamp(),
        }, fs.SetOptions(merge: true));

        // C. 🚀 追加到 'price_history' (价格历史流水)
        // 这里的目的是为了可追踪性 (Traceable)，记录每一次价格变动
        var historyRef = firestore
            .collection('price_history')
            .doc(); // 自动生成随机 ID
        batch.set(historyRef, {
          'ingredientId': ingredientId, // 关联 ID
          'name': item.name.trim(),
          'price': priceNum,
          'timestamp': fs.FieldValue.serverTimestamp(),
          'source': 'AI_Scan', // 标记来源
        });

        // D. 🚀 记录到 'transactions' (财务账目流水)
        var transactionRef = firestore.collection('transactions').doc();
        batch.set(transactionRef, {
          'title': "Beli ${item.name}",
          'amount': "- RM ${priceNum.toStringAsFixed(2)}",
          'isIncome': false,
          'timestamp': fs.FieldValue.serverTimestamp(),
        });
      }

      // 提交所有写入操作
      await batch.commit();

      if (!mounted) return;
      Navigator.pop(context); // 关闭加载圈

      // 成功后提示用户
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Data berjaya disinkronkan ke Firebase! ✅"),
        ),
      );

      // 带着数据返回 Dashboard 更新 UI
      Navigator.pop(context, _items);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // 关闭加载圈
      debugPrint("Firebase Error: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal menyimpan data: $e ❌")));
    }
  }

  // ==========================================
  // ➕ Tambah Item
  // ==========================================
  void _addNewItem() {
    setState(() {
      _items.add(
        ExtractedItem(name: "", price: "RM 0.00", date: DateTime.now()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.jungleGreen,
        title: const Text(
          "Semak Resit",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1, // 阴影轻一点，看起来更干净
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ==========================================
            // 🧾 Extracted Items List
            // ==========================================
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final nameController = TextEditingController(text: item.name);
                  final priceController = TextEditingController(
                    text: item.price,
                  );

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        // Name TextField with white background
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: nameController,
                            onChanged: (val) {
                              _items[index] = _items[index].copyWith(name: val);
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white, // 白色背景
                              border: const OutlineInputBorder(),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Price TextField with white background
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: priceController,
                            onChanged: (val) {
                              _items[index] = _items[index].copyWith(
                                price: val,
                              );
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white, // 白色背景
                              border: const OutlineInputBorder(),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Delete Button
                        InkWell(
                          onTap: () {
                            setState(() {
                              _items.removeAt(index);
                            });
                          },
                          child: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // ==========================================
            // ➕ Tambah Item 按钮
            // ==========================================
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _addNewItem,
                icon: const Icon(Icons.add, color: AppColors.jungleGreen),
                label: const Text(
                  "Tambah Item",
                  style: TextStyle(
                    color: AppColors.jungleGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // 🟢 Confirm Button
            // ==========================================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _confirmData,
                child: const Text(
                  "Sahkan Data",
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
