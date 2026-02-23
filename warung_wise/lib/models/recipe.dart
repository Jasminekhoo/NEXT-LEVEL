class Ingredient {
  String name;
  String category;
  double gram; // 对于 biji，存数量；对 kg/g，存重量
  double? customPricePerKg;
  String unit; // 'biji', 'g', 'kg'
  double? unitWeightGram; // 每个单位重量（biji专用）

  Ingredient({
    required this.name,
    required this.category,
    required this.gram,
    this.customPricePerKg,
    this.unit = 'g',
    this.unitWeightGram,
  });
}

class Recipe {
  String name;
  List<Ingredient> ingredients;

  Recipe({required this.name, required this.ingredients});
}
