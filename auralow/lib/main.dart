// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; 
import 'utils/storage.dart'; 

void main() async {
  // Must be called before calling any services like SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the storage utility
  await Storage.init(); 

  // Set the default values if they haven't been set yet.
  final currentLevel = Storage.getInt('currentLevel');
  if (currentLevel == null) {
    await Storage.setInt('currentLevel', 1);
    await Storage.setInt('unlockedLevel', 1);
    await Storage.setInt('selectedThemeId', 1); // Set default theme ID
  }
  
  // NOTE: Storage.getBool('seenInstructions') is now checked in home_screen.dart,
  // using the corrected Storage.getBool() method.

  runApp(const AuralowApp());
}

class AuralowApp extends StatelessWidget {
  const AuralowApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auralow',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.cyan,
          brightness: Brightness.dark,
        ).copyWith(
          secondary: Colors.redAccent,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Roboto', color: Colors.white),
          bodyMedium: TextStyle(fontFamily: 'Roboto', color: Colors.white70),
          titleLarge: TextStyle(fontFamily: 'Roboto', color: Colors.white, fontWeight: FontWeight.bold),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(), // Correctly starts the app on the main menu
    );
  }
}