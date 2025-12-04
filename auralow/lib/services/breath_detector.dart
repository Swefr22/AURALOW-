// lib/services/breath_detector.dart

import 'dart:async';
import 'package:noise_meter/noise_meter.dart';

class BreathDetector {
  final NoiseMeter _noise = NoiseMeter();
  StreamSubscription<NoiseReading>? _sub;
  final StreamController<double> _ampController = StreamController.broadcast();
  Stream<double> get amplitudeStream => _ampController.stream;

  // ------------------------------------------------------------------
  // ⚙️ FINAL, STABLE CONSTANTS (TUNED FOR VISIBLE MOVEMENT)
  // ------------------------------------------------------------------
  // Scaling: 25 dB above baseline is max breath (1.0 amplitude).
  static const double DB_SCALING_FACTOR = 25.0; 
  
  // Alpha: Set higher (0.15) for responsive decay back toward the floor.
  static const double ALPHA_SMOOTHING = 0.15; 
  
  // Floor: Set to 0.10 to ensure a visually noticeable minimum speed/size.
  static const double MIN_SMOOTHING_FLOOR = 0.10; 
  // ------------------------------------------------------------------

  double _baseline = -50.0; // Initial fallback baseline (dB)
  double _smoothed = 0.0;
  bool _listening = false;

  /// Calibrate ambient sound for [durationMs] and returns the measured baseline.
  Future<double> calibrate({int durationMs = 2000}) async { 
    final samples = <double>[];
    try {
      _sub = _noise.noise.listen((r) {
        samples.add(r.meanDecibel);
      });
      await Future.delayed(Duration(milliseconds: durationMs));
      
      if (samples.isNotEmpty) {
        final avg = samples.reduce((a, b) => a + b) / samples.length;
        _baseline = avg;
      }
      print('BREATH DETECTOR → calibration done baseline:${_baseline.toStringAsFixed(2)}dB');
      return _baseline; 
    } catch (e, st) {
      print('BREATH DETECTOR → calibration error: $e\n$st');
      return _baseline; 
    } finally {
      await _sub?.cancel();
      _sub = null;
    }
  }

  /// Start continuous listening; emits smoothed normalized amplitude (0..1)
void startListening() {
    if (_listening) return;
    _listening = true;

    _sub = _noise.noise.listen((r) {
      final db = r.meanDecibel;

      final rel = (db - _baseline); 
      final scaled = rel / DB_SCALING_FACTOR; 
      
      // 1. Filter: Clamp negative scaled input to 0.0 (prevents aggressive decay).
      final nonNegativeScaled = scaled.clamp(0.0, double.infinity);
      
      // 2. Floor: Add a constant (MIN_SMOOTHING_FLOOR) to guarantee continuous movement.
      final inputForSmoothing = nonNegativeScaled + MIN_SMOOTHING_FLOOR;

      // Apply the Exponential Moving Average (EMA) filter.
      _smoothed = ALPHA_SMOOTHING * inputForSmoothing + (1 - ALPHA_SMOOTHING) * _smoothed;

      // Clamp the final output between 0.0 and 1.0.
      double out = _smoothed.clamp(0.0, 1.0); 

      // Debug print so you can monitor the values in the console.
      print('BREATH DEBUG → db:${db.toStringAsFixed(2)} rel:${rel.toStringAsFixed(2)} '
            'scaled:${scaled.toStringAsFixed(3)} smooth:${out.toStringAsFixed(3)}');
      
      _ampController.add(out);
    }, onError: (e, st) {
      print('BREATH DETECTOR → listen error: $e\n$st');
    });

    print('BREATH DETECTOR → listening started');
}

  void stop() {
    _sub?.cancel();
    _listening = false;
  }

  void dispose() {
    _sub?.cancel();
    _ampController.close();
  }
}