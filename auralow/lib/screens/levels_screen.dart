// lib/screens/levels_screen.dart

import 'package:flutter/material.dart';
import '../models/level_theme.dart';
import '../utils/storage.dart'; 
import '../widgets/background.dart'; // Assuming CalmBackground is here

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({Key? key}) : super(key: key);

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  // State variables for the currently selected level and theme IDs
  int _currentLevel = 1;
  int _unlockedLevel = 1;
  int _selectedThemeId = 1;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  // Load the current settings from fixed Storage
  void _loadSavedSettings() {
    setState(() {
      _currentLevel = Storage.getInt('currentLevel') ?? 1;
      _unlockedLevel = Storage.getInt('unlockedLevel') ?? 1;
      _selectedThemeId = Storage.getInt('selectedThemeId') ?? 1;
    });
  }

  // Save the selected level/theme and navigate back to Home.
  Future<void> _handleSelection(int level, LevelTheme theme) async {
    // Save new settings
    await Storage.setInt('currentLevel', level);
    await Storage.setInt('selectedThemeId', theme.id);

    // Navigate back to HomeScreen and pass the selected data as a result.
    // The HomeScreen will use this result to immediately launch GameplayScreen.
    Navigator.pop(context, {'levelId': level, 'theme': theme});
  }

  @override
  Widget build(BuildContext context) {
    final themes = allThemes;

    return CalmBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Select Level & Theme'),
        ),
        
        // ✅ CORRECTED STRUCTURE
        body: SingleChildScrollView( 
          padding: const EdgeInsets.all(16.0),
          child: Column( 
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              // --- Theme Selection Section ---
              const Text(
                'Themes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: themes.length,
                  itemBuilder: (context, index) {
                    final theme = themes[index];
                    final isSelected = theme.id == _selectedThemeId;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedThemeId = theme.id;
                        });
                        Storage.setInt('selectedThemeId', theme.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            gradient: theme.gradient,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected ? Colors.cyanAccent : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: Colors.cyanAccent.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              theme.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(blurRadius: 5, color: Colors.black.withOpacity(0.7)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 40, color: Colors.white12),

              // --- Level Selection Section ---
              const Text(
                'Mazes (Levels)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 1.0,
                ),
                itemCount: 5, // Total of 5 levels defined
                itemBuilder: (context, index) {
                  final levelId = index + 1;
                  final isUnlocked = levelId <= _unlockedLevel;
                  final isCurrent = levelId == _currentLevel;
                  
                  // Find the currently selected theme object for passing to the handler
                  final selectedTheme = themes.firstWhere(
                    (t) => t.id == _selectedThemeId,
                    orElse: () => themes.first,
                  );

                  return Opacity(
                    opacity: isUnlocked ? 1.0 : 0.4,
                    child: ElevatedButton(
                      onPressed: isUnlocked
                          ? () => _handleSelection(levelId, selectedTheme)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUnlocked 
                            ? (isCurrent ? Colors.cyanAccent : Colors.white12) 
                            : Colors.grey.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isCurrent ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    // NEW STRUCTURE (FIXING ERROR)
                      child: Center( // Center the content inside the button
                        child: Column( // Now wrap the text and icons in a Column that is centered
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min, // Make Column take minimum vertical space
                          children: [
                            Text('Level $levelId',
                                style: TextStyle(
                                  color: isUnlocked
                                      ? (isCurrent ? Colors.black : Colors.white)
                                      : Colors.white54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                              )),
                            if (!isUnlocked)
                              const Icon(Icons.lock, color: Colors.white54, size: 20),
                            if (isCurrent)
                              const Text('(Current)', style: TextStyle(color: Colors.black, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 