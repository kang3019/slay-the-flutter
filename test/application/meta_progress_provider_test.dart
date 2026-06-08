import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slay_the_flutter/application/meta_progress_provider.dart';
import 'package:slay_the_flutter/data/local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(LocalStorage(prefs)),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('MetaProgressNotifier 초기 상태', () {
    test('저장 데이터 없으면 레벨 1, XP 0', () {
      final state = container.read(metaProgressProvider);
      expect(state.level, equals(1));
      expect(state.xp, equals(0));
    });

    test('저장 데이터 없으면 strike, defend 해금', () {
      final state = container.read(metaProgressProvider);
      expect(state.unlockedCardTypes, containsAll(['strike', 'defend']));
    });

    test('저장된 값이 있으면 해당 값을 불러온다', () async {
      await prefs.setInt('meta_level', 3);
      await prefs.setInt('meta_xp', 300);
      await prefs.setString(
        'meta_unlocked_cards',
        '["strike","defend","rageBurst","quickMend","swiftCut","regroup"]',
      );

      final freshContainer = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(LocalStorage(prefs)),
        ],
      );
      addTearDown(freshContainer.dispose);

      final state = freshContainer.read(metaProgressProvider);
      expect(state.level, equals(3));
      expect(state.xp, equals(300));
      expect(state.unlockedCardTypes.length, equals(6));
    });
  });

  group('MetaProgressNotifier.addXp — 레벨업 없음', () {
    test('XP 50 추가 후 상태 반영', () async {
      await container.read(metaProgressProvider.notifier).addXp(50);

      final state = container.read(metaProgressProvider);
      expect(state.xp, equals(50));
      expect(state.level, equals(1));
    });

    test('레벨업 없으면 LevelUpResult.didLevelUp = false', () async {
      final result =
          await container.read(metaProgressProvider.notifier).addXp(50);
      expect(result.didLevelUp, isFalse);
      expect(result.newlyUnlockedCards, isEmpty);
    });
  });

  group('MetaProgressNotifier.addXp — 레벨업', () {
    test('레벨업 시 LevelUpResult.didLevelUp = true', () async {
      final result =
          await container.read(metaProgressProvider.notifier).addXp(100);

      expect(result.didLevelUp, isTrue);
      expect(result.newLevel, equals(2));
      expect(result.newlyUnlockedCards, containsAll(['rageBurst', 'quickMend']));
    });

    test('레벨업 후 provider 상태가 갱신된다', () async {
      await container.read(metaProgressProvider.notifier).addXp(100);

      final state = container.read(metaProgressProvider);
      expect(state.level, equals(2));
      expect(state.unlockedCardTypes, containsAll(['rageBurst', 'quickMend']));
    });
  });

  group('MetaProgressNotifier — 영속성', () {
    test('addXp 후 prefs에 xp가 저장된다', () async {
      await container.read(metaProgressProvider.notifier).addXp(100);

      expect(prefs.getInt('meta_xp'), equals(100));
    });

    test('addXp 레벨업 시 prefs에 level이 저장된다', () async {
      await container.read(metaProgressProvider.notifier).addXp(100);

      expect(prefs.getInt('meta_level'), equals(2));
    });

    test('addXp 레벨업 시 prefs에 unlocked_cards가 저장된다', () async {
      await container.read(metaProgressProvider.notifier).addXp(100);

      final storage = LocalStorage(prefs);
      expect(storage.unlockedCards, containsAll(['rageBurst', 'quickMend']));
    });
  });

  group('MetaProgressNotifier.reset', () {
    test('reset 후 레벨 1, XP 0으로 돌아간다', () async {
      await container.read(metaProgressProvider.notifier).addXp(200);
      await container.read(metaProgressProvider.notifier).reset();

      final state = container.read(metaProgressProvider);
      expect(state.level, equals(1));
      expect(state.xp, equals(0));
    });

    test('reset 후 해금 카드가 초기값으로 돌아간다', () async {
      await container.read(metaProgressProvider.notifier).addXp(250);
      await container.read(metaProgressProvider.notifier).reset();

      final state = container.read(metaProgressProvider);
      expect(state.unlockedCardTypes, containsAll(['strike', 'defend']));
      expect(state.unlockedCardTypes.length, equals(2));
    });
  });
}
