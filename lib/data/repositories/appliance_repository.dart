import '../local/database_helper.dart';
import '../models/appliance_model.dart';
import 'log_repository.dart';

class ApplianceRepository {
  final _db = DatabaseHelper.instance;
  final _logRepo = LogRepository();

  Future<List<ApplianceModel>> fetchAllAppliances() async {
    final maps = await _db.getAllAppliances();
    return maps.map((m) => ApplianceModel.fromMap(m)).toList();
  }

  Future<void> addAppliance(String name, String wattageStr, String hoursStr) async {
    final wattage = double.tryParse(wattageStr) ?? 0.0;
    final hours = double.tryParse(hoursStr) ?? 0.0;
    
    if (name.trim().isEmpty || wattage <= 0 || hours <= 0) {
      throw Exception('Invalid input data');
    }

    final model = ApplianceModel(
      name: name.trim(),
      wattage: wattage,
      hoursPerDay: hours,
    );

    await _db.insertAppliance(model.toMap());
  }

  Future<void> deleteAppliance(int id) async {
    await _db.deleteAppliance(id);
  }

  // Calculate monthly cost of an appliance (30 days)
  double calculateMonthlyCost(ApplianceModel appliance) {
    return _logRepo.calculateCost(appliance.dailyKwh * 30);
  }
}
