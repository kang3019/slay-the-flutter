import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// 철갑골렘 보스 배경 위에 오버레이되는 파티클 전용 FlameGame.
///
/// 완전 투명 배경으로 동작하며, Flutter Stack 레이어로 배경 이미지 위에 얹힌다.
/// 세 시스템을 포함한다:
///   [_FogSystem]        — 화면 하단에서 좌우로 흐르는 으스스한 녹색 안개
///   [_GemGlowSystem]    — 벽·기둥·천장 보석의 살짝 맥동하는 글로우
///   [_SwordFlameSystem] — 제단 검의 녹색 불꽃 (밀도 완화)
class IronGolemParticleGame extends FlameGame {
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(_FogSystem());
    add(_GemGlowSystem());
    add(_SwordFlameSystem());
  }
}

// ── 안개 파라미터 ──────────────────────────────────────────────────────────────

class _FogBlob {
  final double baseX;
  final double y;
  final double rx;
  final double ry;
  final double phase;
  final double speed;

  const _FogBlob({
    required this.baseX,
    required this.y,
    required this.rx,
    required this.ry,
    required this.phase,
    required this.speed,
  });
}

// ── 안개 시스템 ────────────────────────────────────────────────────────────────

/// 화면 하단에서 좌우로 천천히 흐르는 으스스한 녹색 안개.
///
/// 블러 없이 RadialGradient 셰이더만으로 부드러운 가장자리를 표현해
/// GPU 부담을 최소화한다. 오브젝트 할당이 없어 GC 압박도 없다.
class _FogSystem extends Component {
  static const _fogBlobs = [
    // 메인: 넓고 낮은 바닥 안개층
    _FogBlob(baseX: 0.30, y: 0.66, rx: 0.70, ry: 0.26, phase: 0.0,        speed: 0.18),
    // 중간 높이 — 반대 방향 교차
    _FogBlob(baseX: 0.65, y: 0.52, rx: 0.55, ry: 0.21, phase: pi,         speed: 0.23),
    // 바닥 짙은 층
    _FogBlob(baseX: 0.45, y: 0.78, rx: 0.46, ry: 0.17, phase: pi * 0.65,  speed: 0.16),
    // 왼쪽 중간
    _FogBlob(baseX: 0.18, y: 0.44, rx: 0.36, ry: 0.14, phase: pi * 1.35,  speed: 0.28),
    // 오른쪽 보조
    _FogBlob(baseX: 0.80, y: 0.49, rx: 0.34, ry: 0.15, phase: pi * 0.45,  speed: 0.21),
    // 중앙 하단 짙은 패치
    _FogBlob(baseX: 0.50, y: 0.73, rx: 0.42, ry: 0.18, phase: pi * 1.80,  speed: 0.20),
    // 좌하단 바닥 흐름
    _FogBlob(baseX: 0.22, y: 0.83, rx: 0.32, ry: 0.12, phase: pi * 0.95,  speed: 0.25),
  ];

  double _elapsed = 0;
  late Vector2 _size;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _size = size;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    for (final blob in _fogBlobs) {
      final driftX = sin(_elapsed * blob.speed + blob.phase) * _size.x * 0.10;
      final cx     = blob.baseX * _size.x + driftX;
      final cy     = blob.y * _size.y;
      final rx     = blob.rx * _size.x;
      final ry     = blob.ry * _size.y;

      // 투명도 맥동
      final alphaOsc    = sin(_elapsed * blob.speed * 1.4 + blob.phase * 0.8) * 0.05;
      final centerAlpha = (0.50 + alphaOsc).clamp(0.40, 0.60);

      final rect = Rect.fromCenter(
        center: Offset(cx, cy),
        width:  rx * 2,
        height: ry * 2,
      );

      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Color.fromRGBO(45, 190, 90, centerAlpha),
              Color.fromRGBO(20, 130, 55, centerAlpha * 0.65),
              const Color(0x00000000),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(rect),
      );
    }
  }
}

// ── 보석 글로우 시스템 ──────────────────────────────────────────────────────────

