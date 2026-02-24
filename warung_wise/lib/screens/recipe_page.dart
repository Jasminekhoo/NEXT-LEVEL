import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../models/recipe.dart';
import '../models/price_record.dart';
import '../services/price_service_csv.dart';
import '../services/gemini_service.dart';

class RecipePage extends StatefulWidget {
  final List<PriceRecord> latestPrices;

  const RecipePage({super.key, required this.latestPrices});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  // ---------------- SAMPLE RECIPES ----------------
  final List<Recipe> recipes = [
    // 1. Nasi Lemak Biasa (RM 3.00)
    Recipe(
      name: "Nasi Lemak Biasa",
      ingredients: [
        Ingredient(
          name: "Beras Cap Jasmine (SST5%)(10kg)",
          category: "Keperluan",
          gram: 100,
        ),
        Ingredient(
          name: "Santan Kelapa Segar (1kg)",
          category: "Keperluan",
          gram: 30,
        ),
        Ingredient(
          name: "Telur Ayam Gred B (10biji)",
          category: "Daging & Telur",
          gram: 50,
        ), // 半颗蛋约50g
        Ingredient(name: "Timun (1kg)", category: "Sayur", gram: 20),
        Ingredient(name: "Ikan Bilis", category: "Daging & Telur", gram: 10),
        Ingredient(
          name: "Bawang Merah India (1kg)",
          category: "Sayur",
          gram: 15,
        ), // 用于sambal
      ],
    ),

    // 2. Nasi Lemak Ayam (RM 6.50)
    Recipe(
      name: "Nasi Lemak Ayam",
      ingredients: [
        Ingredient(
          name: "Beras Cap Jasmine (SST5%)(10kg)",
          category: "Keperluan",
          gram: 100,
        ),
        Ingredient(
          name: "Ayam Bersih - Standard (1kg)",
          category: "Daging & Telur",
          gram: 150,
        ),
        Ingredient(
          name: "Santan Kelapa Segar (1kg)",
          category: "Keperluan",
          gram: 30,
        ),
        Ingredient(name: "Timun (1kg)", category: "Sayur", gram: 20),
        Ingredient(
          name: "Minyak Masak (1kg) - Buruh",
          category: "Keperluan",
          gram: 20,
        ), // 炸鸡耗油
      ],
    ),

    // 3. Teh O Ais (RM 2.00)
    Recipe(
      name: "Teh O Ais",
      ingredients: [
        Ingredient(
          name: "Gula Pasir Kasar (1kg)",
          category: "Keperluan",
          gram: 20,
        ),
        Ingredient(name: "Serbuk Teh", category: "Keperluan", gram: 5),
        Ingredient(
          name: "Limau Nipis (1kg)",
          category: "Buah",
          gram: 10,
        ), // 可选：Teh O Ais Limau
      ],
    ),

    // 4. Kuih Muih (1 Keping) (RM 0.50)
    Recipe(
      name: "Kuih Muih",
      ingredients: [
        Ingredient(
          name: "Tepung Gandum - Berbungkus (1kg)",
          category: "Keperluan",
          gram: 40,
        ),
        Ingredient(
          name: "Gula Pasir Halus (1kg)",
          category: "Keperluan",
          gram: 15,
        ),
        Ingredient(
          name: "Santan Kelapa Segar (1kg)",
          category: "Keperluan",
          gram: 10,
        ),
      ],
    ),
  ];

  // ---------------- REAL PRICE LOOKUP ----------------
  double getPriceFromLookup(String name, [String? category]) {
    try {
      final match = PriceServiceCsv.itemLookup.entries.firstWhere(
        (entry) =>
            entry.value['name']!.toLowerCase().contains(name.toLowerCase()) &&
            (category == null || entry.value['cat'] == category),
      );
      return widget.latestPrices
          .firstWhere(
            (p) => p.itemName == match.value['name'],
            orElse: () => PriceRecord(
              itemName: match.value['name']!,
              oldPrice: 0,
              newPrice: 0,
              history: [0, 0, 0],
              unit: 'unit',
              date: '',
              category: match.value['cat']!,
            ),
          )
          .newPrice;
    } catch (_) {
      return 0;
    }
  }

