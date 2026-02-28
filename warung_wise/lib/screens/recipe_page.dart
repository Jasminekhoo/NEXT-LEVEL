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
    // 1. Nasi Lemak Biasa (RM6.00)
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
        ), 
        Ingredient(name: "Timun (1kg)", category: "Sayur", gram: 20),
        Ingredient(name: "Ikan Bilis", category: "Daging & Telur", gram: 10),
        Ingredient(
          name: "Bawang Merah India (1kg)",
          category: "Sayur",
          gram: 15,
        ), 
      ],
    ),

    // 2. Nasi Lemak Ayam (RM 7.00)
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
        ), 
      ],
    ),

    // 3. Teh O Ais (RM 1.00)
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
        ), 
      ],
    ),

    // 4. Kuih Muih (1 Keping) (RM 1.00)
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

  // Real price look up
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

  double calculateRecipeCost(Recipe recipe, {double profitMargin = 0.3}) {
    double totalCost = 0;

    for (var ingredient in recipe.ingredients) {
      double pricePerKg =
          ingredient.customPricePerKg ?? getPriceFromLookup(ingredient.name);
      double cost = 0;

      switch (ingredient.unit.toLowerCase()) {
        case 'biji':
          double unitWeightGram = ingredient.unitWeightGram ?? 50; // 50g for 1 egg
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

  void deleteIngredient(Recipe recipe, int index) {
    setState(() {
      recipe.ingredients.removeAt(index);
    });
  }

  void _showAddIngredientDialog(Recipe recipe) {
  final nameController = TextEditingController();
  final gramController = TextEditingController();
  final priceController = TextEditingController();

  String selectedCategory = "Keperluan";
  Map<String, String>? selectedItem;
  bool useLookup = true;

  showDialog(
    context: context,
    builder: (_) {
      String selectedUnit = 'g';
      return StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Tambah Bahan"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Toggle Pilih vs Custom (Lebih hemat ruang dari Radio) ---
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text("Senarai"),
                        icon: Icon(Icons.list_alt),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text("Custom"),
                        icon: Icon(Icons.edit_note),
                      ),
                    ],
                    selected: {useLookup},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setDialogState(() => useLookup = newSelection.first);
                    },
                  ),
                  const SizedBox(height: 20),

                  if (useLookup) ...[
                    // --- Dropdown Pilih Bahan ---
                    DropdownButtonFormField<Map<String, String>>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Pilih bahan",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      value: selectedItem,
                      items: PriceServiceCsv.itemLookup.values.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item['name']!, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedItem = val;
                          nameController.text = val?['name'] ?? '';
                          selectedCategory = val?['cat'] ?? 'Keperluan';

                          // LOGIC ASLI ANDA
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

                          bool isTelur = RegExp(
                            r'telur',
                            caseSensitive: false,
                          ).hasMatch(selectedItem?['name'] ?? '');

                          if (isTelur) {
                            selectedUnit = 'biji';
                            gramController.text = '1';
                            double singlePrice = latestPrice.newPrice / 10;
                            priceController.text = singlePrice.toStringAsFixed(3);
                          } else {
                            selectedUnit = 'g';
                            gramController.text = '100';
                            priceController.text = latestPrice.newPrice.toStringAsFixed(2);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // --- Custom Inputs ---
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Nama Bahan",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // --- Row Jumlah & Unit (Optimasi Horizontal) ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: gramController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Jumlah",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: selectedUnit,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'g', child: Text('g')),
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(value: 'biji', child: Text('biji')),
                          ],
                          onChanged: (value) {
                            setDialogState(() => selectedUnit = value!);
                          },
                        ),
                      ),
                    ],
                  ),

                  if (!useLookup) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Harga per KG / Biji",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: "Kategori",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: "Keperluan", child: Text("Keperluan")),
                        DropdownMenuItem(value: "Daging & Telur", child: Text("Daging & Telur")),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00695C), // Warna hijau gelap sesuai gambar
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // LOGIC SIMPAN ASLI ANDA
                final double gram = double.tryParse(gramController.text.trim()) ?? 0;
                if (gram <= 0) return;

                double? pricePerUnit = double.tryParse(priceController.text.trim());

                setState(() {
                  recipe.ingredients.add(
                    Ingredient(
                      name: nameController.text.trim(),
                      category: selectedCategory,
                      gram: gram,
                      customPricePerKg: pricePerUnit,
                      unit: selectedUnit,
                    ),
                  );
                });

                Navigator.pop(context);
              },
              child: const Text("Tambah"),
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

                  // editable ingredient fields
                  ...recipe.ingredients.asMap().entries.map((entry) {
                    int i = entry.key;
                    Ingredient ing = entry.value;

                    double pricePerUnit =
                        ing.customPricePerKg ??
                        getPriceFromLookup(ing.name, ing.category);

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

                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.end,
                            children: [
                              const Text(
                                "RM ",
                                style: TextStyle(fontSize: 14),
                              ),
                              IntrinsicWidth(
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
                                      TextAlign.left,
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

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecipeDialog,
        backgroundColor: AppColors.lightOrange,
        child: const Icon(Icons.add),
        tooltip: "Tambah Resepi",
      ),
    );
  }
}
