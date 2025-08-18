class ExerciseDef {
  final String name;
  final List<String> muscles;
  final List<String> aliases;
  const ExerciseDef(this.name, this.muscles, [this.aliases = const []]);
}

class ExerciseLibrary {
  static const List<ExerciseDef> all = [
    ExerciseDef('Bench Press', ['chest', 'triceps', 'front delts'], ['flat bench', 'barbell bench']),
    ExerciseDef('Incline Bench', ['upper chest', 'triceps'], ['incline press']),
    ExerciseDef('Overhead Press', ['shoulders', 'triceps'], ['OHP', 'military press']),
    ExerciseDef('Back Squat', ['quads', 'glutes', 'hams'], ['squat']),
    ExerciseDef('Deadlift', ['posterior chain', 'back', 'glutes']),
    ExerciseDef('Barbell Row', ['back', 'lats'], ['bent-over row', 'bor']),
    ExerciseDef('Pull-Up', ['lats', 'back'], ['chin-up']),
    ExerciseDef('Dumbbell Curl', ['biceps']),
    ExerciseDef('Lat Pulldown', ['lats', 'back']),
    ExerciseDef('Romanian Deadlift', ['hamstrings', 'glutes'], ['RDL']),
  ];

  static List<String> suggestions(String query, {int limit = 12}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all.map((e) => e.name).toList();
    bool m(ExerciseDef e) =>
        e.name.toLowerCase().contains(q) ||
        e.aliases.any((a) => a.toLowerCase().contains(q)) ||
        e.muscles.any((m) => m.toLowerCase().contains(q));
    return all.where(m).map((e) => e.name).take(limit).toList();
  }
}
