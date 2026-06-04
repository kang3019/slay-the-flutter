import 'package:flutter/material.dart';

import '../../../domain/entities/monster.dart';
import '../../shared/hp_bar_widget.dart';
import '../battle_constants.dart';

/// 몬스터의 이름·체력·다음 행동 의도·상태 이상을 표시한다.
class MonsterWidget extends StatelessWidget {
  final int hp;
  final int maxHp;
  final int block;
  final String name;
  final MonsterIntentType intentType;
  final String intentLabel;
  final String intentDescription;
  final int attackPower;
  final bool isVulnerable;
  final bool isWeak;

  const MonsterWidget({
    super.key,
    required this.hp,
    required this.maxHp,
    required this.block,
    required this.name,
    required this.intentType,
    required this.intentLabel,
    required this.intentDescription,
    required this.attackPower,
    required this.isVulnerable,
    required this.isWeak,
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
              if (isWeak)
                _StatusBadge(label: BattleStrings.weak, color: Colors.purple[700]!),
              if (isWeak && isVulnerable) const SizedBox(width: 4),
              if (isVulnerable)
                _StatusBadge(label: BattleStrings.vulnerable, color: Colors.orange[800]!),
            ],
          ),
          const SizedBox(height: 10),
          HpBarWidget(
            label: 'HP',
            current: hp,
            max: maxHp,
            barColor: Colors.red,
            block: block,
          ),
          const SizedBox(height: 10),
          _IntentRow(
            intentType: intentType,
            intentLabel: intentLabel,
            intentDescription: intentDescription,
            attackPower: attackPower,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }
}

class _IntentRow extends StatelessWidget {
  final MonsterIntentType intentType;
  final String intentLabel;
  final String intentDescription;
  final int attackPower;

  const _IntentRow({
    required this.intentType,
    required this.intentLabel,
    required this.intentDescription,
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

    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: Text(
            intentLabel,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          content: Text(
            intentDescription,
            style: const TextStyle(color: Colors.white70, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기', style: TextStyle(color: Colors.amber)),
            ),
          ],
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            suffix.isEmpty ? intentLabel : '$intentLabel $suffix',
            style: TextStyle(color: color, fontSize: 13),
          ),
          const SizedBox(width: 4),
          Icon(Icons.info_outline, color: color.withValues(alpha: 0.5), size: 13),
        ],
      ),
    );
  }
}
