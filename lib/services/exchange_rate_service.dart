import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'session_service.dart';

class ExchangeRateService extends GetxService {
  static const _baseUrls = [
    'https://cdn.jsdelivr.net/gh/fawazahmed0/exchange-api@1/latest/currencies',
    'https://raw.githubusercontent.com/fawazahmed0/exchange-api/1/latest/currencies',
    'https://cdn.jsdelivr.net/npm/@fawazahmed0/exchange-api@1/latest/currencies',
    'https://fastly.jsdelivr.net/npm/@fawazahmed0/exchange-api@1/latest/currencies',
    'https://latest.currency-api.pages.dev/v1/currencies',
  ];
  static const _cacheTtl = Duration(hours: 24);
  static const _requestTimeout = Duration(seconds: 4);

  final _session = SessionService();
  final _http = HttpClient()..connectionTimeout = const Duration(seconds: 4);
  String? _lastError;

  final defaultCurrency = 'IDR'.obs;
  final _cachedRates = <String, double>{}.obs;

  String? get lastError => _lastError;

  Future<ExchangeRateService> init() async {
    defaultCurrency.value = await _session.getDefaultCurrency();
    await _warmCache();
    return this;
  }

  Future<void> _warmCache() async {
    try {
      await getAvailableCurrencies();
      final rates = await getRates('idr');
      _cachedRates.assignAll(rates);
    } catch (_) {}
  }

  Future<List<String>> getAvailableCurrencies({
    bool forceRefresh = false,
  }) async {
    _lastError = null;
    final cached = await _session.getCurrencyListCache();
    if (!forceRefresh && cached != null && !_isStale(cached.fetchedAt)) {
      if (_looksLikeCurrencyCodes(cached.codes)) {
        return cached.codes;
      }
      await _session.clearCurrencyListCache();
    }

    // Try all URLs in parallel — whoever responds first wins.
    final result = await _fetchFirst(
      _baseUrls.map((baseUrl) => () async {
        final data = await _getJson('$baseUrl.json');
        if (data is! Map<String, dynamic>) throw Exception('Not a map');
        if (!_looksLikeCurrencyList(data)) {
          throw Exception('Invalid currency list payload from $baseUrl');
        }
        final codes = data.keys
            .map((e) => e.toUpperCase())
            .where((c) => RegExp(r'^[A-Z]{3}$').hasMatch(c))
            .toList()
          ..sort();
        if (codes.isEmpty) throw Exception('Empty codes from $baseUrl');
        await _session.setCurrencyListCache(codes, DateTime.now());
        _lastError = null;
        return codes;
      }),
    );

    if (result != null) return result;
    return cached?.codes ?? [];
  }

  Future<Map<String, double>> getRates(
    String base, {
    bool forceRefresh = false,
  }) async {
    _lastError = null;
    final normalized = base.toLowerCase();
    final cached = await _session.getRatesCache(normalized);
    if (!forceRefresh && cached != null && !_isStale(cached.fetchedAt)) {
      if (_looksLikeRates(cached.rates)) {
        return cached.rates;
      }
      await _session.clearRatesCache();
    }

    // Try all URLs in parallel — whoever responds first wins.
    final result = await _fetchFirst(
      _baseUrls.map((baseUrl) => () async {
        final data = await _getJson('$baseUrl/$normalized.json');
        if (data is! Map<String, dynamic>) throw Exception('Not a map');

        final raw = data[normalized];
        if (raw is! Map<String, dynamic>) throw Exception('No $normalized key');
        if (!_looksLikeRateMap(raw)) {
          throw Exception('Invalid rate map from $baseUrl');
        }

        final rates = <String, double>{};
        raw.forEach((key, value) {
          if (value is num) {
            rates[key.toUpperCase()] = value.toDouble();
          }
        });

        await _session.setRatesCache(normalized, rates, DateTime.now());
        _cachedRates.assignAll(rates);
        _lastError = null;
        return rates;
      }),
    );

    if (result != null) return result;
    return cached?.rates ?? {};
  }

  /// Runs [futures] in parallel and returns the first that succeeds.
  /// If all fail, returns `null`.
  Future<T?> _fetchFirst<T>(Iterable<Future<T> Function()> futures) async {
    // Eagerly start all requests in parallel.
    final fs = futures
        .map((fn) async {
          try {
            return await fn().timeout(_requestTimeout);
          } catch (_) {
            return null;
          }
        })
        .toList();
    // As they complete, return the first non-null value.
    for (final f in fs) {
      final value = await f;
      if (value != null) return value;
    }
    return null;
  }

