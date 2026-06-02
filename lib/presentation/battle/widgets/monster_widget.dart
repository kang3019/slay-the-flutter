import 'package:flutter/material.dart';

import '../../../domain/entities/monster_intent.dart';
import '../../../presentation/shared/hp_bar_widget.dart';
import '../battle_constants.dart';

/// 몬스터의 체력·인텐트(다음 행동 예고)·상태 이상을 표시한다.
class MonsterWidget extends StatelessWidget {
  final int hp;
  final int maxHp;
  final MonsterIntent intent;
  final bool isVulnerable;

  const MonsterWidget({
    super.key,
    required this.hp,
    required this.maxHp,
    required this.intent,
    required this.isVulnerable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BattleColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '👹 몬스터',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (isVulnerable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    BattleStrings.vulnerable,
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          HpBarWidget(
            label: 'HP',
            current: hp,
            max: maxHp,
            barColor: Colors.red,
          ),
          const SizedBox(height: 10),
          _IntentDisplay(intent: intent),
        ],
      ),
    );
  }
}

/// 몬스터의 다음 행동(인텐트)을 아이콘과 수치로 표시한다.
class _IntentDisplay extends StatelessWidget {
  final MonsterIntent intent;
  const _IntentDisplay({required this.intent});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = _intentVisuals(intent);
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          '$label: ${intent.value}',
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  (String icon, String label, Color color) _intentVisuals(MonsterIntent intent) {
    return switch (intent.type) {
      MonsterIntentType.attack     => ('⚔️', BattleStrings.intentAttack, Colors.redAccent),
      MonsterIntentType.heavyAttack => ('💥', BattleStrings.intentHeavyAttack, Colors.red[300]!),
      MonsterIntentType.gainBlock  => ('🛡️', BattleStrings.intentBlock, Colors.blueAccent),
    };
  }
}
