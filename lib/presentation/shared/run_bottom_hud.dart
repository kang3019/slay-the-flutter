import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/run_provider.dart';
import '../../domain/entities/player.dart';
import 'map_overlay_sheet.dart';

/// 이벤트·강화 화면 하단에 고정되는 상태 HUD.
///
/// HP와 골드를 표시하고 지도 오버레이를 열 수 있다.
class RunBottomHud extends ConsumerWidget {
  const RunBottomHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (hp, gold, floor) = ref.watch(
      runProvider.select((s) => (s.playerHp, s.gold, s.floor)),
    );

    final hpRatio = hp / Player.maxHp;
    final hpColor = hpRatio > 0.5
        ? const Color(0xFF66BB6A)
        : hpRatio > 0.25
            ? const Color(0xFFFFB300)
            : const Color(0xFFEF5350);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF00D0A07),
        border: Border(
          top: BorderSide(color: Color(0xFF3D3020), width: 0.8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(Icons.favorite, size: 13, color: hpColor),
            const SizedBox(width: 5),
            Text(
              '$hp / ${Player.maxHp}',
              style: TextStyle(
                color: hpColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 20),
            const Icon(Icons.monetization_on,
                size: 13, color: Color(0xFFFFD700)),
            const SizedBox(width: 5),
            Text(
              '$gold G',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _showMapOverlay(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF3D3020),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map_outlined,
                        size: 14, color: Color(0xFFB8860B)),
                    const SizedBox(width: 6),
                    Text(
                      floor < 0 ? '지도' : '지도  ${floor + 1}F',
                      style: const TextStyle(
                        color: Color(0xFFB8860B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMapOverlay(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const MapOverlaySheet(),
    );
  }
}
