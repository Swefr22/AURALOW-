import 'package:flutter/material.dart';
import 'gameplay_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Auralow"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Breath-Controlled Relaxation Game",
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GameplayScreen()),
                );
              },
              child: Text("Start Game"),
            ),
          ],
        ),
      ),
    );
  }
}
