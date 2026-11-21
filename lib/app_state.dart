import 'package:flutter/foundation.dart';

import 'models/dish.dart';
import 'models/ingredient.dart';
import 'services/seed_data.dart';
import 'services/storage_service.dart';
import 'util/names.dart';

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

  /// A dish with no ingredients set can't be "made" — there's nothing to match.
  bool get canMake => totalCount > 0 && missing.isEmpty;
  bool get hasNoIngredients => totalCount == 0;
  double get ratio => totalCount == 0 ? 0 : haveCount / totalCount;
}

/// Why saving a dish was refused.
enum DishSaveResult { saved, emptyName, duplicateName }

/// Holds all app data (ingredients, dishes, current selection) in memory,
/// persists every change to disk, and exposes the dish-suggestion logic.
class AppState extends ChangeNotifier {
  final StorageService _storage;

  List<Ingredient> ingredients = [];
  List<Dish> dishes = [];
  final Set<String> selectedIngredientIds = {};

  AppState(this._storage);

  Future<void> load() async {
    StorageBundle? bundle;
    try {
      bundle = await _storage.load();
    } catch (err) {
      debugPrint('Could not load saved data: $err');
    }
    if (bundle == null) {
      // First launch: start with a small sample pantry. Only seeded once — if
      // the user later deletes everything, it stays empty.
      final seed = seedData();
      ingredients = seed.ingredients;
      dishes = seed.dishes;
      await _persist();
    } else {
      ingredients = bundle.ingredients;
      dishes = bundle.dishes;
      final known = ingredients.map((i) => i.id).toSet();
      selectedIngredientIds
        ..clear()
        ..addAll(bundle.selectedIngredientIds.where(known.contains));
    }
  }

  Future<void> _persist() => _storage.save(ingredients, dishes).catchError((Object err) {
        debugPrint('Could not save: $err');
      });

  Future<void> _persistSelection() => _storage.saveSelection(selectedIngredientIds).catchError((Object err) {
        debugPrint('Could not save selection: $err');
      });

  Ingredient? ingredientByName(String name) {
    final key = nameKey(name);
    for (final i in ingredients) {
      if (i.id == key) return i;
    }
    return null;
  }

  /// Returns false if the name is empty or an ingredient with that name
  /// already exists.
  bool addIngredient(String name) {
    if (tidyName(name).isEmpty) return false;
    final ingredient = Ingredient.create(name);
    if (ingredients.any((i) => i.id == ingredient.id)) return false;
    ingredients.add(ingredient);
    notifyListeners();
    _persist();
    return true;
  }

  /// Deletes the ingredient and removes it from every dish that used it.
  void deleteIngredient(String id) {
    ingredients.removeWhere((i) => i.id == id);
    if (selectedIngredientIds.remove(id)) _persistSelection();
    dishes = dishes
        .map((d) => d.ingredientIds.contains(id)
            ? d.copyWith(ingredientIds: d.ingredientIds.where((x) => x != id).toList())
            : d)
        .toList();
    notifyListeners();
    _persist();
  }

  bool _nameTaken(String name, {String? exceptId}) {
    final key = nameKey(name);
    return dishes.any((d) => d.id != exceptId && nameKey(d.name) == key);
  }

  DishSaveResult addDish(Dish dish) {
    if (tidyName(dish.name).isEmpty) return DishSaveResult.emptyName;
    if (_nameTaken(dish.name)) return DishSaveResult.duplicateName;
    dishes.add(dish);
    notifyListeners();
    _persist();
    return DishSaveResult.saved;
  }

  DishSaveResult updateDish(Dish dish) {
    if (tidyName(dish.name).isEmpty) return DishSaveResult.emptyName;
    if (_nameTaken(dish.name, exceptId: dish.id)) return DishSaveResult.duplicateName;
    dishes = dishes.map((d) => d.id == dish.id ? dish : d).toList();
    notifyListeners();
    _persist();
    return DishSaveResult.saved;
  }

  void deleteDish(String id) {
    dishes.removeWhere((d) => d.id == id);
    notifyListeners();
    _persist();
  }

  /// Puts back a dish removed with [deleteDish] (for "Undo").
  void restoreDish(Dish dish, int index) {
    if (dishes.any((d) => d.id == dish.id)) return;
    dishes.insert(index.clamp(0, dishes.length), dish);
    notifyListeners();
    _persist();
  }

  void toggleSelected(String ingredientId) {
    if (!selectedIngredientIds.add(ingredientId)) {
      selectedIngredientIds.remove(ingredientId);
    }
    notifyListeners();
    _persistSelection();
  }

  void clearSelected() {
    selectedIngredientIds.clear();
    notifyListeners();
    _persistSelection();
  }

  /// Dishes ranked by how makeable they are with the current selection:
  /// fully-makeable dishes first, then partial matches with the fewest missing
  /// ingredients (then the highest share already in hand), then
  /// alphabetically. Dishes with no ingredients set go last.
  List<DishMatch> get suggestions {
    final byId = {for (final i in ingredients) i.id: i};
    final matches = dishes.map((d) {
      // Ignore ids that no longer point at an ingredient so they neither count
      // as "have" nor as "missing".
      final required = d.ingredientIds.map((id) => byId[id]).whereType<Ingredient>().toList();
      final missing = required.where((i) => !selectedIngredientIds.contains(i.id)).toList()
        ..sort((a, b) => compareNames(a.name, b.name));
      return DishMatch(
        dish: d,
        haveCount: required.length - missing.length,
        totalCount: required.length,
        missing: missing,
      );
    }).toList();

    matches.sort((a, b) {
      if (a.hasNoIngredients != b.hasNoIngredients) return a.hasNoIngredients ? 1 : -1;
      if (a.canMake != b.canMake) return a.canMake ? -1 : 1;
      final missingCompare = a.missing.length.compareTo(b.missing.length);
      if (missingCompare != 0) return missingCompare;
      final ratioCompare = b.ratio.compareTo(a.ratio);
      if (ratioCompare != 0) return ratioCompare;
      return compareNames(a.dish.name, b.dish.name);
    });
    return matches;
  }
}
