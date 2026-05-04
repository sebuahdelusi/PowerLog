import 'package:get/get.dart';
import '../local/database_helper.dart';
import '../models/log_model.dart';
import '../../services/tariff_service.dart';

class LogRepository {
  final _db = DatabaseHelper.instance;
  final _tariff = Get.find<TariffService>();

  double calculateCost(double kwh, {bool forMonthly = false}) {
    return _tariff.calculateCost(kwh, forMonthly: forMonthly);
  }

  Future<List<LogModel>> fetchAllLogs() async {
    try {
      return await _db.getAllLogs();
    } catch (_) {
      return [];
    }
  }

  /// Returns null on success, error string on failure.
  Future<String?> addLog(String kwhInput) async {
    try {
      final kwh = double.tryParse(kwhInput.trim());
      if (kwh == null || kwh <= 0) return 'Enter a valid kWh value.';

      final date = DateTime.now().toIso8601String().substring(0, 10);
      final cost = calculateCost(kwh);

      final existing = await _db.getLogByDate(date);
      if (existing == null) {
        final log = LogModel(
          date: date,
          kwhUsage: kwh,
          estimatedCost: cost,
        );
        await _db.insertLog(log);
      } else {
        await _db.updateLogByDate(date, kwh, cost);
      }
      return null;
    } catch (e) {
      return 'Failed to save log: $e';
    }
  }

  Future<String?> deleteLog(int id) async {
    try {
      await _db.deleteLog(id);
      return null;
    } catch (e) {
      return 'Failed to delete log: $e';
    }
  }

  Future<String?> updateLog(int id, String kwhInput) async {
    try {
      final kwh = double.tryParse(kwhInput.trim());
      if (kwh == null || kwh <= 0) return 'Enter a valid kWh value.';

      final cost = calculateCost(kwh);
      await _db.updateLogById(id, kwh, cost);
      return null;
    } catch (e) {
      return 'Failed to update log: $e';
    }
  }

  Future<void> recalculateAllCosts() async {
    final logs = await _db.getAllLogs();
    for (final log in logs) {
      final newCost = calculateCost(log.kwhUsage);
      await _db.updateLogByDate(log.date, log.kwhUsage, newCost);
    }
  }
}