  // ---------------- COST CALCULATION ----------------
  // 计算单份食材成本 + 加上利润率得到售价
  double calculateRecipeCost(Recipe recipe, {double profitMargin = 0.3}) {
    double totalCost = 0;

    for (var ingredient in recipe.ingredients) {
      double pricePerKg =
          ingredient.customPricePerKg ?? getPriceFromLookup(ingredient.name);
      double cost = 0;

      // 按单位计算
      switch (ingredient.unit.toLowerCase()) {
        case 'biji':
          // 每个重量换算 kg，再乘价格
          double unitWeightGram = ingredient.unitWeightGram ?? 50; // 默认每个 50g
          cost = ingredient.gram * pricePerKg * (unitWeightGram / 1000);
          break;
        case 'g':
        case 'gram':
          cost = (ingredient.gram / 1000) * pricePerKg;
          break;
        case 'kg':
          cost = ingredient.gram * pricePerKg;
          break;
        default:
          cost = (ingredient.gram / 1000) * pricePerKg;
      }

      totalCost += cost;
    }

    return (totalCost * (1 + profitMargin)).ceilToDouble();
  }

  // ---------------- DELETE INGREDIENT ----------------

  void deleteIngredient(Recipe recipe, int index) {
    setState(() {
      recipe.ingredients.removeAt(index);
    });
  }

