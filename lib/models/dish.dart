import '../util/names.dart';

class Dish {
  final String id;
  final String name;
  final List<String> ingredientIds;

  const Dish({required this.id, required this.name, required this.ingredientIds});

  static int _counter = 0;

  /// New dishes get a unique id that never changes, so a dish can be renamed
  /// freely and its old name can be reused by another dish. (Dishes saved by
  /// earlier versions keep their name-based ids; they are just strings.)
  factory Dish.create({required String name, required List<String> ingredientIds}) => Dish(
        id: 'd${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(_counter++).toRadixString(36)}',
        name: tidyName(name),
        ingredientIds: ingredientIds,
      );

  Dish copyWith({String? name, List<String>? ingredientIds}) => Dish(
        id: id,
        name: name == null ? this.name : tidyName(name),
        ingredientIds: ingredientIds ?? this.ingredientIds,
      );

  factory Dish.fromJson(Map<String, dynamic> json) => Dish(
        id: json['id'] as String,
        name: json['name'] as String,
        ingredientIds: List<String>.from(json['ingredientIds'] as List),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'ingredientIds': ingredientIds};
}
