class LogModel {
  final int? id;
  final String date; // ISO-8601 date string: yyyy-MM-dd
  final double kwhUsage;
  final double estimatedCost; // IDR
  final String userId; // username pemilik data ini

  const LogModel({
    this.id,
    required this.date,
    required this.kwhUsage,
    required this.estimatedCost,
    required this.userId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'kwh_usage': kwhUsage,
        'estimated_cost': estimatedCost,
        'user_id': userId,
      };

  factory LogModel.fromMap(Map<String, dynamic> map) => LogModel(
        id: map['id'] as int?,
        date: map['date'] as String,
        kwhUsage: (map['kwh_usage'] as num).toDouble(),
        estimatedCost: (map['estimated_cost'] as num).toDouble(),
        userId: map['user_id'] as String? ?? '',
      );
}
