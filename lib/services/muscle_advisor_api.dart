// lib/services/muscle_advisor_api.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:gymrvt/services/muscle_advisor.dart'; // reuses MuscleAdvice class
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Set this to your deployed API endpoint (e.g. https://your-domain/analyze)
/// If left empty, we automatically fall back to on-device heuristic advice.
const String API_URL = ""; // <-- fill me when your backend is live

class MuscleAdvisorApi {
  static Future<MuscleAdvice> tryAnalyzeOrFallback({
    required File imageFile,
    Pose? poseForFallback,
  }) async {
    if (API_URL.trim().isEmpty) {
      // No endpoint set -> local heuristic
      return MuscleAdvisor.analyze(pose: poseForFallback);
    }

    try {
      final uri = Uri.parse(API_URL);
      final req = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      // Optional: attach user metadata if you like
      req.fields['source'] = 'gymrvt_mobile';

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final summary = (data['summary'] ?? 'Analysis complete.') as String;
        final focus = (data['focus'] as List?)?.cast<String>() ?? const <String>[];
        final caution = (data['caution'] as List?)?.cast<String>() ?? const <String>[];

        return MuscleAdvice(summary: summary, focus: focus, caution: caution);
      } else {
        // API failed -> graceful fallback
        return MuscleAdvisor.analyze(pose: poseForFallback);
      }
    } catch (_) {
      // Network/parse error -> graceful fallback
      return MuscleAdvisor.analyze(pose: poseForFallback);
    }
  }
}
