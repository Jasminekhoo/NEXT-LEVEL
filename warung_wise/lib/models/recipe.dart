class Ingredient {
  String name;
  String category; // 必须 match: Keperluan, Daging & Telur, Sayur, Buah
  double gram;
  double? customPricePerKg; // optional for tambah bahan

  Ingredient({
    required this.name,
    required this.category,
    required this.gram,
    this.customPricePerKg,
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