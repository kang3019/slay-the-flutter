import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slay_the_flutter/data/local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalStorage 기본값 — 저장 데이터 없을 때', () {
    test('playerLevel 기본값 = 1', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs);
      expect(storage.playerLevel, equals(1));
    });

    test('playerXp 기본값 = 0', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs);
      expect(storage.playerXp, equals(0));
    });

    test('unlockedCards 기본값 = [strike, defend]', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs);
      expect(storage.unlockedCards, containsAll(['strike', 'defend']));
      expect(storage.unlockedCards.length, equals(2));
    });
  });

  group('LocalStorage 쓰기 후 읽기', () {
    test('setPlayerLevel 후 playerLevel 반영', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs);
      await storage.setPlayerLevel(3);
      expect(storage.playerLevel, equals(3));
    });

    test('setPlayerXp 후 playerXp 반영', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs);
      await storage.setPlayerXp(250);
      expect(storage.playerXp, equals(250));
    });

    test('setUnlockedCards 후 unlockedCards 반영', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs);
      await storage.setUnlockedCards(['strike', 'defend', 'bash', 'swiftCut']);
      final cards = storage.unlockedCards;
      expect(cards, containsAll(['strike', 'defend', 'bash', 'swiftCut']));
      expect(cards.length, equals(4));
    });

    test('여러 값을 동시에 저장하고 올바르게 읽는다', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs);
      await storage.setPlayerLevel(2);
      await storage.setPlayerXp(150);
      await storage.setUnlockedCards(['strike', 'defend', 'bash', 'swiftCut']);

      expect(storage.playerLevel, equals(2));
      expect(storage.playerXp, equals(150));
      expect(storage.unlockedCards.length, equals(4));
    });
  });

  group('LocalStorage.clear', () {
    test('clear 후 모든 값이 기본값으로 복구된다', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs);

      await storage.setPlayerLevel(4);
      await storage.setPlayerXp(500);
      await storage.setUnlockedCards(
        ['strike', 'defend', 'bash', 'swiftCut', 'ironWall', 'focus', 'recover'],
      );

      await storage.clear();

      expect(storage.playerLevel, equals(1));
      expect(storage.playerXp, equals(0));
      expect(storage.unlockedCards, containsAll(['strike', 'defend']));
      expect(storage.unlockedCards.length, equals(2));
    });
  });
}
