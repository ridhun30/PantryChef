import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dish.dart';
import '../models/ingredient.dart';

class StorageBundle {
  final List<Ingredient> ingredients;
  final List<Dish> dishes;
  final Set<String> selectedIngredientIds;
  const StorageBundle(this.ingredients, this.dishes, [this.selectedIngredientIds = const {}]);
}

/// Persists ingredients, dishes and the current selection on-device via
/// SharedPreferences. No network or backend is involved — everything stays
/// local to the phone.
class StorageService {
  static const _ingredientsKey = 'pantry_chef_ingredients';
  static const _dishesKey = 'pantry_chef_dishes';
  static const _selectedKey = 'pantry_chef_selected';

  /// Returns null when nothing has ever been saved (first launch). An empty
  /// bundle means the user deliberately deleted everything.
  Future<StorageBundle?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ingredientsJson = prefs.getString(_ingredientsKey);
    final dishesJson = prefs.getString(_dishesKey);
    if (ingredientsJson == null && dishesJson == null) return null;

    return StorageBundle(
      _decodeList(ingredientsJson, Ingredient.fromJson),
      _decodeList(dishesJson, Dish.fromJson),
      (prefs.getStringList(_selectedKey) ?? const []).toSet(),
    );
  }

  /// Decodes a saved list, skipping any entry that can't be read instead of
  /// crashing the app on launch.
  List<T> _decodeList<T>(String? json, T Function(Map<String, dynamic>) fromJson) {
    if (json == null) return <T>[];
    try {
      final result = <T>[];
      for (final e in jsonDecode(json) as List) {
        try {
          result.add(fromJson(e as Map<String, dynamic>));
        } catch (err) {
          debugPrint('Skipping unreadable saved entry: $err');
        }
      }
      return result;
    } catch (err) {
      debugPrint('Saved data is unreadable: $err');
      return <T>[];
    }
  }

  Future<void> save(List<Ingredient> ingredients, List<Dish> dishes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _ingredientsKey,
      jsonEncode(ingredients.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _dishesKey,
      jsonEncode(dishes.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> saveSelection(Set<String> selectedIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedKey, selectedIds.toList());
  }
}
