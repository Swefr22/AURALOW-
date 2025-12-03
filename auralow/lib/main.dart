import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(AuralowApp());
}

class AuralowApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Auralow",
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: HomeScreen(),
    );
  }
}
