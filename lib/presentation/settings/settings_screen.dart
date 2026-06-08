import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/meta_progress_provider.dart';
import '../../application/run_provider.dart';

/// 게임 설정 화면 — 메타 진행 초기화 기능을 제공한다.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(metaProgressProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        title: const Text(
          '설정',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 현재 진행 상황 ─────────────────────────────────────
            _SectionHeader(title: '현재 메타 진행'),
            const SizedBox(height: 12),
            _ProgressCard(
              level: progress.level,
              xp: progress.xp,
              xpForNext: progress.xpForNextLevel,
              isMaxLevel: progress.isMaxLevel,
              unlockedCount: progress.unlockedCardTypes.length,
            ),
            const SizedBox(height: 32),
            // ── 진행 초기화 ────────────────────────────────────────
            _SectionHeader(title: '진행 초기화'),
            const SizedBox(height: 12),
            _ResetButton(
              onConfirmed: () async {
                await ref.read(metaProgressProvider.notifier).reset();
                ref.read(runProvider.notifier).startNewRun();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFF59E0B),
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int level;
  final int xp;
  final int xpForNext;
  final bool isMaxLevel;
  final int unlockedCount;

  const _ProgressCard({
    required this.level,
    required this.xp,
    required this.xpForNext,
    required this.isMaxLevel,
    required this.unlockedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3D3020)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
              const SizedBox(width: 8),
              Text(
                'Lv.$level',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                isMaxLevel ? 'MAX' : '$xp / $xpForNext XP',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
          if (!isMaxLevel) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (xp / xpForNext).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: const Color(0xFF333333),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            '해금된 카드: $unlockedCount종',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// 진행 초기화 버튼 — 탭 시 확인 다이얼로그를 표시한다.
///
/// 다이얼로그는 Presentation 계층에서만 처리.
/// BuildContext를 Notifier에 넘기지 않는다.
class _ResetButton extends StatelessWidget {
  final VoidCallback onConfirmed;
  const _ResetButton({required this.onConfirmed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showConfirmDialog(context),
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('진행 초기화'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEF5350),
          side: const BorderSide(color: Color(0xFFEF5350)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          '진행 초기화',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '모든 레벨·해금 카드가 초기화됩니다.\n계속하시겠습니까?',
          style: TextStyle(color: Colors.white70, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
                const Text('취소', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirmed();
            },
            child: const Text(
              '초기화',
              style: TextStyle(
                  color: Color(0xFFEF5350), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
