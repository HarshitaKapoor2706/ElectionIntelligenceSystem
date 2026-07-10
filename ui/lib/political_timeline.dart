import 'package:flutter/material.dart';
import '../Appcolors.dart';
import '../state_data.dart';

/// Horizontal-ish timeline: 2013 -> BJP -> 2018 -> INC -> 2023 -> BJP
class PoliticalTimeline extends StatelessWidget {
  final List<TimelinePoint> points;
  const PoliticalTimeline({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(points.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector arrow between two points.
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: AppColors.textMuted.withOpacity(0.3),
            ),
          );
        }
        final p = points[i ~/ 2];
        final color = AppColors.colorForParty(p.party);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color, width: 1),
              ),
              child: Text(
                p.party,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              p.year,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }),
    );
  }
}