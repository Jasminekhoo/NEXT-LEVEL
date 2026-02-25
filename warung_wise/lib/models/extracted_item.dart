class ExtractedItem {
  final String name;
  final String price; // e.g. "RM 18.50"
  final DateTime date;

  ExtractedItem({required this.name, required this.price, required this.date});

  ExtractedItem copyWith({String? name, String? price, DateTime? date}) {
    return ExtractedItem(
      name: name ?? this.name,
      price: price ?? this.price,
      date: date ?? this.date,
    );
  }
}
