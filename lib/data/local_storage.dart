import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 키 상수.
abstract final class _Keys {
  static const playerLevel = 'player_level';
  static const playerXp = 'player_xp';
  static const unlockedCards = 'unlocked_cards';
}

/// 게임 메타 진행 데이터의 로컬 저장소 래퍼.
///
/// 비즈니스 로직 없음 — 단순 read/write 전용.
/// Application 계층에서만 호출된다.
class LocalStorage {
  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  int get playerLevel => _prefs.getInt(_Keys.playerLevel) ?? 1;

  int get playerXp => _prefs.getInt(_Keys.playerXp) ?? 0;

  List<String> get unlockedCards =>
      _prefs.getStringList(_Keys.unlockedCards) ?? const ['strike', 'defend'];

  Future<void> setPlayerLevel(int level) =>
      _prefs.setInt(_Keys.playerLevel, level);

  Future<void> setPlayerXp(int xp) => _prefs.setInt(_Keys.playerXp, xp);

  Future<void> setUnlockedCards(List<String> cards) =>
      _prefs.setStringList(_Keys.unlockedCards, cards);

  /// 메타 진행 데이터를 모두 초기값으로 리셋한다.
  Future<void> clear() async {
    await _prefs.remove(_Keys.playerLevel);
    await _prefs.remove(_Keys.playerXp);
    await _prefs.remove(_Keys.unlockedCards);
  }
}
