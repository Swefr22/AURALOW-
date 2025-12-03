// lib/services/breath_detector.dart
import 'dart:async';
import 'package:noise_meter/noise_meter.dart';

class BreathDetector {
  final NoiseMeter _noise = NoiseMeter();
  StreamSubscription<NoiseReading>? _sub;
  final StreamController<double> _ampController = StreamController.broadcast();
  Stream<double> get amplitudeStream => _ampController.stream;

  double _baseline = -50.0; // initial fallback baseline (dB)
  double _smoothed = 0.0;
  double _alpha = 0.12; // EMA smoothing factor (tuneable)
  bool _listening = false;

  /// Calibrate ambient sound for [durationMs] (default 2000ms)
  Future<void> calibrate({int durationMs = 2000}) async {
    final samples = <double>[];
    try {
      // subscribe to the package's `noise` stream (NoiseMeter.noise)
      _sub = _noise.noise.listen((r) {
        samples.add(r.meanDecibel);
      });
      await Future.delayed(Duration(milliseconds: durationMs));
      await _sub?.cancel();
      if (samples.isNotEmpty) {
        final avg = samples.reduce((a, b) => a + b) / samples.length;
        _baseline = avg;
      }
      print('BREATH DETECTOR → calibration done baseline:${_baseline.toStringAsFixed(2)}dB');
    } catch (e, st) {
      print('BREATH DETECTOR → calibration error: $e\n$st');
    } finally {
      await _sub?.cancel();
      _sub = null;
    }
  }

  /// Start continuous listening; emits smoothed normalized amplitude (0..1)
  void startListening() {
    if (_listening) return;
    _listening = true;

    // subscribe to the package's `noise` stream
    _sub = _noise.noise.listen((r) {
      final db = r.meanDecibel;
      final rel = (db - _baseline);            // relative dB above baseline
      final scaled = rel / 12.0;               // divisor: lower -> more sensitive (tune)
      _smoothed = _alpha * scaled + (1 - _alpha) * _smoothed;
      double out = _smoothed;
      if (out.isNaN) out = 0.0;
      if (out < 0) out = 0.0;
      if (out > 1.0) out = 1.0;
      // debug print so you can see values in terminal
      print('BREATH DEBUG → db:${db.toStringAsFixed(2)} rel:${rel.toStringAsFixed(2)} '
            'scaled:${scaled.toStringAsFixed(3)} smooth:${_smoothed.toStringAsFixed(3)}');
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
    // NOTE: NoiseMeter does not expose a dispose(), so we don't call it.
  }
}
