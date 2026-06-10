import 'package:flutter/material.dart';

import '../../application/run_provider.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/relic.dart';
import '../reward/reward_constants.dart';
import 'shop_constants.dart';

/// 상점 헤더 — 타이틀과 현재 골드를 표시한다.
class ShopGoldBar extends StatelessWidget {
  final int gold;
  const ShopGoldBar({super.key, required this.gold});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xCC0D0A07),
        border: Border(bottom: BorderSide(color: Color(0xFF3D3020), width: 0.8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront, color: Color(0xFFFFD700), size: 18),
          const SizedBox(width: 8),
          const Text(
            ShopStrings.title,
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 18,
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
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 상인 이미지와 탭 안내 텍스트.
///
/// 부모 `Positioned`에서 고정 높이를 받으며, 이미지는 하단에 정렬되어
/// 상인의 발이 매트 경계선에 닿아 보이도록 한다.
class MerchantImage extends StatelessWidget {
  final bool matOpen;
  const MerchantImage({super.key, required this.matOpen});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned.fill(
          child: Image.asset(
            ShopAssets.merchant,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.person, size: 160, color: Colors.white24),
          ),
        ),
        AnimatedOpacity(
          opacity: matOpen ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              ShopStrings.tapHint,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                shadows: [Shadow(color: Colors.black, blurRadius: 6)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 돗자리 컨테이너 — 카드·유물·카드 제거 서비스를 담는다.
class ShopMat extends StatelessWidget {
  final RunState runState;
  final RunNotifier notifier;
  final VoidCallback onRemovalTap;

  const ShopMat({
    super.key,
    required this.runState,
    required this.notifier,
    required this.onRemovalTap,
  });

  @override
  Widget build(BuildContext context) {
    final gold = runState.gold;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShopColors.mat,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ShopColors.matBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x55000000), blurRadius: 18, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 카드 섹션 ──
          const _SectionHeader(ShopStrings.cardSection),
          const SizedBox(height: 10),
          if (runState.shopCards.isEmpty)
            const Center(
              child: Text('준비된 카드가 없습니다.',
                  style: TextStyle(color: Colors.white24, fontSize: 12)),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < runState.shopCards.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: i < runState.shopCards.length - 1 ? 8 : 0),
                      child: ShopCardTile(
                        card: runState.shopCards[i],
                        price: runState.shopCardPrices[i],
                        sold: runState.shopCardSold[i],
                        canAfford: gold >= runState.shopCardPrices[i],
                        onBuy: () => notifier.buyShopCard(i),
                      ),
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 20),

          // ── 유물 섹션 ──
          const _SectionHeader(ShopStrings.relicSection),
          const SizedBox(height: 10),
          if (runState.shopRelics.isEmpty)
            const Center(
              child: Text('준비된 유물이 없습니다.',
                  style: TextStyle(color: Colors.white24, fontSize: 12)),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < runState.shopRelics.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: i < runState.shopRelics.length - 1 ? 8 : 0),
                      child: ShopRelicTile(
                        relic: runState.shopRelics[i],
                        price: runState.shopRelicPrices[i],
                        sold: runState.shopRelicSold[i],
                        canAfford: gold >= runState.shopRelicPrices[i],
                        onBuy: () => notifier.buyShopRelic(i),
                      ),
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 20),

          // ── 서비스 섹션 ──
          const _SectionHeader(ShopStrings.serviceSection),
          const SizedBox(height: 10),
          _RemovalServiceButton(
            done: runState.shopCardRemovalDone,
            canAfford: gold >= RunNotifier.shopRemovalCost,
            onTap: onRemovalTap,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFD4A853),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Divider(color: Color(0xFF5A4020), thickness: 0.8),
        ),
      ],
    );
  }
}

/// 상점 카드 타일 — 카드 정보와 구매 버튼을 수직으로 배치한다.
class ShopCardTile extends StatelessWidget {
  final GameCard card;
  final int price;
  final bool sold;
  final bool canAfford;
  final VoidCallback onBuy;

