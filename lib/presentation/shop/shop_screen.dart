import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/run_provider.dart';
import '../battle/widgets/looping_video_bg.dart';
import 'shop_constants.dart';
import 'shop_widgets.dart';

/// 상인 이미지 높이.
const double _kMerchantH = 360;

/// 영상 바닥선 비율 (Expanded 높이 기준).
/// battle_bg.mp4 그라운드 섀도우가 전체 화면 하단 28% 지점 → Expanded 기준 약 68%.
const double _kFloorRatio = 0.68;

/// 돗자리 팝업 최대 너비 — [RewardScreen] 보상 팝업과 동일한 폭으로 맞춘다.
const double _kMatMaxWidth = 480;

/// 상점 화면 — 골드로 카드·유물 구매 및 카드 제거.
///
/// 상인을 탭하면 돗자리 팝업이 화면 중앙에 열리며, 다시 탭하거나 바깥을 터치하면 닫힌다.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _matCtrl;
  late final Animation<double> _matScale;
  late final Animation<double> _matFade;

  bool _matOpen = false;

  @override
  void initState() {
    super.initState();
    _matCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _matScale = CurvedAnimation(parent: _matCtrl, curve: Curves.easeOutBack);
    _matFade  = CurvedAnimation(parent: _matCtrl, curve: Curves.easeIn);

    // 이미 구매 이력이 있으면 매트를 즉시 펼친다.
    final s = ref.read(runProvider);
    if (s.shopCardSold.any((e) => e) ||
        s.shopRelicSold.any((e) => e) ||
        s.shopCardRemovalDone) {
      _matOpen = true;
      _matCtrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _matCtrl.dispose();
    super.dispose();
  }

  void _toggleMat() {
    if (_matOpen) {
      _matCtrl.reverse().then((_) {
        if (mounted) setState(() => _matOpen = false);
      });
    } else {
      setState(() => _matOpen = true);
      _matCtrl.forward(from: 0);
    }
  }

  void _showRemovalModal() {
    final deck     = ref.read(runProvider).deck;
    final notifier = ref.read(runProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CardRemovalSheet(deck: deck, notifier: notifier),
    );
  }

  @override
  Widget build(BuildContext context) {
    final runState = ref.watch(runProvider);
    final notifier = ref.read(runProvider.notifier);

    return Scaffold(
      backgroundColor: ShopColors.background,
      body: Stack(
        children: [
          // ── 동영상 배경 ──
          const Positioned.fill(
            child: LoopingVideoBg(assetPath: ShopAssets.backgroundVideo),
          ),

          // ── 메인 UI ──
          SafeArea(
            child: Column(
              children: [
                ShopGoldBar(gold: runState.gold),

                // 상인 이미지 — 바닥선에 발이 닿도록 배치
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, constraints) {
                      final h       = constraints.maxHeight;
                      final floorY  = h * _kFloorRatio;
                      final mercTop =
                          (floorY - _kMerchantH).clamp(0.0, h - _kMerchantH);

                      return Stack(
                        children: [
                          Positioned(
                            top: mercTop,
                            left: 0,
                            right: 0,
                            height: _kMerchantH,
                            child: GestureDetector(
                              onTap: _toggleMat,
                              child: MerchantImage(matOpen: _matOpen),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // 다음 층으로 버튼
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 16, 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: notifier.exitShop,
                      icon: const Icon(Icons.arrow_forward_ios,
                          size: 13, color: Colors.white),
                      label: const Text(
                        ShopStrings.returnButton,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xCC37474F),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 돗자리 팝업 오버레이 ──
          if (_matOpen) ...[
            // 반투명 배경 — 탭하면 닫힘
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMat,
                child: const ColoredBox(color: Color(0x99000000)),
              ),
            ),

            // 중앙 팝업
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 72, 16, 72),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _matCtrl,
                      builder: (_, child) => Transform.scale(
                        scale: _matScale.value,
                        child: Opacity(
                          opacity: _matFade.value.clamp(0.0, 1.0),
                          child: child,
                        ),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: _kMatMaxWidth,
                          maxHeight:
                              MediaQuery.of(context).size.height * 0.65,
                        ),
                        child: SingleChildScrollView(
                          child: ShopMat(
                            runState: runState,
                            notifier: notifier,
                            onRemovalTap: _showRemovalModal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
