class Ingredient {
  String name;
  String category;
  double gram;
  double? customPricePerKg;
  String unit;
  double? unitWeightGram;

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

  Recipe({
    required this.name,
    required this.ingredients,
  });
}