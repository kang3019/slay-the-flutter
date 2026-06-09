import 'package:flutter_test/flutter_test.dart';
import 'package:slay_the_flutter/application/run_provider.dart';
import 'package:slay_the_flutter/domain/entities/card.dart';
import 'package:slay_the_flutter/domain/entities/meta_progress.dart';
import 'package:slay_the_flutter/domain/entities/player.dart';
import 'package:slay_the_flutter/domain/entities/save_slot.dart';
import 'package:slay_the_flutter/domain/map/map_generator.dart';

RunState _makeMinimalRunState() => RunState(
      phase: RunPhase.map,
      floor: 1,
      playerHp: Player.maxHp,
      gold: 30,
      deck: const [Cards.strike, Cards.defend],
      mapNodes: MapGenerator.generateAct1(),
      currentNodeId: null,
      visitedNodeIds: const [],
      isRunOver: false,
      rewardCards: const [],
    );

void main() {
  group('SaveSlot 생성', () {
    test('slotId 1~3 유효', () {
      final state = _makeMinimalRunState();
      final savedAt = DateTime(2026, 6, 7, 12);
      final slot = SaveSlot(
        slotId: 1,
        runState: state,
        metaProgress: MetaProgress.initial(),
        savedAt: savedAt,
      );

      expect(slot.slotId, equals(1));
      expect(slot.runState.floor, equals(1));
      expect(slot.savedAt, equals(savedAt));
    });
  });

  group('SaveSlot JSON 직렬화 왕복', () {
    test('toJson/fromJson 왕복 — slotId 보존', () {
      final slot = SaveSlot(
        slotId: 2,
        runState: _makeMinimalRunState(),
        metaProgress: MetaProgress.initial(),
        savedAt: DateTime(2026, 6, 7),
      );

      final restored = SaveSlot.fromJson(slot.toJson());
      expect(restored.slotId, equals(2));
    });

    test('toJson/fromJson 왕복 — savedAt 보존', () {
      final savedAt = DateTime(2026, 1, 15, 9, 30);
      final slot = SaveSlot(
        slotId: 1,
        runState: _makeMinimalRunState(),
        metaProgress: MetaProgress.initial(),
        savedAt: savedAt,
      );

      final restored = SaveSlot.fromJson(slot.toJson());
      expect(restored.savedAt, equals(savedAt));
    });

    test('toJson/fromJson 왕복 — RunState.floor 보존', () {
      final state = _makeMinimalRunState();
      final slot  = SaveSlot(
        slotId: 3,
        runState: state,
        metaProgress: MetaProgress.initial(),
        savedAt: DateTime.now(),
      );

      final restored = SaveSlot.fromJson(slot.toJson());
      expect(restored.runState.floor, equals(state.floor));
    });

    test('toJson/fromJson 왕복 — RunState.playerHp 보존', () {
      final slot = SaveSlot(
        slotId: 1,
        runState: _makeMinimalRunState(),
        metaProgress: MetaProgress.initial(),
        savedAt: DateTime.now(),
      );

      final restored = SaveSlot.fromJson(slot.toJson());
      expect(restored.runState.playerHp, equals(Player.maxHp));
    });

    test('toJson/fromJson 왕복 — RunState.gold 보존', () {
      final slot = SaveSlot(
        slotId: 1,
        runState: _makeMinimalRunState(),
        metaProgress: MetaProgress.initial(),
        savedAt: DateTime.now(),
      );

      final restored = SaveSlot.fromJson(slot.toJson());
      expect(restored.runState.gold, equals(30));
    });

    test('toJson/fromJson 왕복 — deck 카드 종류 보존', () {
      final slot = SaveSlot(
        slotId: 1,
        runState: _makeMinimalRunState(),
        metaProgress: MetaProgress.initial(),
        savedAt: DateTime.now(),
      );

      final restored = SaveSlot.fromJson(slot.toJson());
      expect(restored.runState.deck.length, equals(2));
      expect(restored.runState.deck.first.type, equals(CardType.strike));
    });

    test('toJson/fromJson 왕복 — metaProgress 보존', () {
      const meta = MetaProgress(level: 3, xp: 300, unlockedCardTypes: ['strike', 'defend', 'swiftCut']);
      final slot = SaveSlot(
        slotId: 1,
        runState: _makeMinimalRunState(),
        metaProgress: meta,
        savedAt: DateTime.now(),
      );

      final restored = SaveSlot.fromJson(slot.toJson());
      expect(restored.metaProgress.level, equals(3));
      expect(restored.metaProgress.xp, equals(300));
      expect(restored.metaProgress.unlockedCardTypes, contains('swiftCut'));
    });

    test('metaProgress 키 없는 구버전 JSON은 초기값으로 복원된다', () {
      final slot = SaveSlot(
        slotId: 1,
        runState: _makeMinimalRunState(),
        metaProgress: MetaProgress.initial(),
        savedAt: DateTime.now(),
      );
      final json = slot.toJson()..remove('metaProgress');

      final restored = SaveSlot.fromJson(json);
      expect(restored.metaProgress.level, equals(1));
      expect(restored.metaProgress.xp, equals(0));
    });
  });

  group('SaveSlot 표시 정보', () {
    test('savedAtLabel은 날짜 문자열을 반환한다', () {
      final slot = SaveSlot(
        slotId: 1,
        runState: _makeMinimalRunState(),
        metaProgress: MetaProgress.initial(),
        savedAt: DateTime(2026, 6, 7, 14, 30),
      );
      expect(slot.savedAtLabel, isA<String>());
      expect(slot.savedAtLabel, isNotEmpty);
    });

    test('stageLabel은 현재 층 정보를 반환한다', () {
      final slot = SaveSlot(
        slotId: 1,
        runState: _makeMinimalRunState(), // floor: 1 → "Floor 2"
        metaProgress: MetaProgress.initial(),
        savedAt: DateTime.now(),
      );
      expect(slot.stageLabel, contains('Floor'));
      expect(slot.stageLabel, contains('2'));
    });
  });
}