/// 벽, 기둥, 천장의 보석이 살짝 맥동하는 글로우.
///
/// 새 오브젝트 할당 없이 단일 렌더 패스로 전체 보석을 그린다.
/// 이전 [_GemSparkleSystem]의 십자 글린트+먼지 파티클을 대체해
/// 드로우 콜을 대폭 줄인다.
class _GemGlowSystem extends Component {
  static const _gemZones = [
    (0.07, 0.07), (0.20, 0.04), (0.35, 0.08), (0.52, 0.05),
    (0.68, 0.07), (0.83, 0.04), (0.92, 0.10),
    (0.04, 0.20), (0.94, 0.26), (0.06, 0.35), (0.92, 0.38),
    (0.15, 0.13), (0.78, 0.11), (0.28, 0.17), (0.62, 0.15),
    (0.44, 0.03), (0.10, 0.45), (0.88, 0.50),
  ];

  final _rng   = Random();
  final _paint = Paint();
  double _elapsed = 0;
  late Vector2 _size;
  late List<double> _phases;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 각 보석마다 독립적인 맥동 위상 — 동시에 깜빡이지 않도록
    _phases = List.generate(
      _gemZones.length,
      (_) => _rng.nextDouble() * 2 * pi,
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _size = size;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    for (int i = 0; i < _gemZones.length; i++) {
      final zone = _gemZones[i];
      final cx = zone.$1 * _size.x;
      final cy = zone.$2 * _size.y;

      // 1.4 rad/s 속도로 부드럽게 맥동
      final pulse = 0.5 + 0.5 * sin(_elapsed * 1.4 + _phases[i]);
      final alpha = 0.18 + pulse * 0.42; // 0.18 ~ 0.60 — "살짝" 빛나는 강도
      final blurR = 2.2 + pulse * 3.0;   // 2.2 ~ 5.2 px

      _paint
        ..color      = Color.fromRGBO(100, 230, 140, alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurR);

      canvas.drawCircle(Offset(cx, cy), 1.5 + pulse * 1.2, _paint);
    }
  }
}

// ── 칼 불꽃 시스템 ─────────────────────────────────────────────────────────────

/// 중앙 제단 검에서 피어오르는 녹색 불꽃.
///
/// 스폰 간격 0.018 → 0.045 s, 틱당 2개 → 1개로 줄여
/// 동시 활성 파티클을 기존 대비 약 1/5 수준으로 낮췄다.
class _SwordFlameSystem extends Component {
  static const _spawnInterval = 0.045;

  final _rng = Random();
  double _elapsed = 0;
  late Vector2 _size;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _size = size;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed < _spawnInterval) return;
    _elapsed = 0;
    _spawnFlame();
  }

  void _spawnFlame() {
    final cx = _size.x * 0.50;
    final cy = _size.y * 0.53;
    final x  = cx + (_rng.nextDouble() - 0.5) * _size.x * 0.04;
    final y  = cy + (_rng.nextDouble() - 0.5) * _size.y * 0.07;

    final lifespan  = 0.50 + _rng.nextDouble() * 0.45;
    final upSpeed   = 40.0 + _rng.nextDouble() * 45.0;
    final sway      = (_rng.nextDouble() - 0.5) * 26.0;
    final vortexX   = (_rng.nextDouble() - 0.5) * 20.0;
    final baseR     = 3.0 + _rng.nextDouble() * 4.0;
    final greenBase = 170 + _rng.nextInt(85);

    parent!.add(
      ParticleSystemComponent(
        position: Vector2(x, y),
        particle: AcceleratedParticle(
          lifespan: lifespan,
          speed:        Vector2(sway, -upSpeed),
          acceleration: Vector2(vortexX, -6),
          child: ComputedParticle(
            renderer: (canvas, p) {
              final t     = p.progress;
              final alpha = ((1.0 - t) * 0.78).clamp(0.0, 1.0);
              final r     = baseR * (1.0 - t * 0.55);
              final g     = (greenBase * (1.0 - t * 0.3)).toInt().clamp(0, 255);
              final rb    = (25 * (1.0 - t)).toInt().clamp(0, 255);
              canvas.drawCircle(
                Offset.zero,
                r,
                Paint()
                  ..color      = Color.fromRGBO(rb, g, rb + 30, alpha)
                  ..maskFilter = MaskFilter.blur(
                    BlurStyle.normal,
                    (2.0 + t * 5.0).clamp(0.0, 8.0),
                  ),
              );
            },
          ),
        ),
      ),
    );
  }
}
