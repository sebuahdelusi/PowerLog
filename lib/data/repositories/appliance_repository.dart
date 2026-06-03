import '../local/database_helper.dart';
import '../models/appliance_model.dart';
import '../../services/session_service.dart';
import 'log_repository.dart';

class ApplianceRepository {
  final _db = DatabaseHelper.instance;
  final _logRepo = LogRepository();
  final _session = SessionService();

  String get _userId => _session.getCachedUsername();

  Future<List<ApplianceModel>> fetchAllAppliances() async {
    final maps = await _db.getAllAppliances(_userId);
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
      userId: _userId,
    );

    await _db.insertAppliance(model.toMap());
  }

  Future<void> deleteAppliance(int id) async {
    await _db.deleteAppliance(id);
  }

  Future<void> updateAppliance(int id, String name, String wattageStr, String hoursStr) async {
    final wattage = double.tryParse(wattageStr) ?? 0.0;
    final hours = double.tryParse(hoursStr) ?? 0.0;
    if (name.trim().isEmpty || wattage <= 0 || hours <= 0) {
      throw Exception('Invalid input data');
    }
    final model = ApplianceModel(
      id: id,
      name: name.trim(),
      wattage: wattage,
      hoursPerDay: hours,
      userId: _userId,
    );
    await _db.updateAppliance(id, model.toMap());
  }

  // Calculate monthly cost of an appliance (30 days)
  double calculateMonthlyCost(ApplianceModel appliance) {
    return _logRepo.calculateCost(appliance.dailyKwh * 30);
  }
}