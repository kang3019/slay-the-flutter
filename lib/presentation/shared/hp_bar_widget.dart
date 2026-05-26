import 'package:flutter/material.dart';

/// 체력·방어도를 시각화하는 재사용 HP 바.
class HpBarWidget extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  final Color barColor;
  final int block;

  const HpBarWidget({
    super.key,
    required this.label,
    required this.current,
    required this.max,
    required this.barColor,
    this.block = 0,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const Spacer(),
            Text(
              '$current / $max',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            if (block > 0) ...[
              const SizedBox(width: 8),
              Text(
                '🛡 $block',
                style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 12),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: Colors.grey[800],
            color: barColor,
          ),
        ),
      ],
    );
  }
}
