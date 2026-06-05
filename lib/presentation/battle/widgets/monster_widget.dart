import 'package:flutter/material.dart';

import '../../../domain/entities/monster_intent.dart';
import '../../../presentation/shared/hp_bar_widget.dart';
import '../battle_constants.dart';

/// 몬스터의 실루엣 플레이스홀더, HP·방어도, 다음 행동(인텐트), 상태 이상을 표시한다.
class MonsterWidget extends StatelessWidget {
  final int hp;
  final int maxHp;
  final int block;
  final MonsterIntent intent;
  final bool isVulnerable;

  const MonsterWidget({
    super.key,
    required this.hp,
    required this.maxHp,
    required this.intent,
    required this.isVulnerable,
    this.block = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BattleColors.panelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BattleColors.panelBorder),
      ),
      child: Column(
        children: [
          // ── 실루엣 영역 ───────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                // 몬스터 이미지 자리 (추후 Image.asset으로 교체)
                const Center(
                  child: Icon(
                    Icons.person,
                    size: 90,
                    color: Color(0x18FFFFFF),
                  ),
                ),

                // ── 상태 이상 배지 (우상단) ───────────────────────────
                if (isVulnerable)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _StatusChip(
                      label: BattleStrings.vulnerable,
                      icon: Icons.water_drop,
                      color: const Color(0xFFE65100),
                    ),
                  ),

                // ── 인텐트 배너 (하단 중앙) ──────────────────────────
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(child: _IntentBanner(intent: intent)),
                ),
              ],
            ),
          ),

          // ── HP 바 ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: HpBarWidget(
              label: BattleStrings.hp,
              current: hp,
              max: maxHp,
              barColor: BattleColors.monsterHpBar,
              block: block,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 비공개 서브위젯 ──────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _StatusChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 3),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _IntentBanner extends StatelessWidget {
  final MonsterIntent intent;
  const _IntentBanner({required this.intent});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = _intentVisuals(intent.type);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              '$label  ${intent.value}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData icon, String label, Color color) _intentVisuals(
    MonsterIntentType type,
  ) => switch (type) {
        MonsterIntentType.attack     => (Icons.flash_on, BattleStrings.intentAttack, const Color(0xFFC62828)),
        MonsterIntentType.heavyAttack => (Icons.whatshot, BattleStrings.intentHeavyAttack, const Color(0xFFB71C1C)),
        MonsterIntentType.gainBlock  => (Icons.shield, BattleStrings.intentBlock, const Color(0xFF1565C0)),
      };
}
