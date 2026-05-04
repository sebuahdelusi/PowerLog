import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:torch_light/torch_light.dart';

class SensorService {
  // ── Shake detection config ────────────────────────────────────────────────
  static const double _shakeThreshold = 22.0; // m/s² — medium sensitivity
  static const Duration _shakeCooldown = Duration(milliseconds: 2500);

  // ── State ─────────────────────────────────────────────────────────────────
  DateTime? _lastShake;
  bool _torchOn = false;
  bool _torchAvailable = false;
  bool _active = false;

  // ── Subscriptions ─────────────────────────────────────────────────────────
  StreamSubscription<AccelerometerEvent>? _accelSub;

  // ── Public streams ────────────────────────────────────────────────────────
  final _shakeController = StreamController<void>.broadcast();
  Stream<void> get onShake => _shakeController.stream;

  Stream<GyroscopeEvent> get gyroscopeStream =>
      gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval);

  // ── Init / Dispose ────────────────────────────────────────────────────────

  Future<void> init() async {
    _torchAvailable = await _checkTorchAvailable();
    resume();
  }

  void dispose() {
    pause();
    _shakeController.close();
  }

  void pause() {
    _accelSub?.cancel();
    _accelSub = null;
    if (_torchOn) _safeDisableTorch();
    _active = false;
  }

  void resume() {
    if (_active) return;
    _startAccelerometer();
    _active = true;
  }

  // ── Accelerometer / Shake ─────────────────────────────────────────────────

  void _startAccelerometer() {
    if (_accelSub != null) return;
    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_onAccelerometer);
  }

  void _onAccelerometer(AccelerometerEvent event) {
    // magnitude includes gravity (~9.8). A hard shake pushes well above threshold.
    final magnitude =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    if (magnitude < _shakeThreshold) return;

    final now = DateTime.now();
    if (_lastShake != null &&
        now.difference(_lastShake!) < _shakeCooldown) {
      return;
    }

    _lastShake = now;
    _shakeController.add(null); // notify listeners
    _toggleTorch();
  }

  // ── Torch ─────────────────────────────────────────────────────────────────

  Future<bool> _checkTorchAvailable() async {
    try {
      return await TorchLight.isTorchAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<void> _toggleTorch() async {
    if (!_torchAvailable) return;
    try {
      if (_torchOn) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      _torchOn = !_torchOn;
    } catch (_) {}
  }

  Future<void> _safeDisableTorch() async {
    try {
      await TorchLight.disableTorch();
    } catch (_) {}
  }

  bool get isTorchOn => _torchOn;
}
