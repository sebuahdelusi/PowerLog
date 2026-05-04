class ApplianceModel {
  final int? id;
  final String name;
  final double wattage;
  final double hoursPerDay;

  ApplianceModel({
    this.id,
    required this.name,
    required this.wattage,
    required this.hoursPerDay,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'wattage': wattage,
      'hours_per_day': hoursPerDay,
    };
  }

  factory ApplianceModel.fromMap(Map<String, dynamic> map) {
    return ApplianceModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      wattage: (map['wattage'] as num).toDouble(),
      hoursPerDay: (map['hours_per_day'] as num).toDouble(),
    );
  }

  // Calculate daily kWh consumption
  double get dailyKwh => (wattage * hoursPerDay) / 1000.0;
}
