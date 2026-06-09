import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_storage.dart';
import '../domain/entities/meta_progress.dart';

/// LocalStorage 인스턴스 Provider.
///
/// main.dart의 ProviderScope에서 반드시 overrideWithValue로 주입한다.
/// 테스트에서는 mock SharedPreferences로 생성한 인스턴스로 override한다.
final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError(
    'localStorageProvider는 ProviderScope에서 overrideWithValue로 주입해야 합니다.',
  );
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
    final level = storage.playerLevel;
    return MetaProgress(
      level: level,
      xp: storage.playerXp,
      unlockedCardTypes: MetaProgress.computeUnlockedCards(level),
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

  /// 슬롯 로드 시 저장된 스냅샷으로 상태를 복원한다.
  Future<void> restoreFromSnapshot(MetaProgress snapshot) async {
    final storage = ref.read(localStorageProvider);
    await storage.setPlayerLevel(snapshot.level);
    await storage.setPlayerXp(snapshot.xp);
    await storage.setUnlockedCards(snapshot.unlockedCardTypes);
    state = snapshot;
  }

  /// 메타 진행 상태를 초기값으로 리셋한다.
  Future<void> reset() async {
    await ref.read(localStorageProvider).clear();
    state = MetaProgress.initial();
  }
}
