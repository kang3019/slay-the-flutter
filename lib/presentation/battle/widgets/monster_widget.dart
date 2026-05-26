import 'package:flutter/material.dart';

import '../../../presentation/shared/hp_bar_widget.dart';
import '../battle_constants.dart';

/// 몬스터의 체력·다음 공격·상태 이상을 표시한다.
class MonsterWidget extends StatelessWidget {
  final int hp;
  final int maxHp;
  final int attackPower;
  final bool isVulnerable;

  const MonsterWidget({
    super.key,
    required this.hp,
    required this.maxHp,
    required this.attackPower,
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
          Row(
            children: [
              const Icon(Icons.bolt, color: Colors.redAccent, size: 16),
              const SizedBox(width: 4),
              Text(
                '${BattleStrings.nextAttack}: $attackPower',
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