  Future<double?> getRate({required String from, required String to}) async {
    if (from.toUpperCase() == to.toUpperCase()) return 1.0;
    final rates = await getRates(from);
    return rates[to.toUpperCase()];
  }

  Future<double?> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    final rate = await getRate(from: from, to: to);
    if (rate == null) return null;
    return amount * rate;
  }

  String format(String code, double amount) {
    final c = code.toUpperCase();
    return NumberFormat.currency(
      locale: _localeFor(c),
      symbol: _currencySymbol(c),
      decimalDigits: _currencyDecimals(c),
    ).format(amount);
  }

  String _localeFor(String code) {
    switch (code) {
      case 'IDR': return 'id_ID';
      case 'EUR': return 'de_DE';
      case 'USD': return 'en_US';
      case 'GBP': return 'en_GB';
      case 'JPY': return 'ja_JP';
      case 'CNY': return 'zh_CN';
      case 'SGD': return 'en_SG';
      case 'MYR': return 'ms_MY';
      case 'THB': return 'th_TH';
      default: return 'en_US';
    }
  }

  String _currencySymbol(String code) {
    const symbols = <String, String>{
      'IDR': 'Rp ',
      'EUR': '€',
      'USD': '\$',
      'GBP': '£',
      'JPY': '¥',
      'CNY': '¥',
      'SGD': 'S\$',
      'MYR': 'RM',
      'THB': '฿',
      'KRW': '₩',
      'INR': '₹',
      'AUD': 'A\$',
      'CAD': 'C\$',
      'CHF': 'CHF ',
      'SAR': '﷼',
      'BND': 'B\$',
      'VND': '₫',
    };
    return symbols[code] ?? '\$$code ';
  }

  int _currencyDecimals(String code) {
    const noDecimal = <String>{
      'JPY', 'KRW', 'IDR', 'VND', 'CLP', 'ISK', 'BIF', 'DJF',
    };
    return noDecimal.contains(code) ? 0 : 2;
  }

  Future<List<String>> getSelectedCurrencies() {
    return _session.getSelectedCurrencies();
  }

  Future<void> setSelectedCurrencies(List<String> codes) {
    return _session.setSelectedCurrencies(codes);
  }

  Future<String> getDefaultCurrency() {
    return _session.getDefaultCurrency();
  }

  Future<void> setDefaultCurrency(String code) async {
    await _session.setDefaultCurrency(code);
    defaultCurrency.value = code.toUpperCase();
  }

  String formatIdrToDefault(double idrAmount) {
    final activeCurrency = defaultCurrency.value;
    if (activeCurrency == 'IDR') {
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(idrAmount);
    }
    final rate = _cachedRates[activeCurrency] ?? 0.0;
    if (rate == 0.0) {
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(idrAmount);
    }
    final converted = idrAmount * rate;
    return format(activeCurrency, converted);
  }

  bool _isStale(DateTime fetchedAt) {
    return DateTime.now().difference(fetchedAt) > _cacheTtl;
  }

  Future<dynamic> _getJson(String url) async {
    final request = await _http.getUrl(Uri.parse(url));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.userAgentHeader, 'PowerLog/1.0');
    final response = await request.close().timeout(_requestTimeout);
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(_requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to fetch exchange data (${response.statusCode}).',
      );
    }
    final decoded = _decodeJson(body);
    return _unwrapProxyResponse(decoded);
  }

  dynamic _decodeJson(String body) {
    try {
      return json.decode(body);
    } catch (_) {
      final start = body.indexOf('{');
      final end = body.lastIndexOf('}');
      if (start >= 0 && end > start) {
        final jsonText = body.substring(start, end + 1);
        return json.decode(jsonText);
      }
      rethrow;
    }
  }

  dynamic _unwrapProxyResponse(dynamic decoded) {
    if (decoded is Map<String, dynamic> && decoded['data'] is Map) {
      final data = decoded['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    return decoded;
  }

  bool _looksLikeCurrencyList(Map<String, dynamic> data) {
    if (data.containsKey('content') ||
        data.containsKey('description') ||
        data.containsKey('external') ||
        data.containsKey('metadata')) {
      return false;
    }
    return data.containsKey('usd') || data.containsKey('idr');
  }

  bool _looksLikeCurrencyCodes(List<String> codes) {
    return codes.contains('USD') || codes.contains('IDR');
  }

  bool _looksLikeRateMap(Map<String, dynamic> data) {
    return data.containsKey('usd') || data.containsKey('eur');
  }

  bool _looksLikeRates(Map<String, double> data) {
    return data.containsKey('USD') || data.containsKey('EUR');
  }
}
