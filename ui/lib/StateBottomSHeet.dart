import 'package:flutter/material.dart';
import '../Appcolors.dart';
import '../state_data.dart';
import 'political_timeline.dart';
import 'seat_bar_chart.dart';

/// Call this instead of showModalBottomSheet directly — it sets up the
/// Google-Maps-style draggable sheet (swipe up to expand, swipe down /
/// tap outside to dismiss).
Future<void> showStateBottomSheet(BuildContext context, String stateName) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (_) => StateBottomSheet(stateName: stateName),
  );
}

class StateBottomSheet extends StatelessWidget {
  final String stateName;
  const StateBottomSheet({super.key, required this.stateName});

  @override
  Widget build(BuildContext context) {
    // TODO: swap mockStateInfo(stateName) for a real fetch from
    // GET $backendBaseUrl/state/{stateName} once your backend is live.
    final info = mockStateInfo(stateName);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.18,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stateName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // ---- Current CM highlight card ----
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Chief Minister',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            info.currentCM.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${info.currentCM.party} · ${info.currentCM.years}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ---- State snapshot stats ----
              _SectionTitle('State Snapshot'),
              Row(
                children: [
                  Expanded(child: _StatChip(label: 'Population', value: info.population)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatChip(label: 'Literacy', value: info.literacy)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatChip(label: 'Urban %', value: info.urbanPercent)),
                ],
              ),

              const SizedBox(height: 22),

              // ---- Past CMs ----
              _SectionTitle('Recent Chief Ministers'),
              ...info.pastCMs.map((cm) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PastCmTile(cm: cm),
                  )),

              const SizedBox(height: 10),

              // ---- Political timeline ----
              _SectionTitle('Political Timeline'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: PoliticalTimeline(points: info.timeline),
              ),

              const SizedBox(height: 22),

              // ---- Seat distribution ----
              _SectionTitle('Assembly Seat Distribution'),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SeatBarChart(seatsByParty: info.seatDistribution),
              ),

              const SizedBox(height: 22),

              // ---- Public sentiment ----
              _SectionTitle('Public Sentiment'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insights_rounded, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        info.publicSentiment,
                        style: const TextStyle(color: AppColors.textDark, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ---- Key issues ----
              _SectionTitle('Key Issues'),
              ...info.keyIssues.map((issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.circle, size: 6, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            issue,
                            style: const TextStyle(color: AppColors.textDark, fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 22),

              // ---- Latest news for this state ----
              _SectionTitle('Latest News'),
              ...info.latestNews.map((n) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.newspaper_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(n,
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.textDark))),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _PastCmTile extends StatelessWidget {
  final CMRecord cm;
  const _PastCmTile({required this.cm});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.colorForParty(cm.party);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cm.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '${cm.party} · ${cm.years}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}