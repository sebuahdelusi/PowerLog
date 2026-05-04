/// Static exchange rates relative to IDR.
/// Rates are approximate and fixed — replace with a live API call if needed.
class CurrencyConverter {
  // 1 IDR = x {currency} (Updated as of 2026)
  static const double _toUSD = 0.0000617;  // ~16,200 IDR/USD
  static const double _toEUR = 0.0000568;  // ~17,600 IDR/EUR
  static const double _toGBP = 0.0000488;  // ~20,500 IDR/GBP

  static const currencies = ['USD', 'EUR', 'GBP'];

  static const Map<String, String> symbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
  };

  /// Returns a map of {currencyCode: convertedAmount} from an IDR amount.
  static Map<String, double> fromIDR(double idr) => {
        'USD': idr * _toUSD,
        'EUR': idr * _toEUR,
        'GBP': idr * _toGBP,
      };

  static String format(String code, double amount) {
    final symbol = symbols[code] ?? code;
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
