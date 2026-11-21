import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_chef/app_state.dart';
import 'package:pantry_chef/main.dart';
import 'package:pantry_chef/services/storage_service.dart';
import 'package:pantry_chef/services/updater.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final state = AppState(StorageService());
  await tester.runAsync(state.load);
  await tester.pumpWidget(PantryChefApp(appState: state, updater: Updater()));
  return state;
}

void main() {
  testWidgets('tapping an ingredient chip redraws it and the suggestions', (tester) async {
    await pumpApp(tester);
    final bread = find.widgetWithText(FilterChip, 'Bread');
    expect(tester.widget<FilterChip>(bread).selected, isFalse);

    await tester.tap(bread);
    await tester.tap(find.widgetWithText(FilterChip, 'Butter'));
    await tester.tap(find.widgetWithText(FilterChip, 'Cheese'));
    await tester.pump();

    expect(tester.widget<FilterChip>(bread).selected, isTrue);
    expect(find.text('You can make 1 dish'), findsOneWidget);
    expect(find.text('You have everything!'), findsOneWidget);
  });

  testWidgets('a new ingredient shows up in the list right away', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Ingredients'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton).hitTestable());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Avocado');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Avocado'), findsOneWidget);
  });

  testWidgets('leaving the dish editor with unsaved changes asks first', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Dishes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton).hitTestable());
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Dish name'), 'Pancakes');
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
  });
}
