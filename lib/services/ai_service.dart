// lib/services/ai_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// API base:
/// - Emulator: use http://10.0.2.2:3000
/// - Physical device: http://<YOUR_PC_LAN_IP>:3000  (e.g., http://162.165.1.186:3000)
///
/// You can override this at run-time:
///   flutter run --dart-define=AI_API_BASE=http://192.168.1.186:3000
const String _apiBaseFromEnv = String.fromEnvironment(
  'AI_API_BASE',
  defaultValue: 'http://192.168.1.186:3000', // <- include http://
);

/// Ensures the base has a scheme and no trailing slash.
String _normalizeBase(String base) {
  var b = base.trim();
  if (!b.startsWith('http://') && !b.startsWith('https://')) {
    b = 'http://$b';
  }
  if (b.endsWith('/')) b = b.substring(0, b.length - 1);
  return b;
}

final String _kApiBase = _normalizeBase(_apiBaseFromEnv);

class AiService {
  static Uri _uri(String path) => Uri.parse('$_kApiBase$path');

  /// Sends a Base64 image to the Node server and returns the advice text.
  static Future<String> analyzeBase64(String base64Image) async {
    final res = await http.post(
      _uri('/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image': base64Image}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['advice'] as String?) ?? 'No advice returned from AI server.';
    } else {
      throw Exception('AI server error ${res.statusCode}: ${res.body}');
    }
  }

  /// Helper when you already have bytes.
  static Future<String> analyzeBytes(Uint8List bytes) =>
      analyzeBase64(base64Encode(bytes));
}
