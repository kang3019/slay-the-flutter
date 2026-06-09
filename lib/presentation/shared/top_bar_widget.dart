import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/run_provider.dart';
import '../../domain/entities/player.dart';

/// 보상·이벤트·상점·휴식 화면 상단에 고정되는 글로벌 상태 표시줄.
///
/// 층수·HP·골드를 표시한다. 지도·전투·런종료 화면에서는 [AppRouter]가 표시하지 않는다.
class TopBarWidget extends ConsumerWidget {
  const TopBarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (floor, hp, gold) = ref.watch(
      runProvider.select((s) => (s.floor, s.playerHp, s.gold)),
    );

    final floorLabel = floor < 0 ? '시작' : '${floor + 1}F';

    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xD90D0A07),
        border: Border(
          bottom: BorderSide(color: Color(0xFF3D3020), width: 0.8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.layers_outlined, size: 13, color: Color(0xFFB8860B)),
          const SizedBox(width: 5),
          Text(
            floorLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          const Icon(Icons.favorite, size: 13, color: Color(0xFFEF5350)),
          const SizedBox(width: 5),
          Text(
            '$hp / ${Player.maxHp}',
            style: TextStyle(
              color: hp <= Player.maxHp * 0.3
                  ? const Color(0xFFEF5350)
                  : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const Icon(Icons.monetization_on, size: 13, color: Color(0xFFFFD700)),
          const SizedBox(width: 5),
          Text(
            '$gold G',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
