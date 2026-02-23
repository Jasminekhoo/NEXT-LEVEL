import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import '../models/price_record.dart';


class PriceServiceCsv {
  static const Map<int, Map<String, String>> itemLookup = {
    // --- Daging & Telur ---
    1: {"name": "Ayam Bersih - Standard (1kg)", "cat": "Daging & Telur"},
    2: {"name": "Ayam Bersih - Super (1kg)", "cat": "Daging & Telur"},
    9: {"name": "Daging Kambing Import (1kg)", "cat": "Daging & Telur"},
    14: {"name": "Daging Kerbau India (1kg)", "cat": "Daging & Telur"},
    118: {"name": "Telur Ayam Gred A (10biji)", "cat": "Daging & Telur"},
    119: {"name": "Telur Ayam Gred B (10biji)", "cat": "Daging & Telur"},
    120: {"name": "Telur Ayam Gred C (10biji)", "cat": "Daging & Telur"},
    43: {"name": "Ikan Bawal Hitam (1kg)", "cat": "Daging & Telur"},
    47: {"name": "Ikan Cencaru (1kg)", "cat": "Daging & Telur"},
    55: {"name": "Ikan Kembung (1kg)", "cat": "Daging & Telur"},
    // --- Sayur-sayuran ---
    92: {"name": "Cili Hijau (1kg)", "cat": "Sayur"},
    93: {"name": "Cili Merah - Kulai (1kg)", "cat": "Sayur"},
    70: {"name": "Cili Padi Hijau (1kg)", "cat": "Sayur"},
    105: {"name": "Kubis Bulat - Tempatan (1kg)", "cat": "Sayur"},
    98: {"name": "Kacang Panjang (1kg)", "cat": "Sayur"},
    96: {"name": "Kacang Bendi(1kg)", "cat": "Sayur"},
    113: {"name": "Timun (1kg)", "cat": "Sayur"},
    114: {"name": "Tomato (1kg)", "cat": "Sayur"},
    88: {"name": "Bawang Merah India (1kg)", "cat": "Sayur"},
    147: {"name": "Halia Basah - Tua (1kg)", "cat": "Sayur"},
    // --- Barangan Keperluan ---
    263: {"name": "Minyak Masak (1kg) - Buruh", "cat": "Keperluan"},
    254: {"name": "Minyak Masak (1kg) - Helang", "cat": "Keperluan"},
    1589: {"name": "Gula Pasir Kasar (1kg)", "cat": "Keperluan"},
    1590: {"name": "Gula Pasir Halus (1kg)", "cat": "Keperluan"},
    1593: {"name": "Tepung Gandum - Berbungkus (1kg)", "cat": "Keperluan"},
    1605: {"name": "Garam Halus Biasa (350g)", "cat": "Keperluan"},
    103: {"name": "Santan Kelapa Segar (1kg)", "cat": "Keperluan"},
    1582: {"name": "Beras Cap Jasmine (SST5%)(10kg)", "cat": "Keperluan"},
    // --- Buah-buahan ---
    16: {"name": "Betik Biasa (1kg)", "cat": "Buah"},
    18: {"name": "Pisang Berangan (1kg)", "cat": "Buah"},
    19: {"name": "Pisang Emas (1kg)", "cat": "Buah"},
    20: {"name": "Tembikai Merah Berbiji (1kg)", "cat": "Buah"},
    21: {"name": "Tembikai Merah Tanpa Biji (1kg)", "cat": "Buah"},
    24: {"name": "Tembikai Susu (1kg)", "cat": "Buah"},
    25: {"name": "Nenas Biasa (1 biji)", "cat": "Buah"},
    1132: {"name": "Limau Nipis (1kg)", "cat": "Buah"},
  };

