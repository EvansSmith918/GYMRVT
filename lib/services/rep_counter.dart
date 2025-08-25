import 'dart:math';
import '../models/exercise_profile.dart';
import '../models/rep_event.dart';

enum Phase { idle, eccentric, concentric }

class RepCounter {
  final ExerciseProfile profile;
  Phase _phase = Phase.idle;
  DateTime? _eccStart;
  DateTime? _conStart;
  double _minY = 1e9;
  double _maxY = -1e9;
  double _peakVel = 0.0;

  RepCounter(this.profile);

  void _track(double y, double velAbs) {
    _minY = min(_minY, y);
    _maxY = max(_maxY, y);
    _peakVel = max(_peakVel, velAbs);
  }

  /// y = normalized vertical position of proxy point (0 = high/top, 1 = low/bottom)
  /// vel = dy/dt in normalized units per second (negative = moving up)
  RepEvent? update(double y, double vel, DateTime t) {
    _track(y, vel.abs());

    switch (_phase) {
      case Phase.idle:
        if (y > profile.downThreshold) {
          _phase = Phase.eccentric;
          _eccStart = t;
          _minY = _maxY = y;
          _peakVel = 0;
        }
        break;

      case Phase.eccentric:
        if (vel < 0) { // direction change = start concentric
          _phase = Phase.concentric;
          _conStart = t;
        }
        break;

      case Phase.concentric:
        if (y < profile.upThreshold) {
          final ecc = (_conStart ?? t).difference(_eccStart ?? t);
          final con = t.difference(_conStart ?? t);
          final rom = (_maxY - _minY).clamp(0.0, 1.0);
          final okTempo = (ecc + con).inMilliseconds >= profile.minTempoMs;
          final okRom = rom >= profile.minRom;

          final event = (okTempo && okRom)
              ? RepEvent(
                  ts: t,
                  type: profile.type,
                  rom: rom,
                  peakVelocity: _peakVel,
                  concentric: con,
                  eccentric: ecc,
                )
              : null;

          _phase = Phase.idle;
          _eccStart = _conStart = null;
          _minY = 1e9; _maxY = -1e9; _peakVel = 0;
          return event;
        }
        break;
    }
    return null;
  }
}
