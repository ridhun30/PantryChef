class Ingredient {
  final String id;
  final String name;

  const Ingredient({required this.id, required this.name});

  /// The id is derived from the trimmed, lowercased name so duplicate
  /// ingredients (e.g. "Egg" vs "egg ") collapse to the same entry.
  factory Ingredient.create(String name) {
    final trimmed = name.trim();
    return Ingredient(id: trimmed.toLowerCase(), name: trimmed);
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
