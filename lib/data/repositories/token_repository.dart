import '../local/database_helper.dart';
import '../models/token_model.dart';
import '../../services/session_service.dart';

class TokenRepository {
  final _db = DatabaseHelper.instance;
  final _session = SessionService();

  String get _userId => _session.getCachedUsername();

  Future<List<TokenModel>> fetchAllTokens() async {
    final maps = await _db.getAllTokens(_userId);
    return maps.map(TokenModel.fromMap).toList();
  }

  Future<TokenModel?> fetchLatestToken() async {
    final map = await _db.getLatestToken(_userId);
    if (map == null) return null;
    return TokenModel.fromMap(map);
  }

  Future<void> addOrUpdateToken(TokenModel token) async {
    final existing = await _db.getTokenByDate(token.date, _userId);
    if (existing == null) {
      await _db.insertToken(token);
    } else {
      await _db.updateTokenByDate(token.date, _userId, token);
    }
  }

  Future<void> deleteToken(int id) async {
    await _db.deleteToken(id);
  }
}