import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/root_screen.dart';
import 'services/storage_service.dart';
import 'services/updater.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState(StorageService());
  final updater = Updater();
  await Future.wait([appState.load(), updater.init()]);
  runApp(PantryChefApp(appState: appState, updater: updater));
}

class PantryChefApp extends StatelessWidget {
  final AppState appState;
  final Updater updater;
  const PantryChefApp({super.key, required this.appState, required this.updater});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pantry Chef',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: Colors.deepOrange, brightness: Brightness.dark, useMaterial3: true),
      home: RootScreen(appState: appState, updater: updater),
    );
  }
}
