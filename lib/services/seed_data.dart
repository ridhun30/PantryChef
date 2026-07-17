import '../models/dish.dart';
import '../models/ingredient.dart';
import 'storage_service.dart';

/// A small starter pantry so the app isn't empty on first launch.
/// Only used once, when there is no saved data yet.
StorageBundle seedData() {
  const ingredientNames = [
    'Egg',
    'Rice',
    'Onion',
    'Tomato',
    'Garlic',
    'Salt',
    'Pepper',
    'Oil',
    'Flour',
    'Milk',
    'Cheese',
    'Pasta',
    'Butter',
    'Chicken',
    'Bread',
  ];
  final ingredients = ingredientNames.map(Ingredient.create).toList();

  Dish dish(String name, List<String> ingredientNames) => Dish.create(
        name: name,
        ingredientIds: ingredientNames.map((n) => n.trim().toLowerCase()).toList(),
      );

  final dishes = [
    dish('Fried Rice', ['Rice', 'Egg', 'Onion', 'Oil', 'Salt']),
    dish('Omelette', ['Egg', 'Milk', 'Salt', 'Pepper', 'Butter']),
    dish('Tomato Pasta', ['Pasta', 'Tomato', 'Garlic', 'Oil', 'Salt']),
    dish('Grilled Cheese Sandwich', ['Bread', 'Cheese', 'Butter']),
    dish('Garlic Butter Chicken', ['Chicken', 'Garlic', 'Butter', 'Salt', 'Pepper']),
  ];

  return StorageBundle(ingredients, dishes);
}