  // ---------------- ADD INGREDIENT ----------------
  void _showAddIngredientDialog(Recipe recipe) {
    final nameController = TextEditingController();
    final gramController = TextEditingController();
    final priceController = TextEditingController();

    String selectedCategory = "Keperluan";
    Map<String, String>? selectedItem; // 如果选已有商品
    bool useLookup = true; // 是否使用已有商品列表

    showDialog(
      context: context,
      builder: (_) {
        String selectedUnit = 'g'; // Dialog 内部局部状态
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text("Tambah Bahan"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  // 切换按钮：使用 lookup 或自定义
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text("Pilih dari senarai"),
                          value: true,
                          groupValue: useLookup,
                          onChanged: (val) {
                            setDialogState(() => useLookup = val!);
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text("Custom"),
                          value: false,
                          groupValue: useLookup,
                          onChanged: (val) {
                            setDialogState(() => useLookup = val!);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (useLookup) ...[
                    // Dropdown 选择已有商品
                    DropdownButton<Map<String, String>>(
                      isExpanded: true,
                      hint: const Text("Pilih bahan"),
                      value: selectedItem,
                      items: PriceServiceCsv.itemLookup.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item['name']!),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedItem = val;
                          nameController.text = val?['name'] ?? '';
                          selectedCategory = val?['cat'] ?? 'Keperluan';

                          // 获取最新价格
                          final latestPrice = widget.latestPrices.firstWhere(
                            (p) => p.itemName == selectedItem!['name'],
                            orElse: () => PriceRecord(
                              itemName: selectedItem!['name']!,
                              oldPrice: 0,
                              newPrice: 0,
                              history: [0, 0, 0],
                              unit: 'unit',
                              date: '',
                              category: selectedItem!['cat']!,
                            ),
                          );

                          // 判断是否是鸡蛋
                          bool isTelur = RegExp(
                            r'telur',
                            caseSensitive: false,
                          ).hasMatch(selectedItem?['name'] ?? '');

                          if (isTelur) {
                            selectedUnit = 'biji';
                            gramController.text = '1'; // 默认 1颗
                            // 鸡蛋价格总价 / 10 得单粒价格
                            double singlePrice = latestPrice.newPrice / 10;
                            priceController.text = singlePrice.toStringAsFixed(
                              3,
                            );
                          } else {
                            selectedUnit = 'g';
                            gramController.text = '100';
                            priceController.text = latestPrice.newPrice
                                .toStringAsFixed(2);
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    // Gram/Biji 输入
                    TextField(
                      controller: gramController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Jumlah："),
                    ),
                    const SizedBox(height: 10),

                    // 单位选择
                    DropdownButton<String>(
                      value: selectedUnit,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'g', child: Text('Gram')),
                        DropdownMenuItem(value: 'kg', child: Text('Kg')),
                        DropdownMenuItem(value: 'biji', child: Text('Biji')),
                      ],
                      onChanged: (value) {
                        setDialogState(() => selectedUnit = value!);
                      },
                    ),
                  ] else ...[
                    // 自定义输入
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Nama Bahan",
                      ),
                    ),
                    TextField(
                      controller: gramController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Gram/Biji"),
                    ),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Harga per KG / per biji",
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: "Keperluan",
                          child: Text("Keperluan"),
                        ),
                        DropdownMenuItem(
                          value: "Daging & Telur",
                          child: Text("Daging & Telur"),
                        ),
                        DropdownMenuItem(value: "Sayur", child: Text("Sayur")),
                        DropdownMenuItem(value: "Buah", child: Text("Buah")),
                      ],
                      onChanged: (value) {
                        setDialogState(() => selectedCategory = value!);
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Batal",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  final double gram =
                      double.tryParse(gramController.text.trim()) ?? 0;
                  if (gram <= 0) return;

                  double? pricePerUnit = double.tryParse(
                    priceController.text.trim(),
                  );

                  setState(() {
                    recipe.ingredients.add(
                      Ingredient(
                        name: nameController.text.trim(),
                        category: selectedCategory,
                        gram: gram,
                        customPricePerKg: pricePerUnit, // 鸡蛋即单粒价格
                        unit: selectedUnit,
                      ),
                    );
                  });

                  Navigator.pop(context);
                },
                child: const Text(
                  "Tambah",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddRecipeDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tambah Resepi"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Nama Resepi"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              setState(() {
                recipes.add(
                  Recipe(name: nameController.text.trim(), ingredients: []),
                );
              });
              Navigator.pop(context);
            },
            child: const Text(
              "Tambah",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.jungleGreen,
        foregroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Recipe Harga Simulator",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          final totalCost = calculateRecipeCost(recipe);

          return Card(
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 删除整个 recipe
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        recipe.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                          size: 28,
                        ),
                        tooltip: "Hapus Resepi",
                        onPressed: () {
                          setState(() {
                            recipes.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ⚡ ingredient 可编辑，价格显示按 portion
                  ...recipe.ingredients.asMap().entries.map((entry) {
                    int i = entry.key;
                    Ingredient ing = entry.value;

                    double pricePerUnit =
                        ing.customPricePerKg ??
                        getPriceFromLookup(ing.name, ing.category);

                    // 计算 portion 成本
                    double portionCost;
                    String unitLabel;

                    if (ing.unit == 'biji') {
                    portionCost = ing.gram * pricePerUnit;
                    unitLabel = "biji";
                    } else if (ing.unit == 'kg') {
                    portionCost = ing.gram * pricePerUnit;
                    unitLabel = "kg";
                    } else {
                    portionCost = (ing.gram / 1000) * pricePerUnit;
                    unitLabel = "g";
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. 名称 (自动占据剩余空间)
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: ing.name,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (val) => ing.name = val,
                          ),
                        ),

                        const SizedBox(width: 8),

                        // 2. 重量/数量 (靠右对齐)
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: ing.gram.toString(),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              suffixText: " $unitLabel",
                            ),
                            onChanged: (val) {
                              final g = double.tryParse(val);
                              if (g != null) {
                                ing.gram = g;
                                setState(() {});
                              }
                            },
                          ),
                        ),

                        const SizedBox(width: 8),

                        // 3. 价格 (核心修改：手动拼接 RM 以实现完美粘合)
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.end, // 关键：让内部组件整体靠右
                            children: [
                              const Text(
                                "RM ",
                                style: TextStyle(fontSize: 14),
                              ), // 固定不动的 RM
                              IntrinsicWidth(
                                // 关键：让输入框宽度随数字长度自动伸缩
                                child: TextFormField(
                                  key: ValueKey(
                                    "cost_${ing.name}_$portionCost",
                                  ),
                                  initialValue: portionCost.toStringAsFixed(2),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  textAlign:
                                      TextAlign.left, // 这里用 left，因为它已经靠右站了
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (val) {
                                    final p = double.tryParse(val);
                                    if (p != null) {
                                      if (unitLabel == "biji") {
                                        ing.customPricePerKg = p / ing.gram;
                                      } else {
                                        ing.customPricePerKg =
                                            p / (ing.gram / 1000);
                                      }
                                      setState(() {});
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 4. 删除按钮
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 22,
                          ),
                          onPressed: () => deleteIngredient(recipe, i),
                        ),
                      ],
                    );
                  }).toList(),

                  const SizedBox(height: 10),

                  Text(
                    "Total Kos (1 Portion): RM ${totalCost.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () => _showAddIngredientDialog(recipe),
                    child: const Text("Tambah Bahan"),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      // FloatingActionButton 添加 recipe
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecipeDialog,
        backgroundColor: AppColors.lightOrange,
        child: const Icon(Icons.add),
        tooltip: "Tambah Resepi",
      ),
    );
  }
}
