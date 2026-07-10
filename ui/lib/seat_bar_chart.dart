import 'package:flutter/material.dart';
import '../Appcolors.dart';

/// A small bar chart (no external chart package needed) showing
/// assembly seats per party, with gridlines like 0/30/60/90/120.
class SeatBarChart extends StatelessWidget {
  final Map<String, int> seatsByParty;
  final double barsHeight;

  const SeatBarChart({
    super.key,
    required this.seatsByParty,
    this.barsHeight = 160,
  });

  int _niceMax(int rawMax) {
    if (rawMax <= 0) return 30;
    const step = 30;
    return ((rawMax / step).ceil()) * step;
  }

  @override
  Widget build(BuildContext context) {
    final entries = seatsByParty.entries.toList();
    final maxVal = _niceMax(
      entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b),
    );
    final gridSteps = [0, maxVal ~/ 4, maxVal ~/ 2, (maxVal * 3) ~/ 4, maxVal];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Y-axis labels, top (max) to bottom (0).
            SizedBox(
              width: 30,
              height: barsHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: gridSteps.reversed
                    .map((v) => Text(
                          '$v',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(width: 10),
            // Chart area: gridlines behind, bars in front.
            Expanded(
              child: SizedBox(
                height: barsHeight,
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        gridSteps.length,
                        (_) => Container(
                          height: 1,
                          color: AppColors.textMuted.withOpacity(0.15),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: entries.map((e) {
                        final fraction = maxVal == 0 ? 0.0 : e.value / maxVal;
                        final barHeight =
                            (barsHeight - 22) * fraction.clamp(0.0, 1.0);
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${e.value}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 34,
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: AppColors.colorForParty(e.key),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Party labels under each bar, aligned with the chart area above.
        Row(
          children: [
            const SizedBox(width: 40),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: seatsByParty.keys
                    .map((party) => SizedBox(
                          width: 34,
                          child: Text(
                            party,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}