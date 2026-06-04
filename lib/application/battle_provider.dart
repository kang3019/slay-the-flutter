import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/battle_engine.dart';
import '../domain/entities/card.dart';
import '../domain/entities/monster.dart';
import '../domain/entities/player.dart';
import '../domain/entities/relic.dart';

/// BattleEngine 생성 팩토리 타입.
/// 테스트에서 overrideWith()로 교체해 결정론적 덱을 주입한다.
typedef BattleEngineFactory = BattleEngine Function(int stage, List<Relic> relics, List<GameCard> cards, int playerHp);

/// 프로덕션 기본 팩토리. BattleEngine.start()로 셔플된 정규 덱을 생성한다.
final battleEngineFactoryProvider = Provider<BattleEngineFactory>((ref) {
  return (stage, relics, cards, playerHp) => BattleEngine.start(stage: stage, relics: relics, cards: cards, playerHp: playerHp);
});

/// UI에 노출되는 전투 상태 스냅샷.
/// BattleEngine의 가변 상태를 불변 값 타입으로 투영한다.
class BattleState {
  final int playerHp;
  final int playerMaxHp;
  final int playerBlock;
  final bool playerIsVulnerable;
  final bool playerIsWeak;
  final int monsterHp;
  final int monsterMaxHp;
  final int monsterBlock;
  final bool monsterIsVulnerable;
  final bool monsterIsWeak;
  final int monsterAttackPower;
  final String monsterName;
  final MonsterIntentType monsterIntentType;
  final String monsterIntentLabel;
  final String monsterIntentDescription;
  final List<GameCard> hand;
  final int energy;
  final int maxEnergy;
  final bool isBattleOver;
  final BattleResult? result;
  final int stage;

  const BattleState({
    required this.playerHp,
    required this.playerMaxHp,
    required this.playerBlock,
    required this.playerIsVulnerable,
    required this.playerIsWeak,
    required this.monsterHp,
    required this.monsterMaxHp,
    required this.monsterBlock,
    required this.monsterIsVulnerable,
    required this.monsterIsWeak,
    required this.monsterAttackPower,
    required this.monsterName,
    required this.monsterIntentType,
    required this.monsterIntentLabel,
    required this.monsterIntentDescription,
    required this.hand,
    required this.energy,
    required this.maxEnergy,
    required this.isBattleOver,
    required this.stage,
    this.result,
  });
}

final battleProvider =
    NotifierProvider<BattleNotifier, BattleState>(BattleNotifier.new);

/// 전투 상태를 소유하고 UI 이벤트를 BattleEngine 호출로 위임한다.
class BattleNotifier extends Notifier<BattleState> {
  late BattleEngine _engine;

  @override
  BattleState build() {
    _engine = ref.read(battleEngineFactoryProvider)(1, const [], const [], Player.maxHp);
    return _fromEngine();
  }

  /// 패에서 카드를 사용한다. 에너지 부족·전투 종료 시 무시된다.
  void playCard(GameCard card) {
    _engine.playCard(card);
    state = _fromEngine();
  }

  /// 플레이어 턴을 종료한다.
  /// 내부 순서: 패 버림 → 몬스터 행동 → 블록 소멸 → 다음 플레이어 턴 시작.
  void endTurn() {
    _engine.endPlayerTurn();
    if (!_engine.isBattleOver) {
      _engine.startPlayerTurn();
    }
    state = _fromEngine();
  }

  /// 지정 스테이지로 새 전투를 시작한다.
  ///
  /// [relics]: 현재 런에서 보유한 유물 목록. 전투 시작 시 유물 효과가 자동 적용된다.
  /// [cards]: 현재 런의 덱. 비어있으면 기본 덱(강타5+방어5)을 사용한다.
  /// [playerHp]: 전투 시작 시 플레이어 HP.
  void startBattle(int stage, {List<Relic> relics = const [], List<GameCard> cards = const [], int playerHp = Player.maxHp}) {
    _engine = ref.read(battleEngineFactoryProvider)(stage, relics, cards, playerHp);
    state = _fromEngine();
  }

  BattleState _fromEngine() => BattleState(
        playerHp: _engine.player.hp,
        playerMaxHp: Player.maxHp,
        playerBlock: _engine.player.block,
        playerIsVulnerable: _engine.player.isVulnerable,
        playerIsWeak: _engine.player.isWeak,
        monsterHp: _engine.monster.hp,
        monsterMaxHp: _engine.monster.maxHp,
        monsterBlock: _engine.monster.block,
        monsterIsVulnerable: _engine.monster.isVulnerable,
        monsterIsWeak: _engine.monster.isWeak,
        monsterAttackPower: _engine.monster.attackPower,
        monsterName: _engine.monster.name,
        monsterIntentType: _engine.monster.currentIntent.intentType,
        monsterIntentLabel: _engine.monster.currentIntent.label,
        monsterIntentDescription: _engine.monster.currentIntent.description,
        hand: List.of(_engine.deck.hand),
        energy: _engine.energy,
        maxEnergy: BattleEngine.energyPerTurn,
        isBattleOver: _engine.isBattleOver,
        result: _engine.result,
        stage: _engine.monster.stage,
      );
}
