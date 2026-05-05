import '../local/database_helper.dart';
import '../models/token_model.dart';

class TokenRepository {
  final _db = DatabaseHelper.instance;

  Future<List<TokenModel>> fetchAllTokens() async {
    final maps = await _db.getAllTokens();
    return maps.map(TokenModel.fromMap).toList();
  }

  Future<TokenModel?> fetchLatestToken() async {
    final map = await _db.getLatestToken();
    if (map == null) return null;
    return TokenModel.fromMap(map);
  }

  Future<void> addOrUpdateToken(TokenModel token) async {
    final existing = await _db.getTokenByDate(token.date);
    if (existing == null) {
      await _db.insertToken(token);
    } else {
      await _db.updateTokenByDate(token.date, token);
    }
  }

  Future<void> deleteToken(int id) async {
    await _db.deleteToken(id);
  }
}
