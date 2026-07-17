class Dish {
  final String id;
  final String name;
  final List<String> ingredientIds;

  const Dish({required this.id, required this.name, required this.ingredientIds});

  /// The id is derived once from the name at creation time and never
  /// changes, so renaming a dish later doesn't break its identity.
  factory Dish.create({required String name, required List<String> ingredientIds}) {
    final trimmed = name.trim();
    return Dish(id: trimmed.toLowerCase(), name: trimmed, ingredientIds: ingredientIds);
  }

  Dish copyWith({String? name, List<String>? ingredientIds}) => Dish(
        id: id,
        name: name ?? this.name,
        ingredientIds: ingredientIds ?? this.ingredientIds,
      );

  factory Dish.fromJson(Map<String, dynamic> json) => Dish(
        id: json['id'] as String,
        name: json['name'] as String,
        ingredientIds: List<String>.from(json['ingredientIds'] as List),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'ingredientIds': ingredientIds};
}
