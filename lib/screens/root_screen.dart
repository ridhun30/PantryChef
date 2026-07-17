import 'package:flutter/material.dart';

import '../app_state.dart';
import 'dishes_screen.dart';
import 'ingredients_screen.dart';
import 'suggest_screen.dart';

class RootScreen extends StatefulWidget {
  final AppState appState;
  const RootScreen({super.key, required this.appState});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      SuggestScreen(appState: widget.appState),
      IngredientsScreen(appState: widget.appState),
      DishesScreen(appState: widget.appState),
    ];

    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        return Scaffold(
          body: screens[_index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Suggest'),
              NavigationDestination(icon: Icon(Icons.egg_alt_outlined), label: 'Ingredients'),
              NavigationDestination(icon: Icon(Icons.menu_book), label: 'Dishes'),
            ],
          ),
        );
      },
    );
  }
}
