import 'package:flutter/material.dart';

import '../app_router.dart';
import '../codex/codex_screen.dart';
import '../save_slot/save_slot_screen.dart';
import '../settings/settings_screen.dart';
import 'intro_constants.dart';
import 'widgets/ember_field.dart';

/// 게임 인트로(타이틀) 화면.
///
/// 전체 화면 일러스트를 배경으로 우측 하단에 게임 시작·설정·도감·세이브 파일
/// 메뉴 버튼을 배치하고, 배경 줌·입자·버튼 등장 애니메이션으로 생동감을 더한다.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  late final AnimationController _zoomController;
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _zoomController = AnimationController(vsync: this, duration: IntroAnim.zoomDuration)
      ..repeat(reverse: true);
    _entranceController = AnimationController(vsync: this, duration: IntroAnim.entranceDuration)
      ..forward();
    _pulseController = AnimationController(vsync: this, duration: IntroAnim.pulseDuration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// [index]번째 버튼의 등장(페이드·슬라이드) 애니메이션을 계산한다.
  Animation<double> _entranceFor(int index) {
    final start = index * IntroAnim.buttonStagger;
    final end = (start + IntroAnim.entranceSpan).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  /// 타이틀 로고의 페이드인 애니메이션. 버튼보다 먼저 떠오른다.
  Animation<double> get _titleFade => CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _zoomController,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_zoomController.value);
              return Transform.scale(scale: 1.0 + t * IntroAnim.zoomScaleDelta, child: child);
            },
            child: Image.asset(
              IntroAssets.background,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          // 타이틀 로고 — 배경과 분리된 레이어로, 줌 애니메이션의 영향을 받지 않는다.
          // 가로폭 기준으로 맞춰 화면 중앙에 정렬한 뒤, 우측으로 살짝 이동시킨다.
          Positioned.fill(
            child: FractionalTranslation(
              translation: const Offset(IntroAnim.titleOffsetX, 0),
              child: FadeTransition(
                opacity: _titleFade,
                child: Image.asset(
                  IntroAssets.titleLogo,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          const Positioned.fill(child: EmberField()),
          // 버튼 가독성을 위한 하단 어둡게 처리
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
                stops: [0.55, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _EntranceItem(
                      animation: _entranceFor(0),
                      child: _IntroButton(
                        icon: Icons.play_arrow,
                        label: IntroStrings.startGame,
                        isPrimary: true,
                        pulse: _pulseController,
                        onTap: () => _startGame(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EntranceItem(
                      animation: _entranceFor(1),
                      child: _IntroButton(
                        icon: Icons.settings,
                        label: IntroStrings.settings,
                        onTap: () => _openSettings(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EntranceItem(
                      animation: _entranceFor(2),
                      child: _IntroButton(
                        icon: Icons.menu_book,
                        label: IntroStrings.codex,
                        onTap: () => _openCodex(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EntranceItem(
                      animation: _entranceFor(3),
                      child: _IntroButton(
                        icon: Icons.save,
                        label: IntroStrings.saveFiles,
                        onTap: () => _openSaveFiles(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 네비게이션 ───────────────────────────────────────────────────────────────

void _startGame(BuildContext context) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(builder: (_) => const AppRouter()),
  );
}

void _openSettings(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
  );
}

void _openCodex(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const CodexScreen()),
  );
}

void _openSaveFiles(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SaveSlotScreen(
        onSlotLoaded: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const AppRouter()),
          (route) => false,
        ),
      ),
    ),
  );
}

// ── 등장 애니메이션 래퍼 ─────────────────────────────────────────────────────

/// 자식 위젯을 아래에서 위로 슬라이드하며 페이드인시키는 래퍼.
class _EntranceItem extends StatelessWidget {
  const _EntranceItem({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(animation),
        child: child,
      ),
    );
  }
}

// ── 메뉴 버튼 ────────────────────────────────────────────────────────────────

class _IntroButton extends StatelessWidget {
  const _IntroButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.pulse,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  /// 0~1 사이를 반복하는 펄스 값. 지정 시 빛 번짐 효과가 추가된다.
  final Animation<double>? pulse;

  static const double _width = 180;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isPrimary ? IntroColors.primaryButtonBg : IntroColors.buttonBackground;
    final textColor       = isPrimary ? IntroColors.primaryButtonText : IntroColors.buttonText;

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: _width,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: IntroColors.buttonBorder,
              width: isPrimary ? 0 : 1.2,
            ),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final pulse = this.pulse;
    if (pulse == null) return button;

    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final glow = IntroAnim.pulseGlowMin +
            pulse.value * (IntroAnim.pulseGlowMax - IntroAnim.pulseGlowMin);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: IntroColors.primaryGlow.withValues(alpha: 0.55),
                blurRadius: glow,
                spreadRadius: glow * 0.15,
              ),
            ],
          ),
          child: child,
        );
      },
      child: button,
    );
  }
}
