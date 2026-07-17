import 'package:flutter/foundation.dart';

import 'models/dish.dart';
import 'models/ingredient.dart';
import 'services/seed_data.dart';
import 'services/storage_service.dart';

/// How well a dish matches the ingredients the user currently has selected.
class DishMatch {
  final Dish dish;
  final int haveCount;
  final int totalCount;
  final List<Ingredient> missing;

  const DishMatch({
    required this.dish,
    required this.haveCount,
    required this.totalCount,
    required this.missing,
  });

  bool get canMake => missing.isEmpty;
  double get ratio => totalCount == 0 ? 0 : haveCount / totalCount;
}

/// Holds all app data (ingredients, dishes, current selection) in memory,
/// persists every change to disk, and exposes the dish-suggestion logic.
class AppState extends ChangeNotifier {
  final StorageService _storage;

  List<Ingredient> ingredients = [];
  List<Dish> dishes = [];
  final Set<String> selectedIngredientIds = {};

  AppState(this._storage);

  Future<void> load() async {
    final bundle = await _storage.load();
    if (bundle.ingredients.isEmpty && bundle.dishes.isEmpty) {
      final seed = seedData();
      ingredients = seed.ingredients;
      dishes = seed.dishes;
      await _persist();
    } else {
      ingredients = bundle.ingredients;
      dishes = bundle.dishes;
    }
  }

  Future<void> _persist() => _storage.save(ingredients, dishes);

  /// Returns false if the name is empty or an ingredient with that name
  /// already exists.
  bool addIngredient(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final ingredient = Ingredient.create(trimmed);
    if (ingredients.any((i) => i.id == ingredient.id)) return false;
    ingredients.add(ingredient);
    notifyListeners();
    _persist();
    return true;
  }

  /// Deletes the ingredient and removes it from every dish that used it.
  void deleteIngredient(String id) {
    ingredients.removeWhere((i) => i.id == id);
    selectedIngredientIds.remove(id);
    dishes = dishes
        .map((d) => d.ingredientIds.contains(id)
            ? d.copyWith(ingredientIds: d.ingredientIds.where((x) => x != id).toList())
            : d)
        .toList();
    notifyListeners();
    _persist();
  }

  /// Returns false if a dish with that name already exists.
  bool addDish(Dish dish) {
    if (dishes.any((d) => d.id == dish.id)) return false;
    dishes.add(dish);
    notifyListeners();
    _persist();
    return true;
  }

  void updateDish(Dish dish) {
    dishes = dishes.map((d) => d.id == dish.id ? dish : d).toList();
    notifyListeners();
    _persist();
  }

  void deleteDish(String id) {
    dishes.removeWhere((d) => d.id == id);
    notifyListeners();
    _persist();
  }

  void toggleSelected(String ingredientId) {
    if (!selectedIngredientIds.add(ingredientId)) {
      selectedIngredientIds.remove(ingredientId);
    }
    notifyListeners();
  }

  void clearSelected() {
    selectedIngredientIds.clear();
    notifyListeners();
  }

  /// Dishes ranked by how makeable they are with the current selection:
  /// fully-makeable dishes first, then partial matches by how close they
  /// are, then alphabetically.
  List<DishMatch> get suggestions {
    final byId = {for (final i in ingredients) i.id: i};
    final matches = dishes.map((d) {
      final missing = d.ingredientIds
          .where((id) => !selectedIngredientIds.contains(id))
          .map((id) => byId[id])
          .whereType<Ingredient>()
          .toList();
      final total = d.ingredientIds.length;
      final have = total - missing.length;
      return DishMatch(dish: d, haveCount: have, totalCount: total, missing: missing);
    }).toList();

    matches.sort((a, b) {
      if (a.canMake != b.canMake) return a.canMake ? -1 : 1;
      final ratioCompare = b.ratio.compareTo(a.ratio);
      if (ratioCompare != 0) return ratioCompare;
      return a.dish.name.compareTo(b.dish.name);
    });
    return matches;
  }
}
