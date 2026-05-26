import 'package:flutter_test/flutter_test.dart';
import 'package:slay_the_flutter/domain/deck.dart';
import 'package:slay_the_flutter/domain/entities/card.dart';

void main() {
  group('Deck 초기 상태', () {
    test('모든 카드가 뽑는 더미에 있다', () {
      final deck = Deck(initialCards: [Cards.strike, Cards.defend]);
      expect(deck.drawPile.length, equals(2));
      expect(deck.hand, isEmpty);
      expect(deck.discardPile, isEmpty);
    });

    test('totalCards는 초기 카드 수와 같다', () {
      final deck = Deck(initialCards: List.filled(10, Cards.strike));
      expect(deck.totalCards, equals(10));
    });
  });

  group('드로우 (draw)', () {
    test('draw(n)은 n장을 뽑는 더미에서 패로 이동한다', () {
      final deck = Deck(initialCards: List.filled(10, Cards.strike));
      deck.draw(5);
      expect(deck.hand.length, equals(5));
      expect(deck.drawPile.length, equals(5));
    });

    test('totalCards는 드로우 후에도 보존된다', () {
      final deck = Deck(initialCards: List.filled(10, Cards.strike));
      deck.draw(5);
      expect(deck.totalCards, equals(10));
    });

    test('뽑는 더미가 비었을 때 버리는 더미가 셔플되어 뽑는 더미로 이동한다', () {
      final deck = Deck(initialCards: [Cards.strike, Cards.defend, Cards.strike]);

      // 3장 전부 드로우 → 뽑는 더미 소진
      deck.draw(3);
      expect(deck.drawPile, isEmpty);

      // 3장 전부 플레이 → 버리는 더미로
      deck.playCard(Cards.strike);
      deck.playCard(Cards.strike);
      deck.playCard(Cards.defend);
      expect(deck.discardPile.length, equals(3));
      expect(deck.hand, isEmpty);

      // 1장 드로우 → 버리는 더미가 뽑는 더미로 재활용됨
      deck.draw(1);
      expect(deck.hand.length, equals(1));
      expect(deck.discardPile, isEmpty);
      expect(deck.drawPile.length, equals(2)); // 재활용 3장 - 드로우 1장
    });

    test('totalCards는 재활용 후에도 보존된다', () {
      final deck = Deck(initialCards: [Cards.strike, Cards.defend]);
      deck.draw(2);
      deck.playCard(Cards.strike);
      deck.playCard(Cards.defend);
      deck.draw(1);
      expect(deck.totalCards, equals(2));
    });

    test('뽑는 더미와 버리는 더미 모두 비었으면 그 이상 뽑지 않는다', () {
      final deck = Deck(initialCards: [Cards.strike]);
      deck.draw(1); // 1장 드로우
      expect(deck.hand.length, equals(1));

      deck.draw(1); // 더 이상 뽑을 카드 없음
      expect(deck.hand.length, equals(1));
      expect(deck.totalCards, equals(1));
    });
  });

  group('카드 플레이 (playCard)', () {
    test('패의 카드를 플레이하면 버리는 더미로 이동한다', () {
      final deck = Deck(initialCards: [Cards.strike]);
      deck.draw(1);

      deck.playCard(Cards.strike);
      expect(deck.hand, isEmpty);
      expect(deck.discardPile.length, equals(1));
    });

    test('패에 없는 카드를 플레이하면 false를 반환한다', () {
      final deck = Deck(initialCards: [Cards.defend]);
      deck.draw(1);

      final result = deck.playCard(Cards.strike); // 패에 Strike 없음
      expect(result, isFalse);
      expect(deck.hand.length, equals(1)); // 패 변화 없음
    });

    test('totalCards는 playCard 후에도 보존된다', () {
      final deck = Deck(initialCards: [Cards.strike, Cards.defend]);
      deck.draw(2);
      deck.playCard(Cards.strike);
      expect(deck.totalCards, equals(2));
    });
  });

  group('패 전체 버리기 (discardHand)', () {
    test('패의 모든 카드가 버리는 더미로 이동한다', () {
      final deck = Deck(initialCards: List.filled(5, Cards.strike));
      deck.draw(5);
      deck.discardHand();
      expect(deck.hand, isEmpty);
      expect(deck.discardPile.length, equals(5));
    });

    test('totalCards는 discardHand 후에도 보존된다', () {
      final deck = Deck(initialCards: List.filled(5, Cards.strike));
      deck.draw(5);
      deck.discardHand();
      expect(deck.totalCards, equals(5));
    });
  });
}
