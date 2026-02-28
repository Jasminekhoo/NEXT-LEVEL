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

  // Confirm and Save Data to Firebase (Supports Historical Tracking)
  Future<void> _confirmData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final firestore = fs.FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (var item in _items) {
        // Extract price value (remove "RM" and other non-numeric characters)
        double priceNum =
            double.tryParse(item.price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0.0;

        String ingredientId = item.name.trim().toLowerCase();

        // Update 'ingredient_prices' (current unit price snapshot)
        // The purpose is to allow RecipePage to directly retrieve the latest unit price
        var currentPriceRef = firestore
            .collection('ingredient_prices')
            .doc(ingredientId);
        batch.set(currentPriceRef, {
          'name': item.name.trim(),
          'pricePerKg': priceNum,
          'lastUpdated': fs.FieldValue.serverTimestamp(),
        }, fs.SetOptions(merge: true));

        // Append to 'price_history' (price change log)
        // The purpose is to ensure traceability by recording every price change
        var historyRef = firestore
            .collection('price_history')
            .doc(); 
        batch.set(historyRef, {
          'ingredientId': ingredientId, 
          'name': item.name.trim(),
          'price': priceNum,
          'timestamp': fs.FieldValue.serverTimestamp(),
          'source': 'AI_Scan',
        });

        // Record in 'transactions' (financial transaction log)
        var transactionRef = firestore.collection('transactions').doc();
        batch.set(transactionRef, {
          'title': "Beli ${item.name}",
          'amount': "- RM ${priceNum.toStringAsFixed(2)}",
          'isIncome': false,
          'timestamp': fs.FieldValue.serverTimestamp(),
        });
      }

      
      await batch.commit();

      if (!mounted) return;
      Navigator.pop(context); 

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Data berjaya disinkronkan ke Firebase! ✅"),
        ),
      );

      Navigator.pop(context, _items);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); 
      debugPrint("Firebase Error: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal menyimpan data: $e ❌")));
    }
  }

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
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: nameController,
                            onChanged: (val) {
                              _items[index] = _items[index].copyWith(name: val);
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white, 
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
                              fillColor: Colors.white,
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
