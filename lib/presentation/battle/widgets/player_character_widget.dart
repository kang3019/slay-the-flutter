import 'package:flutter/material.dart';

import '../battle_constants.dart';

/// 플레이어 캐릭터 이미지와 공격 모션 애니메이션을 담당하는 위젯.
///
/// [attackTrigger]의 정수 값이 바뀔 때마다 공격 시퀀스를 한 번 재생한다.
/// 모든 애니메이션 상태는 이 위젯 내부에서만 관리되어 비즈니스 로직과 분리된다.
class PlayerCharacterWidget extends StatefulWidget {
  /// 공격 카드가 사용될 때 외부에서 값을 증가시켜 애니메이션을 트리거한다.
  final ValueNotifier<int> attackTrigger;

  const PlayerCharacterWidget({super.key, required this.attackTrigger});

  @override
  State<PlayerCharacterWidget> createState() => _PlayerCharacterWidgetState();
}

class _PlayerCharacterWidgetState extends State<PlayerCharacterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  bool _isAttacking = false;
  bool _animating   = false;

  // 돌진: 몬스터(위쪽) 방향으로 위로 48px + 살짝 오른쪽 24px
  static const Offset _kSlideTo = Offset(24, -48);
  static const Duration _kForward = Duration(milliseconds: 100);
  static const Duration _kHold    = Duration(milliseconds: 150);
  static const Duration _kReturn  = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: _kForward);
    _slide = Tween<Offset>(begin: Offset.zero, end: _kSlideTo).animate(_ctrl);
    widget.attackTrigger.addListener(_onTrigger);
  }

  @override
  void dispose() {
    widget.attackTrigger.removeListener(_onTrigger);
    _ctrl.dispose();
    super.dispose();
  }

  void _onTrigger() => _playAttack();

  Future<void> _playAttack() async {
    // 이미 재생 중이면 새 요청 무시
    if (_animating || !mounted) return;
    _animating = true;

    setState(() => _isAttacking = true);
    await _ctrl.animateTo(1.0, duration: _kForward, curve: Curves.easeIn);

    if (!mounted) { _animating = false; return; }
    await Future.delayed(_kHold);

    if (!mounted) { _animating = false; return; }
    setState(() => _isAttacking = false);
    await _ctrl.animateTo(0.0, duration: _kReturn, curve: Curves.easeOut);

    if (mounted) _animating = false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slide,
      child: Image.asset(
        _isAttacking ? PlayerAssets.attack : PlayerAssets.idle,
        width: double.infinity,
        height: 360,
        fit: BoxFit.contain,
        alignment: const Alignment(-0.07, 1.0),
        filterQuality: FilterQuality.medium,
      ),
      builder: (context, child) => Transform.translate(
        offset: _slide.value,
        child: child,
      ),
    );
  }
}
