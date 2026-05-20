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

  final _session = SessionService();
  final _http = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  String? _lastError;

  String? get lastError => _lastError;

  Future<ExchangeRateService> init() async {
    await _warmCache();
    return this;
  }

  Future<void> _warmCache() async {
    try {
      await getAvailableCurrencies();
      await getRates('idr');
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

    for (final baseUrl in _baseUrls) {
      try {
        final data = await _getJson('$baseUrl.json');
        if (data is! Map<String, dynamic>) continue;
        if (!_looksLikeCurrencyList(data)) {
          _lastError = 'Invalid currency list payload from $baseUrl';
          continue;
        }

        final codes =
            data.keys
                .map((e) => e.toUpperCase())
                .where((c) => RegExp(r'^[A-Z]{3}$').hasMatch(c))
                .toList()
              ..sort();
        if (codes.isEmpty) continue;
        await _session.setCurrencyListCache(codes, DateTime.now());
        _lastError = null;
        return codes;
      } catch (e) {
        _lastError = 'Failed to load currency list from $baseUrl ($e)';
      }
    }
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

    for (final baseUrl in _baseUrls) {
      try {
        final data = await _getJson('$baseUrl/$normalized.json');
        if (data is! Map<String, dynamic>) continue;

        final raw = data[normalized];
        if (raw is! Map<String, dynamic>) continue;
        if (!_looksLikeRateMap(raw)) {
          _lastError = 'Invalid rate payload from $baseUrl';
          continue;
        }

        final rates = <String, double>{};
        raw.forEach((key, value) {
          if (value is num) {
            rates[key.toUpperCase()] = value.toDouble();
          }
        });

        await _session.setRatesCache(normalized, rates, DateTime.now());
        _lastError = null;
        return rates;
      } catch (e) {
        _lastError = 'Failed to load rates for $normalized from $baseUrl ($e)';
      }
    }
    return cached?.rates ?? {};
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
    final formatter = NumberFormat.simpleCurrency(name: code.toUpperCase());
    return formatter.format(amount);
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

  Future<void> setDefaultCurrency(String code) {
    return _session.setDefaultCurrency(code);
  }

  bool _isStale(DateTime fetchedAt) {
    return DateTime.now().difference(fetchedAt) > _cacheTtl;
  }

  Future<dynamic> _getJson(String url) async {
    final request = await _http.getUrl(Uri.parse(url));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.userAgentHeader, 'PowerLog/1.0');
    final response = await request.close().timeout(const Duration(seconds: 8));
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 8));
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
