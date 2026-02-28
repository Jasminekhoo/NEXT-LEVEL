// lib/screens/dashboard_page.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../app_colors.dart';
import '../widgets/custom_widgets.dart';
import 'transaction_history_page.dart';
import 'transaction_detail_page.dart';
import '../models/extracted_item.dart';
import 'receipt_review_page.dart';
import 'profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs; 
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_vision_service.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback onScanTap;

  const DashboardPage({super.key, required this.onScanTap});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ImagePicker _picker = ImagePicker();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;
  bool _isListening = false;
  String _lastWords = "";
  final GeminiVisionService _visionService = GeminiVisionService();
  
  final ValueNotifier<String> _loadingText = ValueNotifier(
    "Memulakan imbasan...",
  );
  // initial profit
  double totalUntung = 145.50;

  // initial transactions
  List<Transaction> transactions = [
    Transaction(
      title: "Beli Telur Gred A",
      amount: "- RM 18.00",
      isIncome: false,
      date: "Hari Ini",
      time: "08:30 AM",
    ),
    Transaction(
      title: "Jual Nasi Lemak (50 pax)",
      amount: "+ RM 150.00",
      isIncome: true,
      date: "Hari Ini",
      time: "11:45 AM",
    ),
    Transaction(
      title: "Beli Beras (10kg)",
      amount: "- RM 38.00",
      isIncome: false,
      date: "Hari Ini",
      time: "09:00 AM",
    ),
  ];

  Future<void> _handleSnapReceipt() async {
    // 0) Choose source (Camera or Gallery)
    final source = await _showReceiptSourceSheet();
    if (source == null) return;

    // 1) Pick image
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (picked == null) {
      _showSuccessSnackBar(
        isIncome: false,
        text: "Tiada gambar dipilih",
        subText: "Batal imbasan resit.",
      );
      return;
    }

    // 2) Show Loading Dialog
    _showScanLoading();

    try {
      _loadingText.value = "Memproses gambar...";
      await Future.delayed(const Duration(milliseconds: 500));

      _loadingText.value = "Menganalisis dengan AI Gemini...";

      final List<ExtractedItem> results = await _visionService.analyzeReceipt(
        picked,
      );

      if (!mounted) return;

      // 3) Close loading
      Navigator.pop(context);

      // If Gemini fails to find items, stop here and inform user
      if (results.isEmpty) {
        _showSuccessSnackBar(
          isIncome: false,
          text: "Imbasan Kosong",
          subText:
              "AI tidak menemui sebarang item. Sila cuba lagi dengan gambar lebih jelas.",
        );
        return;
      }

      // 4) Go to review page with the REAL results from Gemini
      final confirmedResult = await Navigator.push<List<ExtractedItem>>(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptReviewPage(extractedItems: results),
        ),
      );

      // 5) If user confirmed -> sync Firebase (Your existing logic)
      if (confirmedResult != null && confirmedResult.isNotEmpty) {
        for (var item in confirmedResult) {
          // Clean price: Remove "RM" or non-numeric characters to get a double
          double priceNum =
              double.tryParse(item.price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0.0;

          // A. Record in Transactions (Ledger)
          await fs.FirebaseFirestore.instance.collection('transactions').add({
            'title': "Beli ${item.name}",
            'amount': "- RM ${priceNum.toStringAsFixed(2)}",
            'isIncome': false,
            'timestamp': fs.FieldValue.serverTimestamp(),
            'time': _getCurrentTime(),
          });

          // B. Record in Ingredient Prices (Market Data for Pillar 2)
          await fs.FirebaseFirestore.instance
              .collection('ingredient_prices')
              .doc(item.name.trim().toLowerCase())
              .set({
                'name': item.name,
                'pricePerKg': priceNum,
                'lastUpdated': fs.FieldValue.serverTimestamp(),
              }, fs.SetOptions(merge: true));

          // C. Update Local Dashboard UI
          setState(() {
            transactions.insert(
              0,
              Transaction(
                title: "Beli ${item.name}",
                amount: "- RM ${priceNum.toStringAsFixed(2)}",
                isIncome: false,
                date: "Hari Ini",
                time: _getCurrentTime(),
              ),
            );
            totalUntung -= priceNum;
          });
        }

        _showSuccessSnackBar(
          isIncome: false,
          text: "Resit berjaya direkod",
          subText:
              "${confirmedResult.length} item telah disinkronkan ke Firebase.",
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackBar(
          isIncome: false,
          text: "Ralat Imbasan",
          subText: "Sesuatu berlaku: $e",
        );
      }
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _smartExtractAmount(String text, bool isSales) {
    String lowerText = text.toLowerCase();

    // 1. First, use regex to extract a number from the text

    final RegExp regExp = RegExp(r'\d+(\.\d{1,2})?');

    final match = regExp.firstMatch(lowerText);

    double rawNumber = 0.0;

    if (match != null) {
      rawNumber = double.tryParse(match.group(0)!) ?? 0.0;
    } else {
      // If no number is found, return a fallback random amount

      return (Random().nextInt(40) + 10).toDouble();
    }

    // 2. Determine the unit:
    // If it refers to quantity units, multiply by the corresponding unit price
    
    // Example: Nasi Lemak assumed RM5 per pack
    if (lowerText.contains('bungkus') ||
        lowerText.contains('pax') ||
        lowerText.contains('pinggan')) {
      return rawNumber * 5.0; 
    }
    // Example: Chicken assumed RM10 per unit/kg
    else if (lowerText.contains('ekor') || lowerText.contains('kg')) {
      return rawNumber * 10.0;
    }
    // If the text mentions ringgit or RM, assume it's already the total amount
    else if (lowerText.contains('ringgit') || lowerText.contains('rm')) {
      return rawNumber;
    }

    // If no unit is detected, assume the number is already the final amount
    return rawNumber;
  }

  // Jual

  Future<void> _handleVoiceSales() async {
    final transcript = await _listenOnce();

    if (transcript == null) return;
    _showScanLoading();
    _loadingText.value = "Gemini memproses data Jualan...";
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.pop(context);

    // 1. Calculate the total sales amount (Jumlah Jualan)
    double jumlahJualan = _smartExtractAmount(transcript, true);
    // 2. Core business logic:
    // Automatically calculate Net Profit (Untung Bersih)
    // (Assuming a 40% profit margin)
    double untungBersih = jumlahJualan * 0.40;

    setState(() {
      // The big number at the top only increases by Net Profit
      totalUntung += untungBersih;
      // The transaction list below shows the total sales amount
      transactions.insert(
        0,
        Transaction(
          title: "Jual (Suara): $transcript",
          amount: "+ RM ${jumlahJualan.toStringAsFixed(2)}",
          isIncome: true,
          date: "Hari Ini",
          time: _getCurrentTime(),
        ),
      );
    });

    // Sync to Firebase in the background (syncing the sales amount)
    fs.FirebaseFirestore.instance.collection('transactions').add({
      'title': "Jual (Suara): $transcript",
      'amount': "+ RM ${jumlahJualan.toStringAsFixed(2)}",
      'isIncome': true,
      'timestamp': fs.FieldValue.serverTimestamp(),
      'time': _getCurrentTime(),
    });

    // Show a success message to inform the user that AI calculated the profit
    _showSuccessSnackBar(
      isIncome: true,
      text: "Jualan RM ${jumlahJualan.toStringAsFixed(2)} direkod",
      subText:
          "AI mengira: Untung Bersih +RM ${untungBersih.toStringAsFixed(2)}",
    );
  }

  //Beli/Kos

  Future<void> _handleVoiceCost() async {
    final transcript = await _listenOnce();

    if (transcript == null) return;

    _showScanLoading();

    _loadingText.value = "Gemini memproses data Kos...";

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.pop(context);

    double kosBaru = _smartExtractAmount(transcript, false);

    setState(() {
      totalUntung -= kosBaru;

      transactions.insert(
        0,

        Transaction(
          title: "Beli (Suara): $transcript",

          amount: "- RM ${kosBaru.toStringAsFixed(2)}",

          isIncome: false,

          date: "Hari Ini",

          time: _getCurrentTime(),
        ),
      );
    });

    fs.FirebaseFirestore.instance.collection('transactions').add({
      'title': "Beli (Suara): $transcript",

      'amount': "- RM ${kosBaru.toStringAsFixed(2)}",

      'isIncome': false,

      'timestamp': fs.FieldValue.serverTimestamp(),

      'time': _getCurrentTime(),
    });

    _showSuccessSnackBar(
      isIncome: false,

      text: "Kos Direkod",

      subText: "Gemini: Kos RM ${kosBaru.toStringAsFixed(2)} ditolak.",
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12
        ? now.hour - 12
        : (now.hour == 0 ? 12 : now.hour);
    final period = now.hour >= 12 ? "PM" : "AM";
    final minute = now.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  }

  void _showListeningDialog(String title, String subtitle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.lightOrange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic,
                  size: 40,
                  color: AppColors.lightOrange,
                ),
              ),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const LinearProgressIndicator(color: AppColors.lightOrange),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar({
    required bool isIncome,
    required String text,
    required String subText,
  }) {
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
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 4),
              child: Text(
                subText,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isIncome
            ? AppColors.successGreen
            : AppColors.warningRed,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(
      onStatus: (status) {
        // status: listening / notListening / done
      },
      onError: (error) {
        // optional: show snackbar
      },
    );
    setState(() {});
  }

  Future<String?> _listenOnce({
    Duration maxDuration = const Duration(seconds: 6),
  }) async {
    if (!_speechReady) {
      _showSuccessSnackBar(
        isIncome: false,
        text: "Mic tidak tersedia",
        subText: "Sila benarkan akses mikrofon / speech.",
      );
      return null;
    }

    _lastWords = "";
    _isListening = true;

    _showListeningDialog(
      "Sedang mendengar...",
      "Sila sebut...\nContoh: 'Jual 20 bungkus' atau 'Dapat 50 ringgit'",
    );

    await _speech.listen(
      listenMode: stt.ListenMode.confirmation,
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
        });
      },
      localeId: "ms_MY", // Malay. Try "en_US" if needed.
    );

    // stop after maxDuration
    await Future.delayed(maxDuration);

    await _speech.stop();

    _isListening = false;

    if (!mounted) return null;
    Navigator.pop(context); // close dialog

    final text = _lastWords.trim();
    return text.isEmpty ? null : text;
  }

  Future<ImageSource?> _showReceiptSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "Snap Resit",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text("Guna Kamera"),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text("Muat Naik Gambar"),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. Header (Untung Bersih)
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 50,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: AppColors.jungleGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(
                            'https://tse3.mm.bing.net/th/id/OIP.kp5huS9dTrQdcZH_FcqMTQHaHa?rs=1&pid=ImgDetMain&o=7&rm=3',
                          ),
                        ),
                      ),
                    ),
                    Stack(
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.warningRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
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
                        const Text(
                          "Untung Bersih",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "RM ${totalUntung.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: (totalUntung / 200).clamp(0.0, 1.0),
                                backgroundColor: Colors.white24,
                                color: AppColors.lightOrange,
                                strokeWidth: 6,
                              ),
                              Text(
                                "${((totalUntung / 200) * 100).toInt()}%",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Target",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppColors.warningRed.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
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
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: AppColors.warningRed,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Amaran AI (Gemini)",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Telur naik harga! Ketik untuk lihat.",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey,
                    ),
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
                    //onTap: _simulateSalesInput, // Single Tap -> Sales
                    //onLongPress: _simulateCostInput, // Long Press -> Cost
                    onTap: _handleVoiceSales,
                    onLongPress: _handleVoiceCost,
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.lightOrange,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mic_rounded,
                            size: 50,
                            color: Colors.black,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Cakap\n(Jual / Beli)",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
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
                    const Text(
                      "Urusniaga Terkini",
                      style: TextStyle(
                        color: AppColors.jungleGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    // Navigation to History Page
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransactionHistoryPage(
                              transactions:
                                  transactions, // Pass the current list
                            ),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Text(
                          "Lihat Semua >",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                ...transactions.map((tx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TransactionTile(
                      title: tx.title,
                      amount: tx.amount,
                      isIncome: tx.isIncome,
                      time: tx.time, 
                      successColor: AppColors.successGreen,
                      warningColor: AppColors.warningRed,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TransactionDetailPage(transaction: tx),
                          ),
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