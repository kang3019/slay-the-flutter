import 'package:flutter/material.dart';

import '../../domain/entities/relic.dart';

/// 엘리트 처치·보스 승리 시 자동 지급된 유물을 알리는 뱃지.
///
/// 골드 보상과 달리 [RunNotifier]가 이미 [RunState.relics]에 추가한 뒤이므로
/// 탭 동작 없이 결과만 표시한다. [RewardScreen]·[RunEndScreen]에서 공용으로 쓰인다.
class RelicRewardBadge extends StatelessWidget {
  const RelicRewardBadge({super.key, required this.relic});

  final Relic relic;

  static const _accent = Color(0xFFCE93D8);
  static const _label = '신규 유물 획득';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: _accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_label: ${relic.name}',
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  relic.description,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
