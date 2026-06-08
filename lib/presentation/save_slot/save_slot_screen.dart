import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/run_provider.dart';
import '../../application/save_slot_provider.dart';
import '../../domain/entities/save_slot.dart';

/// 세이브 슬롯 선택 화면 — 슬롯 3개를 카드 형태로 나열한다.
///
/// [onSlotLoaded]: 슬롯 로드 완료 후 호출되는 콜백 (맵 화면으로 이동 등).
class SaveSlotScreen extends ConsumerWidget {
  final VoidCallback? onSlotLoaded;

  const SaveSlotScreen({super.key, this.onSlotLoaded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(saveSlotProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        title: const Text(
          '세이브 슬롯',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: List.generate(
            slots.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _SlotCard(
                slotId: i + 1,
                slot: slots[i],
                onLoad: () async {
                  await ref
                      .read(saveSlotProvider.notifier)
                      .loadFromSlot(i + 1);
                  onSlotLoaded?.call();
                },
                onNewGame: () async {
                  ref.read(runProvider.notifier).startNewRun();
                  await ref
                      .read(saveSlotProvider.notifier)
                      .saveToSlot(i + 1);
                  onSlotLoaded?.call();
                },
                onSave: () =>
                    ref.read(saveSlotProvider.notifier).saveToSlot(i + 1),
                onDelete: () =>
                    ref.read(saveSlotProvider.notifier).deleteSlot(i + 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 슬롯 1개를 표현하는 카드 위젯.
class _SlotCard extends StatelessWidget {
  final int slotId;
  final SaveSlot? slot;
  final VoidCallback onLoad;
  final VoidCallback onNewGame;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  const _SlotCard({
    required this.slotId,
    required this.slot,
    required this.onLoad,
    required this.onNewGame,
    required this.onSave,
    required this.onDelete,
  });

  bool get _isEmpty => slot == null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isEmpty
              ? const Color(0xFF3D3020)
              : const Color(0xFFF59E0B),
          width: _isEmpty ? 1 : 1.5,
        ),
      ),
      child: Row(
        children: [
          // ── 슬롯 번호 아이콘 ─────────────────────────────────────
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isEmpty
                  ? const Color(0xFF252525)
                  : const Color(0xFF2A2A0A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$slotId',
                style: TextStyle(
                  color: _isEmpty
                      ? Colors.white38
                      : const Color(0xFFFFD700),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // ── 슬롯 정보 ────────────────────────────────────────────
          Expanded(
            child: _isEmpty
                ? const Text(
                    '빈 슬롯',
                    style: TextStyle(color: Colors.white38, fontSize: 15),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slot!.stageLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'HP ${slot!.runState.playerHp}  •  골드 ${slot!.runState.gold}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        slot!.savedAtLabel,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 8),
          // ── 버튼 영역 ─────────────────────────────────────────────
          if (_isEmpty)
            _ActionButton(
              label: '새 게임',
              color: const Color(0xFF4CAF50),
              onPressed: onNewGame,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ActionButton(
                  label: '이어하기',
                  color: const Color(0xFFF59E0B),
                  onPressed: onLoad,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      label: '덮어쓰기',
                      color: const Color(0xFF64B5F6),
                      onPressed: () =>
                          _confirmOverwrite(context),
                      small: true,
                    ),
                    const SizedBox(width: 6),
                    _ActionButton(
                      label: '삭제',
                      color: const Color(0xFFEF5350),
                      onPressed: () => _confirmDelete(context),
                      small: true,
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _confirmOverwrite(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          '덮어쓰기',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '기존 저장 데이터를 덮어씁니다.\n계속하시겠습니까?',
          style: TextStyle(color: Colors.white70, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onSave();
            },
            child: const Text(
              '덮어쓰기',
              style: TextStyle(
                  color: Color(0xFF64B5F6), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          '슬롯 삭제',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '저장된 데이터가 영구 삭제됩니다.\n계속하시겠습니까?',
          style: TextStyle(color: Colors.white70, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            child: const Text(
              '삭제',
              style: TextStyle(
                  color: Color(0xFFEF5350), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool small;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        side: BorderSide(color: color, width: 1),
        padding: small
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: small ? 11 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
