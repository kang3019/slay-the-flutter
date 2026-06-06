import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/run_provider.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/player.dart';
import '../battle/widgets/card_widget.dart';

/// 휴식처(🔥) 노드에서 HP 회복 또는 강화를 선택하는 화면.
///
/// 휴식: 최대 HP의 30%를 회복하고 맵으로 돌아간다.
/// 강화: 덱의 카드 1장을 업그레이드하고 맵으로 돌아간다.
class RestScreen extends ConsumerStatefulWidget {
  const RestScreen({super.key});

  @override
  ConsumerState<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends ConsumerState<RestScreen> {
  static const double _healRatio = 0.3;

  /// true이면 카드 선택 화면을 표시한다.
  bool _upgradingMode = false;

  @override
  Widget build(BuildContext context) {
    final playerHp = ref.watch(runProvider.select((s) => s.playerHp));
    final deck     = ref.watch(runProvider.select((s) => s.deck));
    final notifier = ref.read(runProvider.notifier);

    final healAmount  = (Player.maxHp * _healRatio).floor();
    final afterHp     = (playerHp + healAmount).clamp(0, Player.maxHp);
    final alreadyFull = playerHp >= Player.maxHp;

    // 강화 가능한 카드(미강화)가 한 장 이상 있어야 강화 선택지를 활성화한다.
    final upgradableCards = deck.where((c) => !c.isUpgraded).toList();
    final canUpgrade = upgradableCards.isNotEmpty;

    if (_upgradingMode) {
      return _UpgradePickerView(
        deck: deck,
        onCardSelected: (card) {
          notifier.upgradeCard(card);
        },
        onBack: () => setState(() => _upgradingMode = false),
      );
    }

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

              // ── 강화 버튼 ─────────────────────────────────────────────────
              _OptionButton(
                icon: '⚒️',
                label: canUpgrade ? '강화' : '강화 (강화할 카드 없음)',
                description: '덱의 카드 1장을 업그레이드한다.',
                color: const Color(0xFF1A2A3A),
                enabled: canUpgrade,
                onTap: () => setState(() => _upgradingMode = true),
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

// ── 카드 선택 뷰 ──────────────────────────────────────────────────────────────

/// 강화할 카드를 덱에서 선택하는 화면.
///
/// 캐러셀에서 좌우로 드래그해 카드를 확인하고, 탭하면 강화 전·후 비교 화면으로 전환된다.
class _UpgradePickerView extends StatefulWidget {
  final List<GameCard> deck;
  final void Function(GameCard) onCardSelected;
  final VoidCallback onBack;

  const _UpgradePickerView({
    required this.deck,
    required this.onCardSelected,
    required this.onBack,
  });

  @override
  State<_UpgradePickerView> createState() => _UpgradePickerViewState();
}

class _UpgradePickerViewState extends State<_UpgradePickerView> {
  /// null = 카드 목록, non-null = 강화 확인.
  GameCard? _selectedCard;

  late final PageController _pageController;
  int _currentPage = 0;

  static const int _cardsPerRow  = 8;
  static const int _cardsPerPage = _cardsPerRow * 2;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A0D),
      body: SafeArea(
        child: _selectedCard == null
            ? _buildCardList()
            : _buildConfirmation(_selectedCard!),
      ),
    );
  }

  // ── 2×8 페이지 카드 목록 ─────────────────────────────────────────────────

  Widget _buildCardList() {
    // 덱을 페이지 단위로 나눈다. 페이지당 최대 _cardsPerPage(16)장.
    final pages = <List<GameCard>>[];
    for (var i = 0; i < widget.deck.length; i += _cardsPerPage) {
      pages.add(widget.deck.sublist(
          i, min(i + _cardsPerPage, widget.deck.length)));
    }
    if (pages.isEmpty) pages.add([]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 헤더 ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: const Icon(Icons.arrow_back_ios,
                    color: Color(0xFF81C784), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '강화할 카드를 선택하세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ── 카드 그리드 박스 ──────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A1A0A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E7D32)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (p) => setState(() => _currentPage = p),
                      itemCount: pages.length,
                      itemBuilder: (_, i) => _buildPage(pages[i]),
                    ),
                  ),
                  if (pages.length > 1) _buildPageNav(pages.length),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  // ── 페이지 1장 (위 8 + 아래 8) ───────────────────────────────────────────

  Widget _buildPage(List<GameCard> pageCards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const hGap = 4.0;
        const vGap = 8.0;
        const pad  = 12.0;

        final availW = constraints.maxWidth  - pad * 2;
        final availH = constraints.maxHeight - pad * 2;

        final cardW = (availW - hGap * (_cardsPerRow - 1)) / _cardsPerRow;
        final cardH = (availH - vGap) / 2;

        final scale = min(
          cardW / CardWidget.cardWidth,
          cardH / CardWidget.cardHeight,
        ).clamp(0.3, 2.0);

        final top    = pageCards.take(_cardsPerRow).toList();
        final bottom = pageCards.skip(_cardsPerRow).toList();

        return Padding(
          padding: const EdgeInsets.all(pad),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRow(top,    scale, hGap),
              _buildRow(bottom, scale, hGap),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(List<GameCard> cards, double scale, double hGap) {
    final items = <Widget>[];
    for (var i = 0; i < _cardsPerRow; i++) {
      if (i > 0) items.add(SizedBox(width: hGap));
      if (i < cards.length) {
        items.add(_buildCardItem(cards[i], scale));
      } else {
        // 빈 자리 — 마지막 페이지에서 그리드 정렬 유지
        items.add(SizedBox(
          width:  CardWidget.cardWidth  * scale,
          height: CardWidget.cardHeight * scale,
        ));
      }
    }
    return Row(children: items);
  }

  // ── 페이지 네비게이션 (화살표 + 페이지 번호) ────────────────────────────

  Widget _buildPageNav(int total) {
    final canPrev = _currentPage > 0;
    final canNext = _currentPage < total - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: canPrev
                ? () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    )
                : null,
            child: Icon(
              Icons.arrow_back_ios,
              color: canPrev
                  ? const Color(0xFF81C784)
                  : const Color(0xFF333333),
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${_currentPage + 1} / $total',
            style: const TextStyle(
              color: Color(0xFF81C784),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: canNext
                ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    )
                : null,
            child: Icon(
              Icons.arrow_forward_ios,
              color: canNext
                  ? const Color(0xFF81C784)
                  : const Color(0xFF333333),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ── 카드 아이템 ──────────────────────────────────────────────────────────

  Widget _buildCardItem(GameCard card, double scale) {
    final canSelect = !card.isUpgraded;
    return GestureDetector(
      onTap: canSelect ? () => setState(() => _selectedCard = card) : null,
      child: Opacity(
        opacity: canSelect ? 1.0 : 0.38,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            _ScaledCard(card: card, scale: scale),
            if (card.isUpgraded)
              Positioned(
                bottom: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '강화 완료',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── 강화 확인 ────────────────────────────────────────────────────────────

  Widget _buildConfirmation(GameCard card) {
    const scale   = 1.45;
    final upgraded = Cards.upgrade(card);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 헤더 ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedCard = null),
                child: const Icon(Icons.arrow_back_ios,
                    color: Color(0xFF81C784), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '강화 확인',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // ── 강화 전·후 비교 ──────────────────────────────────────────
        // Expanded로 각 카드를 좌·우 영역에 배치해 중앙 화살표와 겹치지 않게 한다.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Center(child: _ScaledCard(card: card, scale: scale)),
            ),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_forward,
                    color: Color(0xFFFFD700), size: 30),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '강화',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            Expanded(
              child: Center(child: _ScaledCard(card: upgraded, scale: scale)),
            ),
          ],
        ),

        const Spacer(),

        // ── 강화하기 버튼 ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: GestureDetector(
            onTap: () => widget.onCardSelected(card),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF4CAF50)),
              ),
              child: const Text(
                '강화하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── 다시 선택 버튼 ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: GestureDetector(
            onTap: () => setState(() => _selectedCard = null),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '다시 선택',
                style: TextStyle(color: Color(0xFF666666), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        const SizedBox(height: 28),
      ],
    );
  }
}

/// [CardWidget]을 [scale]배 크기로 레이아웃 공간까지 확보해 표시한다.
///
/// Center를 통해 Transform.scale의 시각적 출력이 SizedBox 안에 정확히 맞게 한다.
/// Center 없이는 Transform이 카드 원점(0,0) 기준으로 그려져 레이아웃 밖으로 튀어나온다.
class _ScaledCard extends StatelessWidget {
  final GameCard card;
  final double scale;
  const _ScaledCard({required this.card, required this.scale});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  CardWidget.cardWidth  * scale,
      height: CardWidget.cardHeight * scale,
      child: Center(
        child: Transform.scale(
          scale: scale,
          child: CardWidget(card: card, canPlay: true),
        ),
      ),
    );
  }
}

// ── 공통 옵션 버튼 ─────────────────────────────────────────────────────────────

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
