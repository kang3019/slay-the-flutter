import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/run_provider.dart';
import '../../domain/entities/player.dart';

/// 휴식처(🔥) 노드에서 HP 회복 또는 강화를 선택하는 화면.
///
/// 휴식: 최대 HP의 30%를 회복하고 맵으로 돌아간다.
class RestScreen extends ConsumerWidget {
  const RestScreen({super.key});

  static const double _healRatio = 0.3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerHp = ref.watch(runProvider.select((s) => s.playerHp));
    final notifier = ref.read(runProvider.notifier);

    final healAmount = (Player.maxHp * _healRatio).floor();
    final afterHp    = (playerHp + healAmount).clamp(0, Player.maxHp);
    final alreadyFull = playerHp >= Player.maxHp;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 태그 ─────────────────────────────────────────────────────
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1F0A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2E7D32)),
                  ),
                  child: const Text(
                    '🔥  휴식처',
                    style: TextStyle(
                      color: Color(0xFF81C784),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ── 모닥불 아이콘 ────────────────────────────────────────────
              const Center(
                child: Text('🔥', style: TextStyle(fontSize: 72)),
              ),

              const SizedBox(height: 24),

              // ── HP 상태 ──────────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Text(
                      'HP  $playerHp / ${Player.maxHp}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (!alreadyFull) ...[
                      const SizedBox(height: 6),
                      Text(
                        '휴식 후  $afterHp / ${Player.maxHp}  (+$healAmount)',
                        style: const TextStyle(
                          color: Color(0xFF81C784),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(),

              // ── 휴식 버튼 ─────────────────────────────────────────────────
              _OptionButton(
                icon: '❤️‍🔥',
                label: alreadyFull ? '휴식 (HP 최대)' : '휴식  (+$healAmount HP)',
                description: '최대 HP의 30%를 회복한다.',
                color: const Color(0xFF2E7D32),
                enabled: !alreadyFull,
                onTap: notifier.rest,
              ),

              const SizedBox(height: 12),

              // ── 강화 버튼 (미구현) ────────────────────────────────────────
              _OptionButton(
                icon: '⚒️',
                label: '강화  (준비 중)',
                description: '덱의 카드 1장을 업그레이드한다.',
                color: const Color(0xFF1A1A2E),
                enabled: false,
                onTap: () {},
              ),

              const SizedBox(height: 12),

              // ── 건너뛰기 ──────────────────────────────────────────────────
              GestureDetector(
                onTap: notifier.skipRest,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '그냥 지나친다',
                    style: TextStyle(color: Color(0xFF666666), fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String icon;
  final String label;
  final String description;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF333333),
            ),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFFA5D6A7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
