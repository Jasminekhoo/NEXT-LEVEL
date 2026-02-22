import 'package:flutter/material.dart';
import '../models/extracted_item.dart';
import '../app_colors.dart';

class ReceiptReviewPage extends StatefulWidget {
  final List<ExtractedItem> extractedItems;

  const ReceiptReviewPage({
    super.key,
    required this.extractedItems,
  });

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
  // 🟢 Confirm & Save Data
  // ==========================================
  void _confirmData() {
  // 回传数据给上一个页面
  Navigator.pop(context, _items); // 传回 List<ExtractedItem>
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Resit berjaya disahkan ✅"),
      duration: Duration(seconds: 2),
    ),
  );
  }

  // ==========================================
  // ➕ Tambah Item
  // ==========================================
  void _addNewItem() {
    setState(() {
      _items.add(ExtractedItem(name: "", price: "RM 0.00", date: DateTime.now()));
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
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      elevation: 1,                  // 阴影轻一点，看起来更干净
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
                  final nameController =
                      TextEditingController(text: item.name);
                  final priceController =
                      TextEditingController(text: item.price);

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
                              _items[index] =
                                  _items[index].copyWith(name: val);
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white, // 白色背景
                              border: const OutlineInputBorder(),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
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
                              _items[index] =
                                  _items[index].copyWith(price: val);
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white, // 白色背景
                              border: const OutlineInputBorder(),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
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
                      color: AppColors.jungleGreen, fontWeight: FontWeight.bold),
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