import 'dart:math';

import 'entities/card.dart';

/// 뽑는 더미·패·버리는 더미·소멸 더미의 상태와 이동 로직을 관리한다.
///
/// 순수 Dart 클래스 — Flutter·Riverpod 임포트 금지.
class Deck {
  final List<GameCard> _drawPile;
  final List<GameCard> _hand;
  final List<GameCard> _discardPile;

  /// 소멸(Exhaust)된 카드. 버리는 더미로 재활용되지 않는다.
  final List<GameCard> _exhaustPile;

  final Random _random;

  Deck({required List<GameCard> initialCards, Random? random})
      : _drawPile = List.of(initialCards),
        _hand = [],
        _discardPile = [],
        _exhaustPile = [],
        _random = random ?? Random();

  List<GameCard> get drawPile => List.unmodifiable(_drawPile);
  List<GameCard> get hand => List.unmodifiable(_hand);
  List<GameCard> get discardPile => List.unmodifiable(_discardPile);
  List<GameCard> get exhaustPile => List.unmodifiable(_exhaustPile);

  /// 소멸 더미를 제외한 총 카드 수.
  int get totalCards => _drawPile.length + _hand.length + _discardPile.length;

  void shuffle() => _drawPile.shuffle(_random);

  /// [count]장을 뽑는 더미에서 패로 이동한다.
  /// 뽑는 더미가 바닥나면 버리는 더미를 셔플해 뽑는 더미로 재활용한 뒤 계속 뽑는다.
  void draw(int count) {
    for (var i = 0; i < count; i++) {
      if (_drawPile.isEmpty) {
        if (_discardPile.isEmpty) break;
        _recycleDiscard();
      }
      _hand.add(_drawPile.removeLast());
    }
  }

  void _recycleDiscard() {
    _drawPile.addAll(_discardPile);
    _discardPile.clear();
    _drawPile.shuffle(_random);
  }

  /// 패에서 [card]를 꺼내 버리는 더미로 이동한다. 패에 없으면 false 반환.
  bool playCard(GameCard card) {
    final idx = _hand.indexOf(card);
    if (idx < 0) return false;
    _hand.removeAt(idx);
    _discardPile.add(card);
    return true;
  }

  /// 패 전체를 버리는 더미로 이동한다.
  void discardHand() {
    _discardPile.addAll(_hand);
    _hand.clear();
  }

  /// [card]를 버리는 더미에 직접 추가한다. 광분([CardType.rageBurst]) 복사본 생성에 사용된다.
  void addToDiscard(GameCard card) => _discardPile.add(card);

  /// [card]를 패에 직접 추가한다. 유물의 전투 시작 시 손패 지급에 사용된다.
  void addToHand(GameCard card) => _hand.add(card);

  /// 버리는 더미의 마지막 카드를 소멸 더미로 이동한다.
  /// Exhaust 카드([CardType.crushingBlow], [CardType.quickMend])의 효과 적용 직후 호출된다.
  void exhaustLastPlayed() {
    if (_discardPile.isNotEmpty) {
      _exhaustPile.add(_discardPile.removeLast());
    }
  }
}
