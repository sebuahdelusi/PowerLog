import 'package:get/get.dart';
import 'package:powerlog/data/models/log_model.dart';
import 'package:powerlog/data/repositories/log_repository.dart';

class AnalyticsController extends GetxController {
  final _repo = LogRepository();

  final logs = <LogModel>[].obs;
  final isLoading = false.obs;

  // For charts
  final dailyUsage = <DateTime, double>{}.obs;
  
  // For prediction
  final predictedMonthlyCost = 0.0.obs;
  final averageDailyKwh = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    final data = await _repo.fetchAllLogs();
    logs.value = data;
    
    _processData();
    isLoading.value = false;
  }

  void _processData() {
    if (logs.isEmpty) {
      dailyUsage.clear();
      predictedMonthlyCost.value = 0.0;
      averageDailyKwh.value = 0.0;
      return;
    }

    // Group by Date and sum kWh
    final Map<DateTime, double> usageMap = {};
    double totalKwh = 0;

    for (var log in logs) {
      try {
        final date = DateTime.parse(log.date);
        final day = DateTime(date.year, date.month, date.day);
        usageMap[day] = (usageMap[day] ?? 0) + log.kwhUsage;
        totalKwh += log.kwhUsage;
      } catch (_) {}
    }

    // Sort map by date
    final sortedKeys = usageMap.keys.toList()..sort();
    
    // Get last 7 days of data for the chart
    final Map<DateTime, double> chartData = {};
    final chartKeys = sortedKeys.length > 7 ? sortedKeys.sublist(sortedKeys.length - 7) : sortedKeys;
    
    for (var key in chartKeys) {
      chartData[key] = usageMap[key]!;
    }
    
    dailyUsage.value = chartData;

    // Bill prediction
    // Calculate average daily usage based on the range of logs
    if (sortedKeys.isNotEmpty) {
      final firstDate = sortedKeys.first;
      final lastDate = sortedKeys.last;
      var span = lastDate.difference(firstDate).inDays + 1;
      if (span <= 0) span = 1;
      
      averageDailyKwh.value = totalKwh / span;
      // Predict 30 days
      final predicted30DayKwh = averageDailyKwh.value * 30;
      predictedMonthlyCost.value = _repo.calculateCost(predicted30DayKwh);
    } else {
      averageDailyKwh.value = 0;
      predictedMonthlyCost.value = 0;
    }
  }
}
