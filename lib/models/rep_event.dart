import 'exercise_profile.dart';

class RepEvent {
  final DateTime ts;
  final ExerciseType type;
  final double rom;           // 0..1
  final double peakVelocity;  // normalized / s
  final Duration concentric;
  final Duration eccentric;

  RepEvent({
    required this.ts,
    required this.type,
    required this.rom,
    required this.peakVelocity,
    required this.concentric,
    required this.eccentric,
  });
}
