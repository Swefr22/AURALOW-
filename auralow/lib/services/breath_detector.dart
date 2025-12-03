import 'dart:async';
import 'package:noise_meter/noise_meter.dart';

class BreathDetector {
  final Noise _noise = Noise();
  StreamSubscription<NoiseReading>? _sub;
  final StreamController<double> _ampController = StreamController.broadcast();
  Stream<double> get amplitudeStream => _ampController.stream;

  double _baseline = -50.0;
  double _smoothed = 0.0;
  double _alpha = 0.12;
  bool _listening = false;

  Future<void> calibrate({int durationMs = 2000}) async {
    final samples = <double>[];
    try {
      _sub = _noise.noiseStream.listen((r) {
        samples.add(r.meanDecibel);
      });

      await Future.delayed(Duration(milliseconds: durationMs));

      await _sub?.cancel();

      if (samples.isNotEmpty) {
        _baseline =
            samples.reduce((a, b) => a + b) / samples.length;
      }

      print("Calibration done. Baseline = $_baseline");
    } catch (e, st) {
      print("Calibration error: $e\n$st");
      await _sub?.cancel();
    }
  }

  void startListening() {
    if (_listening) return;
    _listening = true;

    _sub = _noise.noiseStream.listen((r) {
      final db = r.meanDecibel;
      final rel = (db - _baseline);
      final scaled = rel / 12.0;
      _smoothed = _alpha * scaled + (1 - _alpha) * _smoothed;

      double out = _smoothed;
      if (out < 0) out = 0;
      if (out > 1) out = 1;

      print("BREATH DEBUG → db:$db rel:$rel scaled:$scaled smooth:$_smoothed");

      _ampController.add(out);
    });
  }

  void dispose() {
    _sub?.cancel();
    _ampController.close();
    _noise.dispose();
  }
}
