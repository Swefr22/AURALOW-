// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../widgets/background.dart'; 
import 'gameplay_screen.dart';
import 'levels_screen.dart'; 
import '../utils/storage.dart';
import '../models/level_theme.dart'; 
import 'dart:math'; 

// Keeping your Theme definitions
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _showInstructions(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('How to play', style: TextStyle(color: Colors.white)),
        content: const Text(
          '1) Allow microphone permission.\n'
          '2) Hold phone ~20–30 cm from your mouth.\n'
          '3) Exhale softly to move the orb.\n\n'
          'No timers. No losing. Focus and relax.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CalmBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// ---------------------------
                ///      INSERTED: APP LOGO
                /// ---------------------------
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/logo.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                /// ---------------------------
                ///      APP TITLE
                /// ---------------------------
                Text(
                  'AURALOW',
                  style: TextStyle(
                    fontSize: 36, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white, 
                    shadows: [
                      Shadow(blurRadius: 18, color: Colors.cyanAccent.withOpacity(0.6), offset: const Offset(0, 4))
                    ]
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Breathe • Relax • Play', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 28),

                /// ---------------------------
                ///      START BUTTON
                /// ---------------------------
                ElevatedButton(
                  onPressed: () async {
                    // Get the currently selected level and theme ID from storage.
                    final currentLevelId = Storage.getInt('currentLevel') ?? 1;
                    final selectedThemeId = Storage.getInt('selectedThemeId') ?? 1;
                    
                    // Find the full LevelTheme object based on the selected ID.
                    final LevelTheme themeToUse = allThemes.firstWhere(
                      (theme) => theme.id == selectedThemeId,
                      orElse: () => allThemes.first, 
                    );

                    final seen = Storage.getBool('seenInstructions') ?? false;

                    if (seen == false) {
                      showDialog(
                        context: context, 
                        builder: (_) => WillPopScope(
                        onWillPop: () async => false,
                        child: AlertDialog(
                          backgroundColor: Colors.black87,
                          title: const Text('Quick tips', style: TextStyle(color: Colors.white)),
                          content: const Text('Hold phone at comfortable distance and exhale slowly to move the orb.',
                              style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(onPressed: () {
                              Storage.setBool('seenInstructions', true);
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => GameplayScreen(levelId: currentLevelId, theme: themeToUse)));
                            },
                                child: const Text('Start', style: TextStyle(color: Colors.cyanAccent)))
                          ],
                        ),
                      ));
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GameplayScreen(levelId: currentLevelId, theme: themeToUse)));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14), 
                      shape: const StadiumBorder(), 
                      backgroundColor: Colors.cyanAccent),
                  child: const Text('Start', style: TextStyle(color: Colors.black, fontSize: 16)),
                ),

                const SizedBox(height: 12),
                
                /// ---------------------------
                ///    LEVELS & THEMES BUTTON
                /// ---------------------------
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelsScreen()));

                    if (result != null && result is Map && result['theme'] is LevelTheme && result['levelId'] is int) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GameplayScreen(levelId: result['levelId'], theme: result['theme'])));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12), 
                      shape: const StadiumBorder(), 
                      backgroundColor: Colors.white12),
                  child: const Text('Levels & Themes', style: TextStyle(color: Colors.white)),
                ),

                const SizedBox(height: 18),
                
                /// ---------------------------
                ///      HOW TO PLAY BUTTON
                /// ---------------------------
                TextButton(
                  onPressed: () => _showInstructions(context), 
                  child: const Text('How to play', style: TextStyle(color: Colors.white70))
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}