import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/dish.dart';
import '../models/ingredient.dart';

class StorageBundle {
  final List<Ingredient> ingredients;
  final List<Dish> dishes;
  const StorageBundle(this.ingredients, this.dishes);
}

/// Persists ingredients and dishes on-device via SharedPreferences.
/// No network or backend is involved — everything stays local to the phone.
class StorageService {
  static const _ingredientsKey = 'pantry_chef_ingredients';
  static const _dishesKey = 'pantry_chef_dishes';

  Future<StorageBundle> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ingredientsJson = prefs.getString(_ingredientsKey);
    final dishesJson = prefs.getString(_dishesKey);

    final ingredients = ingredientsJson == null
        ? <Ingredient>[]
        : (jsonDecode(ingredientsJson) as List)
            .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
            .toList();

    final dishes = dishesJson == null
        ? <Dish>[]
        : (jsonDecode(dishesJson) as List)
            .map((e) => Dish.fromJson(e as Map<String, dynamic>))
            .toList();

    return StorageBundle(ingredients, dishes);
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
}
