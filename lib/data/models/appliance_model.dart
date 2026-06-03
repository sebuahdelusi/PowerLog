class ApplianceModel {
  final int? id;
  final String name;
  final double wattage;
  final double hoursPerDay;
  final String userId; // username pemilik data ini

  ApplianceModel({
    this.id,
    required this.name,
    required this.wattage,
    required this.hoursPerDay,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'wattage': wattage,
      'hours_per_day': hoursPerDay,
      'user_id': userId,
    };
  }

  factory ApplianceModel.fromMap(Map<String, dynamic> map) {
    return ApplianceModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      wattage: (map['wattage'] as num).toDouble(),
      hoursPerDay: (map['hours_per_day'] as num).toDouble(),
      userId: map['user_id'] as String? ?? '',
    );
  }

  // Calculate daily kWh consumption
  double get dailyKwh => (wattage * hoursPerDay) / 1000.0;
}
