import 'dart:math';

import 'package:flutter/material.dart';

import '../intro_constants.dart';

/// 인트로 배경 위로 떠오르는 초록빛 입자 효과.
///
/// 배경 일러스트의 크리스탈 분위기에 생동감을 더하기 위한 순수 장식용
/// 애니메이션이며 게임 로직과는 무관하다.
class EmberField extends StatefulWidget {
  const EmberField({super.key});

  @override
  State<EmberField> createState() => _EmberFieldState();
}

class _EmberFieldState extends State<EmberField>
    with SingleTickerProviderStateMixin {
  static const int _emberCount = 22;
  static const Duration _cycleDuration = Duration(seconds: 16);

  late final AnimationController _controller;
  late final List<_Ember> _embers;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _cycleDuration)
      ..repeat();
    final random = Random();
    _embers = List.generate(_emberCount, (_) => _Ember.random(random));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _EmberPainter(embers: _embers, t: _controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// 입자 한 개의 이동 경로(시작 위치·속도·흔들림)를 정의하는 불변 데이터.
class _Ember {
  const _Ember({
    required this.x,
    required this.startY,
    required this.speed,
    required this.radius,
    required this.driftAmount,
    required this.phase,
  });

  factory _Ember.random(Random random) {
    return _Ember(
      x: random.nextDouble(),
      startY: 0.5 + random.nextDouble() * 0.8,
      speed: 0.6 + random.nextDouble() * 0.7,
      radius: 1.0 + random.nextDouble() * 2.2,
      driftAmount: 8 + random.nextDouble() * 18,
      phase: random.nextDouble() * 2 * pi,
    );
  }

  final double x;
  final double startY;
  final double speed;
  final double radius;
  final double driftAmount;
  final double phase;
}

class _EmberPainter extends CustomPainter {
  const _EmberPainter({required this.embers, required this.t});

  final List<_Ember> embers;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final ember in embers) {
      final cycle = (t * ember.speed + ember.phase / (2 * pi)) % 1.0;
      final dy = ember.startY * size.height - cycle * size.height * 1.1;
      final dx =
          ember.x * size.width +
          sin(cycle * 2 * pi + ember.phase) * ember.driftAmount;
      final alpha = sin(cycle * pi).clamp(0.0, 1.0);

      paint.color = IntroColors.emberColor.withValues(alpha: alpha * 0.7);
      canvas.drawCircle(Offset(dx, dy), ember.radius, paint);

      paint.color = IntroColors.emberColor.withValues(alpha: alpha * 0.18);
      canvas.drawCircle(Offset(dx, dy), ember.radius * 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EmberPainter oldDelegate) => true;
}
