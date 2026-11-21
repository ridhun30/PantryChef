import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_chef/app_state.dart';
import 'package:pantry_chef/models/dish.dart';
import 'package:pantry_chef/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> freshState([Map<String, Object> saved = const {}]) async {
  SharedPreferences.setMockInitialValues(saved);
  final state = AppState(StorageService());
  await state.load();
  return state;
}

void main() {
  test('first launch seeds sample data, but an emptied pantry stays empty', () async {
    final state = await freshState();
    expect(state.ingredients, isNotEmpty);
    expect(state.dishes, isNotEmpty);

    for (final d in [...state.dishes]) {
      state.deleteDish(d.id);
    }
    for (final i in [...state.ingredients]) {
      state.deleteIngredient(i.id);
    }
    await Future<void>.delayed(Duration.zero);

    final reloaded = AppState(StorageService());
    await reloaded.load();
    expect(reloaded.ingredients, isEmpty);
    expect(reloaded.dishes, isEmpty);
  });

  test('the selection is remembered across launches', () async {
    final state = await freshState();
    state.toggleSelected('egg');
    state.toggleSelected('rice');
    await Future<void>.delayed(Duration.zero);

    final reloaded = AppState(StorageService());
    await reloaded.load();
    expect(reloaded.selectedIngredientIds, {'egg', 'rice'});
  });

  test('unreadable saved data does not crash loading', () async {
    final state = await freshState({
      'pantry_chef_ingredients': '[{"id":"egg","name":"Egg"},{"broken":true}]',
      'pantry_chef_dishes': 'not json',
    });
    expect(state.ingredients.map((i) => i.name), ['Egg']);
    expect(state.dishes, isEmpty);
  });

  test('ingredient names are tidied and compared case-insensitively', () async {
    final state = await freshState();
    expect(state.addIngredient('  Olive   oil '), isTrue);
    expect(state.ingredients.last.name, 'Olive oil');
    expect(state.addIngredient('olive OIL'), isFalse);
    expect(state.addIngredient('   '), isFalse);
  });

  test('a renamed dish frees its old name and duplicate names are refused', () async {
    final state = await freshState();
    final omelette = state.dishes.firstWhere((d) => d.name == 'Omelette');

    expect(state.updateDish(omelette.copyWith(name: 'fried rice')), DishSaveResult.duplicateName);
    expect(state.updateDish(omelette.copyWith(name: 'Cheese Omelette')), DishSaveResult.saved);
    expect(state.addDish(Dish.create(name: 'Omelette', ingredientIds: ['egg'])), DishSaveResult.saved);
    expect(state.addDish(Dish.create(name: 'OMELETTE ', ingredientIds: ['egg'])), DishSaveResult.duplicateName);
  });

  test('suggestions: makeable first, then fewest missing; empty dishes last and never makeable', () async {
    final state = await freshState();
    state.deleteIngredient('bread');
    state.deleteIngredient('cheese');
    // Grilled Cheese Sandwich now only needs butter.
    for (final id in ['butter', 'egg', 'milk', 'salt']) {
      state.toggleSelected(id);
    }
    state.addDish(Dish.create(name: 'Air', ingredientIds: []));

    final s = state.suggestions;
    expect(s.first.dish.name, 'Grilled Cheese Sandwich');
    expect(s.first.canMake, isTrue);
    expect(s[1].dish.name, 'Omelette'); // only pepper missing
    expect(s[1].missing.map((i) => i.name), ['Pepper']);
    expect(s.last.dish.name, 'Air');
    expect(s.last.canMake, isFalse);
  });

  test('restoreDish undoes a delete', () async {
    final state = await freshState();
    final dish = state.dishes[2];
    state.deleteDish(dish.id);
    state.restoreDish(dish, 2);
    expect(state.dishes[2].id, dish.id);
  });
}
