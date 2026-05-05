class TokenModel {
  final int? id;
  final String date; // ISO-8601 date string: yyyy-MM-dd
  final double amountIdr;
  final String planCode;
  final double ratePerKwh;
  final double taxPercent;
  final bool includeTax;
  final double fixedFee;
  final bool includeFixedFee;

  const TokenModel({
    this.id,
    required this.date,
    required this.amountIdr,
    required this.planCode,
    required this.ratePerKwh,
    required this.taxPercent,
    required this.includeTax,
    required this.fixedFee,
    required this.includeFixedFee,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'token_date': date,
        'amount_idr': amountIdr,
        'plan_code': planCode,
        'rate_per_kwh': ratePerKwh,
        'tax_percent': taxPercent,
        'include_tax': includeTax ? 1 : 0,
        'fixed_fee': fixedFee,
        'include_fixed_fee': includeFixedFee ? 1 : 0,
      };

  factory TokenModel.fromMap(Map<String, dynamic> map) => TokenModel(
        id: map['id'] as int?,
        date: map['token_date'] as String,
        amountIdr: (map['amount_idr'] as num).toDouble(),
        planCode: map['plan_code'] as String,
        ratePerKwh: (map['rate_per_kwh'] as num).toDouble(),
        taxPercent: (map['tax_percent'] as num).toDouble(),
        includeTax: (map['include_tax'] as int) == 1,
        fixedFee: (map['fixed_fee'] as num).toDouble(),
        includeFixedFee: (map['include_fixed_fee'] as int) == 1,
      );
}