  const ShopCardTile({
    super.key,
    required this.card,
    required this.price,
    required this.sold,
    required this.canAfford,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final accent = RewardColors.forEffectType(card.effectType);
    final disabled = sold || !canAfford;

    return Opacity(
      opacity: sold ? 0.45 : 1.0,
      child: Container(
        height: ShopSizes.cardTileHeight,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: ShopColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sold ? Colors.white12 : accent.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: sold ? 0.08 : 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                    color: accent.withValues(alpha: sold ? 0.25 : 0.75)),
              ),
              child: Center(
                child: Text(
                  card.cost == -1 ? 'X' : '${card.cost}',
                  style: TextStyle(
                    color: accent.withValues(alpha: sold ? 0.35 : 1.0),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              card.name,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              RewardStrings.cardEffect(card),
              style: TextStyle(
                  color: accent.withValues(alpha: 0.75), fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: disabled ? null : onBuy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: sold
                      ? Colors.transparent
                      : canAfford
                          ? const Color(0xFFB8860B)
                          : const Color(0xFF3A2D1A),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text(
                  sold ? ShopStrings.soldLabel : '$price G',
                  style: TextStyle(
                    color: sold
                        ? Colors.white24
                        : canAfford
                            ? Colors.white
                            : Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

/// 상점 유물 타일 — 유물 이름·설명과 구매 버튼을 수직으로 배치한다.
class ShopRelicTile extends StatelessWidget {
  final Relic relic;
  final int price;
  final bool sold;
  final bool canAfford;
  final VoidCallback onBuy;

  const ShopRelicTile({
    super.key,
    required this.relic,
    required this.price,
    required this.sold,
    required this.canAfford,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = sold || !canAfford;

    return Opacity(
      opacity: sold ? 0.45 : 1.0,
      child: Container(
        height: ShopSizes.relicTileHeight,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: ShopColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sold
                ? Colors.white12
                : const Color(0xFF7B5EA7).withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    size: 14, color: Color(0xFFCE93D8)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    relic.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              relic.description,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 10),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: disabled ? null : onBuy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: sold
                      ? Colors.transparent
                      : canAfford
                          ? const Color(0xFF6A3FA0)
                          : const Color(0xFF2A1F35),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text(
                  sold ? ShopStrings.soldLabel : '$price G',
                  style: TextStyle(
                    color: sold
                        ? Colors.white24
                        : canAfford
                            ? Colors.white
                            : Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

class _RemovalServiceButton extends StatelessWidget {
  final bool done;
  final bool canAfford;
  final VoidCallback onTap;

  const _RemovalServiceButton({
    required this.done,
    required this.canAfford,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = done || !canAfford;
    final fgColor = done
        ? Colors.white24
        : canAfford
            ? Colors.white
            : Colors.white38;
    final bgColor = done
        ? Colors.transparent
        : canAfford
            ? const Color(0xFF8B1A1A)
            : const Color(0xFF2A1515);
    final borderColor = done
        ? Colors.white12
        : canAfford
            ? const Color(0xFFE57373)
            : Colors.white12;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: disabled ? null : onTap,
        icon: Icon(
          done ? Icons.check_circle_outline : Icons.content_cut,
          size: 15,
          color: fgColor,
        ),
        label: Text(
          done
              ? '카드 제거 완료'
              : '카드 제거 서비스  ${RunNotifier.shopRemovalCost} G',
          style: TextStyle(
              color: fgColor, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: borderColor, width: 0.8),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

/// 덱에서 제거할 카드를 선택하는 바텀시트.
class CardRemovalSheet extends StatelessWidget {
  final List<GameCard> deck;
  final RunNotifier notifier;

  const CardRemovalSheet(
      {super.key, required this.deck, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final sorted = [...deck]..sort((a, b) => a.name.compareTo(b.name));

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFF1A130A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Color(0xFF5A4020))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            ShopStrings.removalSheetTitle,
            style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            ShopStrings.removalSheetSubtitle,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF3D3020)),
          Expanded(
            child: sorted.isEmpty
                ? const Center(
                    child: Text('덱이 비어 있습니다.',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 13)),
                  )
                : ListView.builder(
                    itemCount: sorted.length,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemBuilder: (_, i) {
                      final card   = sorted[i];
                      final accent = RewardColors.forEffectType(card.effectType);
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        leading: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: accent.withValues(alpha: 0.6)),
                          ),
                          child: Center(
                            child: Text(
                              card.cost == -1 ? 'X' : '${card.cost}',
                              style: TextStyle(
                                  color: accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        title: Text(card.name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                        subtitle: Text(
                          RewardStrings.cardEffect(card),
                          style: TextStyle(
                              color: accent.withValues(alpha: 0.7),
                              fontSize: 11),
                        ),
                        trailing: const Icon(Icons.remove_circle_outline,
                            size: 22, color: Color(0xFFEF5350)),
                        onTap: () {
                          notifier.removeCardInShop(card);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
