import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/run_provider.dart';

/// 상점 화면 — 골드로 카드 구매·제거·유물 구매.
///
/// 현재는 플레이스홀더. Sprint 6에서 완전 구현 예정.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gold = ref.watch(runProvider.select((s) => s.gold));

    return Scaffold(
      backgroundColor: const Color(0xFF0D0A07),
      body: SafeArea(
        child: Column(
          children: [
            // ── 헤더 ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.storefront, color: Color(0xFFFFD700)),
                  const SizedBox(width: 8),
                  const Text(
                    '상점',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.monetization_on, size: 16, color: Color(0xFFFFD700)),
                  const SizedBox(width: 4),
                  Text(
                    '$gold G',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF3D3020)),

            // ── 준비 중 안내 ───────────────────────────────────────────────
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.construction, size: 64, color: Colors.white24),
                    SizedBox(height: 16),
                    Text(
                      '상점 준비 중...',
                      style: TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sprint 6에서 오픈 예정',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // ── 돌아가기 ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => ref.read(runProvider.notifier).exitShop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF37474F),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '맵으로 돌아가기',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
