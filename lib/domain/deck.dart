import 'dart:math';

import 'entities/card.dart';

/// 뽑는 더미·패·버리는 더미의 상태와 이동 로직을 관리한다.
///
/// 순수 Dart 클래스 — Flutter·Riverpod 임포트 금지.
class Deck {
  final List<GameCard> _drawPile;
  final List<GameCard> _hand;
  final List<GameCard> _discardPile;
  final Random _random;

  Deck({required List<GameCard> initialCards, Random? random})
      : _drawPile = List.of(initialCards),
        _hand = [],
        _discardPile = [],
        _random = random ?? Random();

  List<GameCard> get drawPile => List.unmodifiable(_drawPile);
  List<GameCard> get hand => List.unmodifiable(_hand);
  List<GameCard> get discardPile => List.unmodifiable(_discardPile);

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
}
