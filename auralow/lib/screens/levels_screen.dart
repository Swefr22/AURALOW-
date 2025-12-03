// lib/screens/levels_screen.dart
import 'package:flutter/material.dart';
import '../widgets/background.dart';
import '../utils/storage.dart';

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({Key? key}) : super(key: key);
  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  int unlocked = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final val = await Storage.getInt('unlockedLevel') ?? 1;
    setState(() => unlocked = val);
  }

  void _unlockNext() async {
    final next = (unlocked + 1).clamp(1, 5);
    await Storage.setInt('unlockedLevel', next);
    setState(() => unlocked = next);
  }

  Widget _levelTile(int idx, String title, String subtitle) {
    final locked = idx > unlocked;
    return ListTile(
      leading: CircleAvatar(backgroundColor: locked ? Colors.white12 : Colors.cyanAccent, child: Text('$idx', style: TextStyle(color: locked?Colors.white38:Colors.black))),
      title: Text(title, style: TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white60)),
      trailing: locked ? Icon(Icons.lock, color: Colors.white38) : Icon(Icons.check_circle, color: Colors.cyanAccent),
      onTap: () {
        if (!locked) {
          Storage.setInt('currentLevel', idx);
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CalmBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text('Levels & Themes'), backgroundColor: Colors.transparent, elevation: 0),
        body: ListView(
          padding: EdgeInsets.all(12),
          children: [
            _levelTile(1, 'Level 1 — Sky Drift', 'Soft clouds and gentle light'),
            _levelTile(2, 'Level 2 — Forest Aura', 'Fireflies and green glow'),
            _levelTile(3, 'Level 3 — Ocean Calm', 'Bubbles and blue waves'),
            _levelTile(4, 'Level 4 — Cosmic Glow', 'Stars and slow twinkles'),
            _levelTile(5, 'Level 5 — Dream Pink', 'Warm soft petals'),
            SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => _unlockNext(),
              child: Text('Unlock Next Level (demo)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            )
          ],
        ),
      ),
    );
  }
}
