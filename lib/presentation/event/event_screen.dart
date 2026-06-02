import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/run_provider.dart';
import '../../domain/events/game_event.dart';
import 'event_constants.dart';

/// 이벤트 노드(❓)에서 텍스트 이벤트와 선택지를 보여주는 화면.
///
/// 선택지를 탭하면 결과 화면으로 전환되고, "계속" 버튼을 누르면
/// [RunNotifier.resolveEvent]를 호출해 효과를 적용한 뒤 맵으로 돌아간다.
class EventScreen extends ConsumerStatefulWidget {
  const EventScreen({super.key});

  @override
  ConsumerState<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends ConsumerState<EventScreen> {
  /// null = 선택 전(선택지 표시), non-null = 선택 후(결과 표시).
  EventChoice? _selectedChoice;

  @override
  Widget build(BuildContext context) {
    final event    = ref.watch(runProvider.select((s) => s.currentEvent));
    final notifier = ref.read(runProvider.notifier);

    if (event == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D26),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: _selectedChoice == null
              ? _ChoiceView(
                  event: event,
                  onChoiceSelected: (choice) =>
                      setState(() => _selectedChoice = choice),
                )
              : _ResultView(
                  choice: _selectedChoice!,
                  onContinue: () => notifier.resolveEvent(_selectedChoice!),
                ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// _ChoiceView — 선택지 목록
// ──────────────────────────────────────────────────────────────────────────

class _ChoiceView extends StatelessWidget {
  final GameEvent event;
  final ValueChanged<EventChoice> onChoiceSelected;

  const _ChoiceView({required this.event, required this.onChoiceSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 태그 ───────────────────────────────────────────────────────────
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A3E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4A4A8A)),
            ),
            child: const Text(
              EventConstants.screenTag,
              style: TextStyle(
                color: Color(0xFFA78BFA),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // ── 이벤트 제목 ─────────────────────────────────────────────────────
        Text(
          event.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // ── 이벤트 설명 ─────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF161638),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2C2C68)),
          ),
          child: Text(
            event.description,
            style: const TextStyle(
              color: Color(0xFFB0B0D8),
              fontSize: 16,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const Spacer(),

        // ── 선택지 버튼들 ──────────────────────────────────────────────────
        ...event.choices.map(
          (choice) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ChoiceButton(
              choice: choice,
              onTap: () => onChoiceSelected(choice),
            ),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// _ResultView — 선택 결과
// ──────────────────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final EventChoice choice;
  final VoidCallback onContinue;

  const _ResultView({required this.choice, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final effect = choice.effect;
    final items  = _buildResultItems(effect);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 태그 ───────────────────────────────────────────────────────────
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A3E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4A4A8A)),
            ),
            child: const Text(
              EventConstants.resultTag,
              style: TextStyle(
                color: Color(0xFFA78BFA),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // ── 선택한 선택지 ──────────────────────────────────────────────────
        Text(
          '▶  ${choice.label}',
          style: const TextStyle(
            color: Color(0xFFA78BFA),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // ── 결과 항목들 ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161638),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2C2C68)),
          ),
          child: items.isEmpty
              ? const Text(
                  '아무 일도 일어나지 않았다.',
                  style: TextStyle(color: Color(0xFFB0B0D8), fontSize: 15),
                  textAlign: TextAlign.center,
                )
              : Column(
                  children: items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: item,
                        ),
                      )
                      .toList(),
                ),
        ),

        const Spacer(),

        // ── 계속 버튼 ──────────────────────────────────────────────────────
        GestureDetector(
          onTap: onContinue,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF4A4A8A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              EventConstants.continueLabel,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  List<Widget> _buildResultItems(EventEffect effect) {
    final items = <Widget>[];

    if (effect.hpDelta != 0) {
      final isGain = effect.hpDelta > 0;
      items.add(_ResultItem(
        icon: isGain ? '❤️' : '💔',
        text: 'HP ${isGain ? '+' : ''}${effect.hpDelta}',
        color: isGain ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
      ));
    }

    if (effect.goldDelta != 0) {
      final isGain = effect.goldDelta > 0;
      items.add(_ResultItem(
        icon: isGain ? '💰' : '💸',
        text: '골드 ${isGain ? '+' : ''}${effect.goldDelta}',
        color: isGain ? const Color(0xFFFDD835) : const Color(0xFFFF8F00),
      ));
    }

    if (effect.addRandomCard) {
      items.add(const _ResultItem(
        icon: '🃏',
        text: '랜덤 카드 1장 획득',
        color: Color(0xFF42A5F5),
      ));
    }

    return items;
  }
}

// ──────────────────────────────────────────────────────────────────────────
// _ResultItem
// ──────────────────────────────────────────────────────────────────────────

class _ResultItem extends StatelessWidget {
  final String icon;
  final String text;
  final Color color;

  const _ResultItem({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// _ChoiceButton
// ──────────────────────────────────────────────────────────────────────────

class _ChoiceButton extends StatelessWidget {
  final EventChoice choice;
  final VoidCallback onTap;

  const _ChoiceButton({required this.choice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1D46),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF4A4A8A)),
        ),
        child: Row(
          children: [
            const Text(
              EventConstants.choiceButtonPrefix,
              style: TextStyle(color: Color(0xFFA78BFA), fontSize: 16),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                choice.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
