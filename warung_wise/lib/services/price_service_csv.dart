import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import '../models/price_record.dart';

class PriceServiceCsv {
  static const Map<int, Map<String, String>> itemLookup = {
    // --- Daging & Telur ---
    1: {"name": "Ayam Bersih (Standard)", "cat": "Daging & Telur"},
    2: {"name": "Ayam Bersih (Super)", "cat": "Daging & Telur"},
    9: {"name": "Daging Kambing Import", "cat": "Daging & Telur"},
    14: {"name": "Daging Kerbau India", "cat": "Daging & Telur"},
    118: {"name": "Telur Ayam Gred A", "cat": "Daging & Telur"},
    119: {"name": "Telur Ayam Gred B", "cat": "Daging & Telur"},
    120: {"name": "Telur Ayam Gred C", "cat": "Daging & Telur"},
    43: {"name": "Ikan Bawal Hitam", "cat": "Daging & Telur"},
    47: {"name": "Ikan Cencaru", "cat": "Daging & Telur"},
    55: {"name": "Ikan Kembung", "cat": "Daging & Telur"},
    // --- Sayur-sayuran ---
    92: {"name": "Cili Hijau", "cat": "Sayur"},
    93: {"name": "Cili Merah (Kulai)", "cat": "Sayur"},
    70: {"name": "Cili Padi Hijau", "cat": "Sayur"},
    105: {"name": "Kubis Bulat (Tempatan)", "cat": "Sayur"},
    98: {"name": "Kacang Panjang", "cat": "Sayur"},
    96: {"name": "Kacang Bendi", "cat": "Sayur"},
    113: {"name": "Timun", "cat": "Sayur"},
    114: {"name": "Tomato", "cat": "Sayur"},
    88: {"name": "Bawang Merah India", "cat": "Sayur"},
    147: {"name": "Halia Basah (Tua)", "cat": "Sayur"},
    // --- Barangan Keperluan ---
    263: {"name": "Minyak Masak (5kg) - Buruh", "cat": "Keperluan"},
    254: {"name": "Minyak Masak (5kg) - Helang", "cat": "Keperluan"},
    1589: {"name": "Gula Pasir Kasar", "cat": "Keperluan"},
    1590: {"name": "Gula Pasir Halus", "cat": "Keperluan"},
    1593: {"name": "Tepung Gandum (Berbungkus)", "cat": "Keperluan"},
    1605: {"name": "Garam Halus Biasa", "cat": "Keperluan"},
    103: {"name": "Santan Kelapa Segar", "cat": "Keperluan"},
    1582: {"name": "Beras Super (SST5%)", "cat": "Keperluan"},
    // --- Buah-buahan ---
    16: {"name": "Betik Biasa", "cat": "Buah"},
    18: {"name": "Pisang Berangan", "cat": "Buah"},
    19: {"name": "Pisang Emas", "cat": "Buah"},
    20: {"name": "Tembikai Merah Berbiji", "cat": "Buah"},
    21: {"name": "Tembikai Merah Tanpa Biji", "cat": "Buah"},
    24: {"name": "Tembikai Susu", "cat": "Buah"},
    25: {"name": "Nenas Biasa", "cat": "Buah"},
    1132: {"name": "Limau Nipis", "cat": "Buah"},
  };

  Future<List<PriceRecord>> getLatestPrices({String? cacheDirPath}) async {
    try {
      final directory = cacheDirPath != null ? Directory(cacheDirPath) : Directory.systemTemp;
      if (!directory.existsSync()) directory.createSync(recursive: true);

      final now = DateTime.now();
      String currentYM = "${now.year}-${now.month.toString().padLeft(2, '0')}";

      // 1️⃣ 检查本地缓存
      File? latestCacheFile = _getLatestLocalFile(directory);
      String dataMonth = currentYM; // 默认月份
      String csvContent;

      if (latestCacheFile != null && latestCacheFile.path.contains(currentYM)) {
        csvContent = await latestCacheFile.readAsString();
        dataMonth = _extractYMFromFilename(latestCacheFile.path);
      } else {
        // 2️⃣ 下载最近三个月 CSV
        final downloadResult = await _downloadWithFallback();
        csvContent = downloadResult['content']!;
        dataMonth = downloadResult['ym']!;
        final newFile = File('${directory.path}/prices_$dataMonth.csv');
        await newFile.writeAsString(csvContent);
        await _clearOldCache(directory, 'prices_$dataMonth.csv');
      }

      return _processRows(
          const CsvToListConverter().convert(csvContent, eol: '\n'),
          dataMonth
      );
    } catch (e) {
      debugPrint("Error in getLatestPrices: $e");
      return [];
    }
  }

  // 找到最新本地缓存
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

  // 从文件名提取年月
  String _extractYMFromFilename(String path) {
    final regex = RegExp(r'prices_(\d{4}-\d{2})\.csv');
    final match = regex.firstMatch(path);
    return match != null ? match.group(1)! : '';
  }

  // 下载最近三个月 CSV
  Future<Map<String, String>> _downloadWithFallback() async {
    final now = DateTime.now();
    for (int i = 0; i < 3; i++) {
      final targetDate = DateTime(now.year, now.month - i);
      String yearMonth = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}";
      String url = "https://storage.data.gov.my/pricecatcher/pricecatcher_$yearMonth.csv";
      try {
        debugPrint("Trying to download data for $yearMonth...");
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200 && response.body.length > 1000) {
          debugPrint("Success! Found data for $yearMonth");
          return {'content': response.body, 'ym': yearMonth};
        }
      } catch (e) {
        debugPrint("Failed to fetch $yearMonth: $e");
      }
    }
    throw Exception("No data found in the last 3 months.");
  }

  // 清理旧缓存
  Future<void> _clearOldCache(Directory dir, String currentFileName) async {
    final files = dir.listSync().whereType<File>().toList();
    for (var f in files) {
      if (f.path.contains('prices_') && !f.path.contains(currentFileName)) {
        await f.delete();
      }
    }
  }

  // CSV -> PriceRecord，传入 dataMonth
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
      list.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
      final historyPrices = list.map((e) => (e['price'] as num).toDouble()).take(5).toList();

      double newPrice = historyPrices.first;
      double oldPrice = historyPrices.length > 1 ? historyPrices[1] : historyPrices.first;

      String itemName = itemLookup[itemCode]!['name'] ?? 'Unknown';
      String category = itemLookup[itemCode]!['cat'] ?? 'Lain-lain';

      results.add(PriceRecord(
        itemName: itemName,
        oldPrice: oldPrice,
        newPrice: newPrice,
        history: historyPrices,
        unit: "unit",
        date: list.first['date'].toString(),
        category: category,
      ));
    });

    // 补齐 CSV 没有的商品
    itemLookup.forEach((itemCode, info) {
      if (!results.any((r) => r.itemName == info['name'])) {
        results.add(PriceRecord(
          itemName: info['name']!,
          oldPrice: 0.0,
          newPrice: 0.0,
          history: [0.0],
          unit: "unit",
          date: "",
          category: info['cat']!,
        ));
      }
    });

    // 按价格变化排序
    results.sort((a, b) {
      double diffA = (a.newPrice - a.oldPrice) / (a.oldPrice == 0 ? 1 : a.oldPrice);
      double diffB = (b.newPrice - b.oldPrice) / (b.oldPrice == 0 ? 1 : b.oldPrice);
      return diffB.compareTo(diffA);
    });

    return results;
  }

  // 格式化月份为马来文
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