import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/run_provider.dart';
import '../../domain/entities/relic.dart';

/// 유물 보관소(🏺) 노드에서 유물을 보여주는 화면.
///
/// [RunState.currentTreasureRelic]을 표시하고, 획득 버튼을 탭하면
/// [RunNotifier.takeTreasure]를 호출해 유물을 보유 목록에 추가한 뒤 맵으로 돌아간다.
class TreasureScreen extends ConsumerWidget {
  const TreasureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relic    = ref.watch(runProvider.select((s) => s.currentTreasureRelic));
    final notifier = ref.read(runProvider.notifier);

    if (relic == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
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
                    color: const Color(0xFF1A1500),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF7A6500)),
                  ),
                  child: const Text(
                    '🏺  유물 보관소',
                    style: TextStyle(
                      color: Color(0xFFFDD835),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ── 유물 카드 ──────────────────────────────────────────────────
              Center(child: _RelicCard(relic: relic)),

              const Spacer(),

              // ── 획득 버튼 ─────────────────────────────────────────────────
              _ActionButton(
                label: '획득',
                color: const Color(0xFFFDD835),
                textColor: const Color(0xFF1A1500),
                onTap: notifier.takeTreasure,
              ),

              const SizedBox(height: 12),

              // ── 건너뛰기 버튼 ─────────────────────────────────────────────
              _ActionButton(
                label: '건너뛰기',
                color: const Color(0xFF1E1E2E),
                textColor: const Color(0xFF888899),
                onTap: notifier.skipTreasure,
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// _RelicCard
// ──────────────────────────────────────────────────────────────────────────

class _RelicCard extends StatelessWidget {
  final Relic relic;

  const _RelicCard({required this.relic});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1500),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFDD835), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFDD835).withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏺', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            relic.name,
            style: const TextStyle(
              color: Color(0xFFFDD835),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            relic.description,
            style: const TextStyle(
              color: Color(0xFFD4C080),
              fontSize: 14,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// _ActionButton
// ──────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
