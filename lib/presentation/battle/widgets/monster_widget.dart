import 'package:flutter/material.dart';

import '../../../domain/entities/monster.dart';
import '../../shared/hp_bar_widget.dart';
import '../battle_constants.dart';

/// 몬스터의 이름·체력·다음 행동 의도·상태 이상을 표시한다.
class MonsterWidget extends StatelessWidget {
  final int hp;
  final int maxHp;
  final String name;
  final MonsterIntentType intentType;
  final String intentLabel;
  final int attackPower;
  final bool isVulnerable;

  const MonsterWidget({
    super.key,
    required this.hp,
    required this.maxHp,
    required this.name,
    required this.intentType,
    required this.intentLabel,
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
              Text(
                '👹 $name',
                style: const TextStyle(
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
          _IntentRow(
            intentType: intentType,
            intentLabel: intentLabel,
            attackPower: attackPower,
          ),
        ],
      ),
    );
  }
}

class _IntentRow extends StatelessWidget {
  final MonsterIntentType intentType;
  final String intentLabel;
  final int attackPower;

  const _IntentRow({
    required this.intentType,
    required this.intentLabel,
    required this.attackPower,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, suffix) = switch (intentType) {
      MonsterIntentType.attack       => (Icons.sports_martial_arts, Colors.redAccent, '$attackPower'),
      MonsterIntentType.attackDebuff => (Icons.sports_martial_arts, Colors.deepOrangeAccent, '$attackPower'),
      MonsterIntentType.defend       => (Icons.shield_outlined, Colors.blueAccent, ''),
      MonsterIntentType.buff         => (Icons.arrow_upward, Colors.amberAccent, ''),
      MonsterIntentType.sleep        => (Icons.bedtime_outlined, Colors.blueGrey, ''),
    };

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          suffix.isEmpty ? intentLabel : '$intentLabel $suffix',
          style: TextStyle(color: color, fontSize: 13),
        ),
      ],
    );
  }
}
