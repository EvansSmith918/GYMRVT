// lib/services/health_service.dart
import 'package:health/health.dart' as h;

class HealthService {
  HealthService._();
  static final HealthService instance = HealthService._();

  // Newer health versions expose `Health()` instead of `HealthFactory()`
  final h.Health _health = h.Health();

  static const _types = <h.HealthDataType>[
    h.HealthDataType.WEIGHT,
    h.HealthDataType.HEIGHT,
    h.HealthDataType.BODY_FAT_PERCENTAGE,
  ];

  static const _perms = <h.HealthDataAccess>[
    h.HealthDataAccess.READ,
    h.HealthDataAccess.READ,
    h.HealthDataAccess.READ,
  ];

  Future<bool> requestAuthorization() async {
    try {
      return await _health.requestAuthorization(_types, permissions: _perms);
    } catch (_) {
      return false;
    }
  }

  Future<double?> latestBodyMassLb() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));
      final data = await _health.getHealthDataFromTypes(
        types: const [h.HealthDataType.WEIGHT],
        startTime: start,
        endTime: now,
      );
      if (data.isEmpty) return null;
      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final kg = (data.first.value as num?)?.toDouble();
      if (kg == null) return null;
      return double.parse((kg * 2.2046226218).toStringAsFixed(1));
    } catch (_) {
      return null;
    }
  }

  Future<double?> latestHeightInches() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 365));
      final data = await _health.getHealthDataFromTypes(
        types: const [h.HealthDataType.HEIGHT],
        startTime: start,
        endTime: now,
      );
      if (data.isEmpty) return null;
      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final meters = (data.first.value as num?)?.toDouble();
      if (meters == null) return null;
      return double.parse((meters * 39.37007874).toStringAsFixed(1));
    } catch (_) {
      return null;
    }
  }

  Future<double?> latestBodyFatPercent() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 365));
      final data = await _health.getHealthDataFromTypes(
        types: const [h.HealthDataType.BODY_FAT_PERCENTAGE],
        startTime: start,
        endTime: now,
      );
      if (data.isEmpty) return null;
      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      return (data.first.value as num?)?.toDouble();
    } catch (_) {
      return null;
    }
  }
}
