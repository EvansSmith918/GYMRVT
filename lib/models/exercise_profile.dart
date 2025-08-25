enum ExerciseType { squat, bench, curl, deadlift, row }

class ExerciseProfile {
  final ExerciseType type;
  final double downThreshold; // normalized depth 0..1 (higher = deeper)
  final double upThreshold;   // must rise above to finish rep
  final int minTempoMs;       // reject flickers
  final double minRom;        // min 0..1 ROM

  const ExerciseProfile({
    required this.type,
    required this.downThreshold,
    required this.upThreshold,
    required this.minTempoMs,
    required this.minRom,
  });

  static const squatDefault = ExerciseProfile(
    type: ExerciseType.squat, downThreshold: 0.62, upThreshold: 0.38, minTempoMs: 400, minRom: 0.20);
}
