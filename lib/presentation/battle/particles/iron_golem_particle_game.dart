import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// 철갑골렘 보스 배경 위에 오버레이되는 파티클 전용 FlameGame.
///
/// 완전 투명 배경으로 동작하며, Flutter Stack 레이어로 배경 이미지 위에 얹힌다.
/// 두 파티클 시스템을 포함한다:
///   [_GemSparkleSystem] — 벽·기둥·천장의 녹색 보석 반짝임
///   [_SwordFlameSystem] — 제단 검의 녹색 불꽃 이글거림
class IronGolemParticleGame extends FlameGame {
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(_GemSparkleSystem());
    add(_SwordFlameSystem());
  }
}

// ── 보석 반짝임 ───────────────────────────────────────────────────────────────

/// 벽, 기둥, 천장의 보석 위치에서 4방향 글린트(✦)가 나타났다 사라지는 반짝임 효과.
///
/// 애니메이션 커브: 앞 25% 구간에 빠르게 커지고(등장), 나머지 75%에 서서히 사라짐(잔상).
/// 글린트 피크 순간 작은 먼지 파티클도 함께 방출해 보석 빛 산란 표현.
class _GemSparkleSystem extends Component {
  static const _spawnInterval = 0.07;

  static const _gemZones = [
    (0.07, 0.07), (0.20, 0.04), (0.35, 0.08), (0.52, 0.05),
    (0.68, 0.07), (0.83, 0.04), (0.92, 0.10),
    (0.04, 0.20), (0.94, 0.26), (0.06, 0.35), (0.92, 0.38),
    (0.15, 0.13), (0.78, 0.11), (0.28, 0.17), (0.62, 0.15),
    (0.44, 0.03), (0.10, 0.45), (0.88, 0.50),
  ];

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
    _spawnAt(_gemZones[_rng.nextInt(_gemZones.length)]);
    // 틱당 두 보석이 동시에 반짝이도록
    _spawnAt(_gemZones[_rng.nextInt(_gemZones.length)]);
  }

  void _spawnAt((double, double) zone) {
    final cx = zone.$1 * _size.x + (_rng.nextDouble() - 0.5) * _size.x * 0.04;
    final cy = zone.$2 * _size.y + (_rng.nextDouble() - 0.5) * _size.y * 0.025;

    // 글린트 크기와 색상 — 캡처 후 renderer에서 재사용
    final maxRayLen  = 5.0 + _rng.nextDouble() * 9.0;  // 십자 광선 길이
    final lifespan   = 0.55 + _rng.nextDouble() * 0.55;
    final gVal       = 210 + _rng.nextInt(45);          // 밝은 녹색
    final rVal       = 80  + _rng.nextInt(80);
    final strokeW    = 0.9 + _rng.nextDouble() * 0.8;

    // ── 1. 4방향 글린트 별(✦) ───────────────────────────────────────────
    parent!.add(
      ParticleSystemComponent(
        position: Vector2(cx, cy),
        particle: ComputedParticle(
          lifespan: lifespan,
          renderer: (canvas, p) {
            final t = p.progress;

            // ping 커브: 앞 25%는 확장, 나머지는 서서히 페이드
            final scale = t < 0.25
                ? t / 0.25
                : 1.0 - (t - 0.25) / 0.75;
            final alpha = scale.clamp(0.0, 1.0);
            final ray   = maxRayLen * scale;
            if (ray < 0.3) return;

            final paint = Paint()
              ..color = Color.fromRGBO(rVal, gVal, 130, alpha)
              ..strokeWidth = strokeW
              ..style = PaintingStyle.stroke
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, ray * 0.25);

            // 수직·수평 광선 (긴 방향)
            canvas.drawLine(Offset(0, -ray), Offset(0, ray), paint);
            canvas.drawLine(Offset(-ray, 0), Offset(ray, 0), paint);

            // 대각 광선 (짧게 — 보석 특유의 ✦ 형태)
            final d = ray * 0.42;
            canvas.drawLine(Offset(-d, -d), Offset(d, d), paint);
            canvas.drawLine(Offset(d, -d), Offset(-d, d), paint);

            // 중심 글로우 점
            canvas.drawCircle(
              Offset.zero,
              ray * 0.22,
              Paint()
                ..color = Color.fromRGBO(230, 255, 210, alpha * 0.95)
                ..maskFilter = MaskFilter.blur(BlurStyle.normal, ray * 0.5),
            );
          },
        ),
      ),
    );

    // ── 2. 보석 빛 산란 먼지 (글린트와 동시 방출) ───────────────────────
    parent!.add(
      ParticleSystemComponent(
        position: Vector2(cx, cy),
        particle: Particle.generate(
          count: 4 + _rng.nextInt(4),
          lifespan: lifespan * 0.7,
          generator: (_) {
            final angle  = _rng.nextDouble() * 2 * pi;
            final speed  = 8.0 + _rng.nextDouble() * 16.0;
            final dustR  = 0.8 + _rng.nextDouble() * 1.4;
            final dustG  = 200 + _rng.nextInt(55);
            return AcceleratedParticle(
              speed: Vector2(cos(angle) * speed, sin(angle) * speed),
              acceleration: Vector2(0, 10),
              child: ComputedParticle(
                renderer: (canvas, p) {
                  final alpha = (1.0 - p.progress).clamp(0.0, 1.0);
                  canvas.drawCircle(
                    Offset.zero,
                    dustR * (1 - p.progress * 0.5),
                    Paint()
                      ..color = Color.fromRGBO(rVal, dustG, 120, alpha * 0.75)
                      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── 칼 이글거림 ───────────────────────────────────────────────────────────────

/// 중앙 제단 검에서 위로 피어오르는 녹색 불꽃 입자를 방출한다.
///
/// 조밀한 방출 간격과 소용돌이(vortex) 가속도로 이글거리는 불꽃 질감을 구현한다.
class _SwordFlameSystem extends Component {
  static const _spawnInterval = 0.018; // 0.042 → 0.018: 불꽃 밀도 대폭 증가

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
    _spawnFlame(); // 틱당 2개 방출
  }

  void _spawnFlame() {
    // 검 위치: 화면 수평 중앙, 수직 약 50~56% 지점
    final cx = _size.x * 0.50;
    final cy = _size.y * 0.53;

    // 칼날 형태를 따라 x 는 좁게, y 는 검 길이만큼 분산
    final spreadX = _size.x * 0.04;
    final spreadY = _size.y * 0.07;
    final x = cx + (_rng.nextDouble() - 0.5) * spreadX;
    final y = cy + (_rng.nextDouble() - 0.5) * spreadY;

    final lifespan  = 0.45 + _rng.nextDouble() * 0.50;
    final upSpeed   = 38.0 + _rng.nextDouble() * 50.0;
    final sway      = (_rng.nextDouble() - 0.5) * 28.0;
    // 소용돌이: 위로 오를수록 반대 방향으로 휘게 해 나선감 생성
    final vortexX   = (_rng.nextDouble() - 0.5) * 22.0;
    final baseR     = 2.8 + _rng.nextDouble() * 4.5;
    final greenBase = 170 + _rng.nextInt(85); // 170~254

    parent!.add(
      ParticleSystemComponent(
        position: Vector2(x, y),
        particle: AcceleratedParticle(
          lifespan: lifespan,
          speed: Vector2(sway, -upSpeed),
          acceleration: Vector2(vortexX, -6), // 위쪽 가속 + 소용돌이
          child: ComputedParticle(
            renderer: (canvas, p) {
              final t     = p.progress;
              final alpha = ((1.0 - t) * 0.88).clamp(0.0, 1.0);
              final r     = baseR * (1.0 - t * 0.55);
              // 초록불꽃: 핵심은 밝은 녹색, 가장자리로 갈수록 어두운 에메랄드
              final g  = (greenBase * (1.0 - t * 0.3)).toInt().clamp(0, 255);
              final rb = (25 * (1.0 - t)).toInt().clamp(0, 255);
              canvas.drawCircle(
                Offset.zero,
                r,
                Paint()
                  ..color = Color.fromRGBO(rb, g, rb + 30, alpha)
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
