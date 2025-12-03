// lib/screens/gameplay_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/breath_detector.dart';

class GameplayScreen extends StatefulWidget {
  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  // Breath detector
  final BreathDetector _detector = BreathDetector();
  StreamSubscription<double>? _ampSub;

  double _currentAmp = 0.0;     // amplitude from 0..1
  double _progress = 0.0;       // progress bar from 0..1
  double _sensitivity = 0.005;  // very easy for testing
  bool _detectorFailed = false;
  bool _calibrating = true;

  @override
  void initState() {
    super.initState();
    _initDetector();
  }

  Future<void> _initDetector() async {
    try {
      print("Calibrating...");
      await _detector.calibrate(durationMs: 2000); // ambient noise baseline
      print("Starting detector...");
      _detector.startListening();
      _calibrating = false;

      _ampSub = _detector.amplitudeStream.listen((val) {
        _currentAmp = val;

        // convert amplitude to movement speed
        final speed = ((val - _sensitivity).clamp(0.0, 1.0)) * 0.06;

        if (val > _sensitivity) {
          _progress += speed;
        } else {
          _progress -= 0.005;
        }

        _progress = _progress.clamp(0.0, 1.0);

        if (mounted) setState(() {});
      });
    } catch (e, st) {
      print("Detector init failed: $e\n$st");
      setState(() => _detectorFailed = true);
    }
  }

  @override
  void dispose() {
    _ampSub?.cancel();
    _detector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Center orb (moves with progress)
          Positioned(
            left: MediaQuery.of(context).size.width * 0.1,
            top: MediaQuery.of(context).size.height * (0.8 - _progress * 0.7),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.cyanAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 8,
                  )
                ],
              ),
            ),
          ),

          // Debug info corner box
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _calibrating
                        ? "Calibrating..."
                        : "Amp: ${( _currentAmp * 100 ).toStringAsFixed(0)}",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Progress: ${( _progress * 100 ).toStringAsFixed(0)}%",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          // Detector failed message
          if (_detectorFailed)
            Center(
              child: Text(
                "Microphone error.\nCheck permission.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.redAccent, fontSize: 20),
              ),
            ),
        ],
      ),
    );
  }
}
