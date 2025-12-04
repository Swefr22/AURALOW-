// lib/models/level_theme.dart

import 'package:flutter/material.dart';

class LevelTheme {
  final int id;
  final String name;
  final Gradient gradient;

  const LevelTheme({required this.id, required this.name, required this.gradient});
}

// FIX: Define the allThemes list as a top-level variable for export
final List<LevelTheme> allThemes = [
  LevelTheme(
    id: 1, 
    name: 'Sky Drift', 
    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F172A), Color(0xFF4C1D95)]),
  ),
  LevelTheme(
    id: 2, 
    name: 'Forest Aura', 
    gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF064E3B), Color(0xFF166534)]),
  ),
  LevelTheme(
    id: 3, 
    name: 'Ocean Calm', 
    gradient: const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]),
  ),
  LevelTheme(
    id: 4, 
    name: 'Desert Star', 
    gradient: const RadialGradient(center: Alignment.center, radius: 1.0, colors: [Color(0xFF431388), Color(0xFF000000)]),
  ),
  LevelTheme(
    id: 5, 
    name: 'Celestial Void', 
    gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFBE185D), Color(0xFFF9A8D4)]),
  ),
];