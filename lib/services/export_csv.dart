import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

import 'package:gymrvt/services/workout_store.dart';
import 'package:gymrvt/services/user_prefs.dart';

class ExportCsv {
  static Future<String> generateCsv() async {
    final days = await WorkoutStore().allDays(newestFirst: false);
    final b = StringBuffer();
    b.writeln('date,exercise,reps,weight_display,unit,weight_lb,volume_lb,timestamp');

    final df = DateFormat('yyyy-MM-dd');
    final tf = DateFormat('yyyy-MM-dd HH:mm:ss');

    for (final d in days) {
      final date = DailyWorkout.parseYmd(d.ymd);
      for (final ex in d.exercises) {
        for (final s in ex.sets) {
          final disp = UserPrefs.toDisplay(s.weight, WeightUnit.lb);
          b.writeln([
            df.format(date),
            _csv(ex.name),
            s.reps,
            _csv(_num(disp)),
            'lb/kg',
            _num(s.weight),
            _num(s.volume),
            tf.format(s.time),
          ].join(','));
        }
      }
    }
    return b.toString();
  }

  static Future<String> saveCsvToFile(String csv) async {
    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/gymrvt_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csv, encoding: utf8);
    return path;
  }

  static Future<String> exportAndShare() async {
    final csv = await generateCsv();
    final path = await saveCsvToFile(csv);
    try {
      await Share.shareXFiles([XFile(path)], text: 'GymRVT export');
    } catch (_) {
      // If share isn’t supported, the file is still saved at [path]
    }
    return path;
  }

  static String _csv(String s) {
    final t = s.replaceAll('"', '""');
    return '"$t"';
    }

  static String _num(num n) =>
      n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2);
}
