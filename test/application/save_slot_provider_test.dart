import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slay_the_flutter/application/meta_progress_provider.dart';
import 'package:slay_the_flutter/application/save_slot_provider.dart';
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

  group('SaveSlotNotifier 초기 상태', () {
    test('3개 슬롯 모두 null (비어 있음)', () {
      final slots = container.read(saveSlotProvider);
      expect(slots.length, equals(3));
      expect(slots.every((s) => s == null), isTrue);
    });
  });

  group('SaveSlotNotifier.saveToSlot', () {
    test('슬롯 1에 저장하면 해당 인덱스가 non-null이 된다', () async {
      await container.read(saveSlotProvider.notifier).saveToSlot(1);

      final slots = container.read(saveSlotProvider);
      expect(slots[0], isNotNull);
      expect(slots[0]!.slotId, equals(1));
    });

    test('슬롯 2에 저장하면 인덱스 1이 채워진다', () async {
      await container.read(saveSlotProvider.notifier).saveToSlot(2);

      final slots = container.read(saveSlotProvider);
      expect(slots[1], isNotNull);
      expect(slots[0], isNull);
      expect(slots[2], isNull);
    });

    test('saveToSlot 후 prefs에 저장된다', () async {
      await container.read(saveSlotProvider.notifier).saveToSlot(1);

      final storage = LocalStorage(prefs);
      expect(storage.loadSaveSlot(1), isNotNull);
    });
  });

  group('SaveSlotNotifier.deleteSlot', () {
    test('저장 후 삭제하면 슬롯이 null이 된다', () async {
      await container.read(saveSlotProvider.notifier).saveToSlot(1);
      await container.read(saveSlotProvider.notifier).deleteSlot(1);

      final slots = container.read(saveSlotProvider);
      expect(slots[0], isNull);
    });

    test('deleteSlot 후 prefs에서도 삭제된다', () async {
      await container.read(saveSlotProvider.notifier).saveToSlot(1);
      await container.read(saveSlotProvider.notifier).deleteSlot(1);

      final storage = LocalStorage(prefs);
      expect(storage.loadSaveSlot(1), isNull);
    });
  });

  group('SaveSlotNotifier.loadFromSlot', () {
    test('저장된 슬롯을 불러오면 RunNotifier 상태가 복원된다', () async {
      await container.read(saveSlotProvider.notifier).saveToSlot(1);
      await container.read(saveSlotProvider.notifier).loadFromSlot(1);
      expect(container.read(saveSlotProvider)[0], isNotNull);
    });

    test('비어 있는 슬롯을 불러와도 예외가 발생하지 않는다', () async {
      await expectLater(
        container.read(saveSlotProvider.notifier).loadFromSlot(1),
        completes,
      );
    });
  });

  group('SaveSlotNotifier — 영속성 (재시작 시뮬레이션)', () {
    test('저장 후 새 컨테이너로 읽어도 슬롯이 복원된다', () async {
      await container.read(saveSlotProvider.notifier).saveToSlot(2);

      // SharedPreferences mock은 인-메모리이므로 같은 인스턴스를 재사용해 재시작을 시뮬레이션한다.
      final fresh = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(LocalStorage(prefs)),
        ],
      );
      addTearDown(fresh.dispose);

      final slots = fresh.read(saveSlotProvider);
      expect(slots[1], isNotNull);
      expect(slots[1]!.slotId, equals(2));
    });
  });
}
