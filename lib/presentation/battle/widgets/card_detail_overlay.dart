import 'package:flutter/material.dart';

import '../../../domain/entities/card.dart';
import '../battle_constants.dart';

/// 카드를 꾹 눌렀을 때 화면 중앙에 표시되는 확대 상세 오버레이.
///
/// OverlayEntry로 주입되어 모든 UI 위에 렌더링된다.
/// [onDismiss]가 제공되면 오버레이 어디를 탭해도 닫힌다.
class CardDetailOverlay extends StatelessWidget {
  final GameCard card;
  final VoidCallback? onDismiss;
  const CardDetailOverlay({super.key, required this.card, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final typeColor = BattleColors.forCard(card.effectType);
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox.expand(child: ColoredBox(color: Color(0xAA000000))),
            _BigCard(card: card, typeColor: typeColor),
          ],
        ),
      ),
    );
  }
}

// ─── 비공개 서브위젯 ──────────────────────────────────────────────────────────

class _BigCard extends StatelessWidget {
  final GameCard card;
  final Color typeColor;

  static const double _width  = 200.0;
  static const double _height = 292.0;

  const _BigCard({required this.card, required this.typeColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C2418), Color(0xFF12100A)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: typeColor, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: typeColor.withValues(alpha: 0.7),
              blurRadius: 30,
              spreadRadius: 6,
            ),
          ],
        ),
        child: Column(
          children: [
            _BigHeader(cost: card.cost, typeColor: typeColor),
            Expanded(child: _BigArt(type: card.type, typeColor: typeColor)),
            _BigFooter(card: card),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _BigHeader extends StatelessWidget {
  final int cost;
  final Color typeColor;
  const _BigHeader({required this.cost, required this.typeColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1A1410)),
            child: Center(
              child: Text(
                '$cost',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const Spacer(),
          const Text('COST', style: TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}

class _BigArt extends StatelessWidget {
  final CardType type;
  final Color typeColor;
  const _BigArt({required this.type, required this.typeColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: typeColor.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Icon(_artIcon, size: 72, color: typeColor.withValues(alpha: 0.85)),
      ),
    );
  }

  IconData get _artIcon => switch (type) {
        CardType.strike          => Icons.sports_martial_arts,
        CardType.bash            => Icons.fitness_center,
        CardType.swiftCut        => Icons.air,
        CardType.defend          => Icons.shield_outlined,
        CardType.ironWall        => Icons.security,
        CardType.focus           => Icons.visibility,
        CardType.recover         => Icons.healing,
        CardType.rageBurst       => Icons.flash_on,
        CardType.toxicJab        => Icons.science,
        CardType.regroup         => Icons.refresh,
        CardType.crushingBlow    => Icons.broken_image,
        CardType.fury            => Icons.local_fire_department,
        CardType.tripleSlash     => Icons.content_cut,
        CardType.quickMend       => Icons.favorite,
        CardType.swiftGuard      => Icons.shield,
        CardType.exploitWeakness => Icons.arrow_downward,
        CardType.sharpen         => Icons.auto_fix_high,
        CardType.weakSlash       => Icons.exposure_minus_1,
        CardType.blockStrike     => Icons.security_update_good,
        CardType.bloodRush       => Icons.bloodtype,
        CardType.devilsDeal      => Icons.dangerous,
        CardType.battleCry       => Icons.campaign,
        CardType.indomitable     => Icons.castle,
        CardType.comboStrike     => Icons.repeat,
        CardType.gamble          => Icons.casino,
        CardType.poisonDart      => Icons.pest_control,
      };
}

class _BigFooter extends StatelessWidget {
  final GameCard card;
  const _BigFooter({required this.card});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          Text(
            card.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _fullDesc,
            style: const TextStyle(color: Color(0xFFB0A070), fontSize: 12, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String get _fullDesc => switch (card.type) {
        CardType.strike          => '적에게 ${card.value}의 피해를 입힙니다.',
        CardType.bash            => '적에게 ${card.value}의 피해를 입히고\n2턴 동안 취약 상태로 만듭니다.',
        CardType.swiftCut        => '적에게 ${card.value}의 피해를\n2회 연속으로 입힙니다.',
        CardType.defend          => '방어도를 ${card.value} 획득합니다.',
        CardType.ironWall        => '방어도를 ${card.value} 획득합니다.',
        CardType.focus           => '다음에 사용하는 카드의\n효과가 ${card.value}% 증가합니다.',
        CardType.recover         => 'HP를 ${card.value} 회복합니다.',
        CardType.rageBurst       => '적에게 ${card.value}의 피해를 입힙니다.\n사용 후 복사본이 버리는 더미에 추가됩니다.',
        CardType.toxicJab        => '${card.value} 데미지 + 취약 ${card.isUpgraded ? 3 : 2}턴',
        CardType.regroup         => '카드 ${card.value}장 드로우',
        CardType.crushingBlow    => '적에게 ${card.value}의 피해를 입힙니다.\n사용 후 이 카드는 덱에서 영구 제거됩니다.',
        CardType.fury            => '힘을 ${card.value} 올립니다. (전투 내내 지속)',
        CardType.tripleSlash     => '적에게 ${card.value}의 피해를\n3회 연속으로 입힙니다.',
        CardType.quickMend       => 'HP를 ${card.value} 회복합니다.\n사용 후 이 카드는 덱에서 영구 제거됩니다.',
        CardType.swiftGuard      => '방어도를 ${card.value} 획득하고\n카드를 1장 드로우합니다.',
        CardType.exploitWeakness => '적에게 ${card.value}의 피해를 입힙니다.\n적이 취약 상태면 +${card.isUpgraded ? 9 : 6} 추가 피해.',
        CardType.sharpen         => '이번 턴에 사용하는\n공격 카드 전부에 +${card.value} 데미지.',
        CardType.weakSlash       => '${card.value} 데미지 + 약화 ${card.isUpgraded ? 3 : 2}턴',
        CardType.blockStrike     => card.isUpgraded
            ? '현재 방어도의 1.5배만큼 데미지를 입힙니다.'
            : '현재 방어도만큼 데미지를 입힙니다.',
        CardType.bloodRush       => '남은 에너지를 모두 소모해\nX×${card.value}의 피해를 입힙니다.',
        CardType.devilsDeal      => 'HP를 ${card.value} 잃고\n카드를 3장 드로우합니다.',
        CardType.battleCry       => '카드 2장 드로우 + 힘 +${card.isUpgraded ? 2 : 1}.\n사용 후 이 카드는 덱에서 영구 제거됩니다.',
        CardType.indomitable     => '방어도를 (${card.value} + 현재 힘) 획득합니다.',
        CardType.comboStrike     => '현재 손패의 공격 카드 수 × ${card.value}의\n피해를 입힙니다.',
        CardType.gamble          => 'HP를 ${card.value} 잃고 에너지를 2 획득합니다.',
        CardType.poisonDart      => '적에게 ${card.value}의 피해를 입히고\n독 ${card.isUpgraded ? 5 : 3}스택을 부여합니다.',
      };
}
