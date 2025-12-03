// lib/screens/gameplay_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/breath_detector.dart';
import '../utils/storage.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({Key? key}) : super(key: key);

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  // Breath detector
  final BreathDetector _detector = BreathDetector();
  StreamSubscription<double>? _ampSub;

  // UI / state
  double _currentAmp = 0.0; // amplitude from 0..1
  double _progress = 0.0; // progress 0..1
  double _sensitivity = 0.005; // tuneable by slider
  bool _detectorFailed = false;
  bool _calibrating = true;

  // demo mode (simulated breathing)
  bool _demoMode = false;
  Timer? _demoTimer;
  double _demoTime = 0.0;

  @override
  void initState() {
    super.initState();
    _initDetector();
  }

  Future<void> _initDetector() async {
    try {
      setState(() {
        _calibrating = true;
      });
      // calibrate first (captures ambient baseline)
      await _detector.calibrate(durationMs: 1500);
      // subscribe to the detector stream
      _subscribeToDetector();
      setState(() {
        _calibrating = false;
      });
    } catch (e, st) {
      print("Detector init failed: $e\n$st");
      setState(() => _detectorFailed = true);
    }
  }

  void _subscribeToDetector() {
    // ensure previous subscription is cancelled
    _ampSub?.cancel();

    try {
      _detector.startListening();
      _ampSub = _detector.amplitudeStream.listen((val) {
        // when not in demo mode, use live amplitude
        if (_demoMode) return;

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
      }, onError: (e, st) {
        print("Amplitude stream error: $e\n$st");
      });
    } catch (e, st) {
      print("Subscribe error: $e\n$st");
      setState(() => _detectorFailed = true);
    }
  }

  // Start demo mode: simulated calm breathing sine wave
  void _startDemo() {
    _demoTimer?.cancel();
    _demoMode = true;

    // stop real detector listening
    _ampSub?.cancel();
    _detector.stop();

    _demoTime = 0.0;
    _demoTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      _demoTime += 0.033;
      // calm breathing wave (period ~6s)
      final base = 0.5 + 0.45 * sin(2 * pi * (_demoTime / 6.0));
      // small jitter
      final jitter = (Random().nextDouble() - 0.5) * 0.02;
      final val = (base + jitter).clamp(0.0, 1.0);
      _currentAmp = val;

      // reuse same movement logic as live
      final speed = ((_currentAmp - _sensitivity).clamp(0.0, 1.0)) * 0.06;
      if (_currentAmp > _sensitivity) {
        _progress += speed;
      } else {
        _progress -= 0.005;
      }
      _progress = _progress.clamp(0.0, 1.0);

      if (mounted) setState(() {});
    });
    if (mounted) setState(() {});
  }

  void _stopDemo() {
    _demoTimer?.cancel();
    _demoTimer = null;
    _demoMode = false;
    // restart detector
    _subscribeToDetector();
    if (mounted) setState(() {});
  }

  // End-of-session: show calm score and unlock next level
  void _onSessionComplete() async {
    final calmScore = (_progress * 100).toInt();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text('Session complete', style: TextStyle(color: Colors.white)),
        content: Text('Calm Score: $calmScore\nNice work!', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () async {
              final current = await Storage.getInt('unlockedLevel') ?? 1;
              await Storage.setInt('unlockedLevel', (current + 1).clamp(1, 5));
              Navigator.pop(context);
            },
            child: Text('Unlock next', style: TextStyle(color: Colors.cyanAccent)),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _ampSub?.cancel();
    _detector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // safe sizes
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // background soft glow (center)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment( -0.2, -0.4),
                    radius: 1.2,
                    colors: [Colors.deepPurple.shade900, Colors.black],
                  ),
                ),
              ),
            ),
          ),

          // Center orb (moves with progress)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            left: w * 0.5 - 24,
            top: h * (0.75 - _progress * 0.6),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.cyanAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.45),
                    blurRadius: 28,
                    spreadRadius: 8,
                  )
                ],
              ),
              child: Center(
                child: Icon(Icons.air_outlined, color: Colors.black87),
              ),
            ),
          ),

          // Debug info corner box
          Positioned(
            top: 40,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _calibrating ? "Calibrating..." : "Amp: ${(_currentAmp * 100).toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Progress: ${(_progress * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _demoMode ? "Mode: Demo" : "Mode: Live",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls: sensitivity slider, demo toggle, end session
          Positioned(
            left: 12,
            right: 12,
            bottom: 18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // sensitivity + demo row
                Row(
                  children: [
                    const Text('Sensitivity', style: TextStyle(color: Colors.white70)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Slider(
                        min: 0.001,
                        max: 0.05,
                        value: _sensitivity,
                        onChanged: (v) => setState(() => _sensitivity = v),
                        divisions: 40,
                        label: _sensitivity.toStringAsFixed(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        const Text('Demo', style: TextStyle(color: Colors.white70)),
                        Switch(
                          value: _demoMode,
                          onChanged: (v) {
                            if (v) {
                              _startDemo();
                            } else {
                              _stopDemo();
                            }
                          },
                          activeColor: Colors.cyanAccent,
                        ),
                      ],
                    )
                  ],
                ),

                const SizedBox(height: 8),

                // End session button
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onSessionComplete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white12,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('End Session', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Detector failed message (overlays)
          if (_detectorFailed)
            const Center(
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
