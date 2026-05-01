import '../local/database_helper.dart';
import '../models/log_model.dart';

class LogRepository {
  static const double _ratePerKwh = 1500.0; // IDR/kWh dummy rate

  final _db = DatabaseHelper.instance;

  double calculateCost(double kwh) => kwh * _ratePerKwh;

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

      final log = LogModel(
        date: DateTime.now().toIso8601String().substring(0, 10),
        kwhUsage: kwh,
        estimatedCost: calculateCost(kwh),
      );
      await _db.insertLog(log);
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
}
