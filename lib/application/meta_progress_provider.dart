import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local_storage.dart';
import '../domain/entities/meta_progress.dart';

/// SharedPreferences 인스턴스 Provider.
///
/// main.dart의 ProviderScope에서 overrideWithValue로 주입한다.
/// 테스트에서는 mock 인스턴스로 override한다.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

/// LocalStorage 인스턴스 Provider.
final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage(ref.watch(sharedPreferencesProvider));
});

/// 메타 진행 상태 Provider.
final metaProgressProvider =
    NotifierProvider<MetaProgressNotifier, MetaProgress>(
  MetaProgressNotifier.new,
);

/// XP 추가, 레벨업, 영구 저장을 관리하는 Notifier.
class MetaProgressNotifier extends Notifier<MetaProgress> {
  @override
  MetaProgress build() {
    final storage = ref.watch(localStorageProvider);
    return MetaProgress(
      level: storage.playerLevel,
      xp: storage.playerXp,
      unlockedCardTypes: storage.unlockedCards,
    );
  }

  /// [amount]만큼 XP를 추가하고, 결과를 저장 후 LevelUpResult를 반환한다.
  Future<LevelUpResult> addXp(int amount) async {
    final (updated, result) = state.addXp(amount);

    final storage = ref.read(localStorageProvider);
    await storage.setPlayerXp(updated.xp);
    await storage.setPlayerLevel(updated.level);
    await storage.setUnlockedCards(updated.unlockedCardTypes);

    state = updated;
    return result;
  }

  /// 메타 진행 상태를 초기값으로 리셋한다.
  Future<void> reset() async {
    await ref.read(localStorageProvider).clear();
    state = MetaProgress.initial();
  }
}
