import 'package:flutter/material.dart';
import '../Appcolors.dart';

enum _Verdict { none, likelyTrue, likelyFalse, unverified }

class FakeNewsDetectorPage extends StatefulWidget {
  const FakeNewsDetectorPage({super.key});

  @override
  State<FakeNewsDetectorPage> createState() => _FakeNewsDetectorPageState();
}

class _FakeNewsDetectorPageState extends State<FakeNewsDetectorPage> {
  final TextEditingController _controller = TextEditingController();
  _Verdict _verdict = _Verdict.none;
  String _reason = '';
  bool _checking = false;

  /// TODO: replace with a real call to your FastAPI `/fake-news-check`
  /// endpoint (claim + recent news -> Gemini -> verdict), per your
  /// architecture doc. This is a placeholder so the UI works standalone.
  Future<void> _checkClaim() async {
    final claim = _controller.text.trim();
    if (claim.isEmpty || _checking) return;
    setState(() {
      _checking = true;
      _verdict = _Verdict.none;
    });

    await Future.delayed(const Duration(milliseconds: 900));

    setState(() {
      _checking = false;
      _verdict = _Verdict.likelyFalse;
      _reason = 'No trusted source confirms this claim. This is placeholder '
          'output — connect your backend to replace it with a real check.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                const Icon(Icons.fact_check_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Fake News Detector',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Paste a claim you\'ve seen online to check it against recent, '
              'trusted election news.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '"Delhi election has been cancelled."',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checking ? null : _checkClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _checking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Check claim', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 20),
            if (_verdict != _Verdict.none) _VerdictCard(verdict: _verdict, reason: _reason),
          ],
        ),
      ),
    );
  }
}

class _VerdictCard extends StatelessWidget {
  final _Verdict verdict;
  final String reason;
  const _VerdictCard({required this.verdict, required this.reason});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late IconData icon;
    late String label;

    switch (verdict) {
      case _Verdict.likelyTrue:
        color = const Color(0xFF2ECC71);
        icon = Icons.check_circle_rounded;
        label = 'Likely true';
        break;
      case _Verdict.likelyFalse:
        color = const Color(0xFFE24B4A);
        icon = Icons.cancel_rounded;
        label = 'Likely false';
        break;
      case _Verdict.unverified:
      case _Verdict.none:
        color = const Color(0xFFEF9F27);
        icon = Icons.help_rounded;
        label = 'Unverified';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: const TextStyle(color: AppColors.textDark, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}