  Future<List<PriceRecord>> getLatestPrices({String? cacheDirPath}) async {
  try {
    DateTime now = DateTime.now();

    String currentYM =
        "${now.year}-${now.month.toString().padLeft(2, '0')}";

    DateTime lastMonthDate =
        DateTime(now.year, now.month - 1);

    String lastYM =
        "${lastMonthDate.year}-${lastMonthDate.month.toString().padLeft(2, '0')}";

    // 下载两个 CSV
    final currentResult = await _downloadMonth(currentYM);
    final lastResult = await _downloadMonth(lastYM);

   final currentRows = const CsvToListConverter().convert(
        currentResult['content'] ?? '', 
        eol: '\n'
      );

      final lastRows = const CsvToListConverter().convert(
        lastResult['content'] ?? '', 
        eol: '\n'
      );

   // final currentRows =
       // CsvToListConverter().convert(currentResult['content']!, eol: '\n');

    //final lastRows =
        //CsvToListConverter().convert(lastResult['content']!, eol: '\n');

    // 存储数据
    Map<int, double> currentLatestPrice = {};
    Map<int, double> lastMonthLowestPrice = {};

    // ===============================
    // 1️⃣ 当月 → 最新价格
    // ===============================
    for (var row in currentRows.skip(1)) {
      if (row.length < 4) continue;

      int itemCode = int.tryParse(row[2].toString()) ?? 0;
      if (!itemLookup.containsKey(itemCode)) continue;

      double price = double.tryParse(row[3].toString()) ?? 0.0;

      // 只记录第一条（CSV 通常最新在前）
      if (!currentLatestPrice.containsKey(itemCode)) {
        currentLatestPrice[itemCode] = price;
      }
    }

    // ===============================
    // 2️⃣ 上个月 → 最低价格
    // ===============================
    for (var row in lastRows.skip(1)) {
      if (row.length < 4) continue;

      int itemCode = int.tryParse(row[2].toString()) ?? 0;
      if (!itemLookup.containsKey(itemCode)) continue;

      double price = double.tryParse(row[3].toString()) ?? 0.0;

      if (!lastMonthLowestPrice.containsKey(itemCode)) {
        lastMonthLowestPrice[itemCode] = price;
      } else {
        if (price < lastMonthLowestPrice[itemCode]!) {
          lastMonthLowestPrice[itemCode] = price;
        }
      }
    }

    // ===============================
    // 3️⃣ 生成 PriceRecord
    // ===============================
    final List<PriceRecord> results = [];

    currentLatestPrice.forEach((itemCode, currentPrice) {
      double oldPrice =
          lastMonthLowestPrice[itemCode] ?? currentPrice;

      results.add(
        PriceRecord(
          itemName: itemLookup[itemCode]!['name']!,
          oldPrice: oldPrice,          // 上个月最低
          newPrice: currentPrice,      // 当月最新
          history: [oldPrice, currentPrice],
          unit: "unit",
          date: DateTime.now().toString(),
          category: itemLookup[itemCode]!['cat']!,
        ),
      );
    });

    return results;

  } catch (e) {
    debugPrint("Error in getLatestPrices: $e");
    return [];
  }
}

  File? _getLatestLocalFile(Directory dir) {
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('prices_'))
        .toList();
    if (files.isEmpty) return null;
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files.first;
  }

  String _extractYMFromFilename(String path) {
    final regex = RegExp(r'prices_(\d{4}-\d{2})\.csv');
    final match = regex.firstMatch(path);
    return match != null ? match.group(1)! : '';
  }

  Future<Map<String, String>> _downloadMonth(String ym) async {
  String url =
      "https://storage.data.gov.my/pricecatcher/pricecatcher_$ym.csv";

  try {
    final response =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 && response.body.length > 1000) {
      return {'content': response.body, 'ym': ym};
    }
  } catch (e) {
    debugPrint("下载 $ym 失败: $e");
  }

  throw Exception("$ym CSV 数据获取失败");
}

  Future<void> _clearOldCache(Directory dir, String currentFileName) async {
    final files = dir.listSync().whereType<File>().toList();
    for (var f in files) {
      if (f.path.contains('prices_') && !f.path.contains(currentFileName)) {
        await f.delete();
      }
    }
  }

  List<PriceRecord> _processRows(List<List<dynamic>> rows, String dataMonth) {
    if (rows.isEmpty) return [];

    int dateIdx = 0, itemCodeIdx = 2, priceIdx = 3;
    final Map<int, List<Map<String, dynamic>>> grouped = {};
    final dataRows = rows.skip(1);

    for (var row in dataRows) {
      if (row.length < 4) continue;
      int itemCode = int.tryParse(row[itemCodeIdx].toString()) ?? 0;
      if (!itemLookup.containsKey(itemCode)) continue;

      double price = double.tryParse(row[priceIdx].toString()) ?? 0.0;
      String date = row[dateIdx].toString();

      grouped.putIfAbsent(itemCode, () => []);
      grouped[itemCode]!.add({'price': price, 'date': date});
    }

    final List<PriceRecord> results = [];

    grouped.forEach((itemCode, list) {
      // 日期降序取最新一条
      list.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
      final latest = list.first;
      double latestPrice = (latest['price'] as num).toDouble();

      results.add(PriceRecord(
        itemName: itemLookup[itemCode]!['name']!,
        oldPrice: latestPrice,
        newPrice: latestPrice,
        history: [latestPrice],
        unit: "unit",
        date: latest['date'].toString(),
        category: itemLookup[itemCode]!['cat']!,
      ));
    });

    return results;
  }

  // 格式化月份为马来文（可选保留）
  String formatMonthMalay(String ym) {
    try {
      final parts = ym.split('-');
      final month = int.parse(parts[1]);
      final year = parts[0];
      const monthNames = [
        '', 'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
        'Jul', 'Ogos', 'Sep', 'Okt', 'Nov', 'Dis'
      ];
      return "${monthNames[month]} $year";
    } catch (_) {
      return ym;
    }
  }
}