import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../application/run_provider.dart';
import '../domain/entities/save_slot.dart';

/// 유효한 슬롯 ID 범위 (1~3).
const int kMaxSaveSlots = 3;

/// 게임 데이터의 로컬 저장소.
///
/// SharedPreferences를 백엔드로 사용해 Web·Android·iOS·Desktop 모두 지원한다.
/// 각 항목은 고정 키의 문자열·정수로 저장된다.
class LocalStorage {
  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  // ── 메타 진행 ────────────────────────────────────────────────────────────

  int get playerLevel => _prefs.getInt('meta_level') ?? 1;

  int get playerXp => _prefs.getInt('meta_xp') ?? 0;

  List<String> get unlockedCards {
    final raw = _prefs.getString('meta_unlocked_cards');
    if (raw == null) return const ['strike', 'defend'];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return const ['strike', 'defend'];
    }
  }

  Future<void> setPlayerLevel(int level) => _prefs.setInt('meta_level', level);

  Future<void> setPlayerXp(int xp) => _prefs.setInt('meta_xp', xp);

  Future<void> setUnlockedCards(List<String> cards) =>
      _prefs.setString('meta_unlocked_cards', jsonEncode(cards));

  /// 메타 진행 데이터를 모두 초기값으로 리셋한다.
  Future<void> clear() async {
    await _prefs.remove('meta_level');
    await _prefs.remove('meta_xp');
    await _prefs.remove('meta_unlocked_cards');
  }

  // ── 세이브 슬롯 ──────────────────────────────────────────────────────────

  static String _slotKey(int slotId) => 'save_slot_$slotId';

  /// [slotId] 슬롯에 저장된 [SaveSlot]을 반환한다. 없으면 null.
  SaveSlot? loadSaveSlot(int slotId) {
    final raw = _prefs.getString(_slotKey(slotId));
    if (raw == null) return null;
    try {
      return SaveSlot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      assert(false, 'save slot $slotId 역직렬화 실패: $e');
      return null;
    }
  }

  /// 현재 [runState]를 [slotId] 슬롯에 저장한다.
  Future<void> saveSaveSlot(int slotId, RunState runState) async {
    final slot = SaveSlot(
      slotId: slotId,
      runState: runState,
      savedAt: DateTime.now(),
    );
    await _prefs.setString(_slotKey(slotId), jsonEncode(slot.toJson()));
  }

  /// [slotId] 슬롯을 삭제한다.
  Future<void> deleteSaveSlot(int slotId) => _prefs.remove(_slotKey(slotId));

  /// 슬롯 1~3을 한 번에 로드한다. 비어 있는 슬롯은 null.
  List<SaveSlot?> loadAllSaveSlots() =>
      List.generate(kMaxSaveSlots, (i) => loadSaveSlot(i + 1));
}
