// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../widgets/background.dart';
import 'levels_screen.dart';
import 'gameplay_screen.dart';
import '../utils/storage.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _showInstructions(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text('How to play', style: TextStyle(color: Colors.white)),
        content: Text(
          '1) Allow microphone permission.\n'
          '2) Hold phone ~20–30 cm from your mouth.\n'
          '3) Exhale softly to move the orb.\n\n'
          'No timers. No losing. Focus and relax.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx), child: Text('Got it', style: TextStyle(color: Colors.cyanAccent))),
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
                // logo
                Text('AURALOW',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, shadows: [
                      Shadow(blurRadius: 18, color: Colors.cyanAccent.withOpacity(0.6), offset: Offset(0, 4))
                    ])),
                SizedBox(height: 8),
                Text('Breathe • Relax • Play', style: TextStyle(color: Colors.white70)),
                SizedBox(height: 28),

                ElevatedButton(
                  onPressed: () async {
                    final seen = await Storage.getBool('seenInstructions') ?? false;
                    if (!seen) {
                      // show a quick modal then start
                      showDialog(context: context, builder: (_) => WillPopScope(
                        onWillPop: () async => false,
                        child: AlertDialog(
                          backgroundColor: Colors.black87,
                          title: Text('Quick tips', style: TextStyle(color: Colors.white)),
                          content: Text('Hold phone at comfortable distance and exhale slowly to move the orb.',
                            style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(onPressed: () { Storage.setBool('seenInstructions', true); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => GameplayScreen())); }, child: Text('Start', style: TextStyle(color: Colors.cyanAccent)))
                          ],
                        ),
                      ));
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GameplayScreen()));
                    }
                  },
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 48, vertical: 14), shape: StadiumBorder(), backgroundColor: Colors.cyanAccent),
                  child: Text('Start', style: TextStyle(color: Colors.black, fontSize: 16)),
                ),

                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LevelsScreen())),
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 36, vertical: 12), shape: StadiumBorder(), backgroundColor: Colors.white12),
                  child: Text('Levels & Themes', style: TextStyle(color: Colors.white)),
                ),

                SizedBox(height: 18),
                TextButton(onPressed: ()=>_showInstructions(context), child: Text('How to play', style: TextStyle(color: Colors.white70))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
