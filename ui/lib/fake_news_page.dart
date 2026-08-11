import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Appcolors.dart';
import '../state_data.dart' show backendBaseUrl;

class _CheckResult {
  final String verdict;
  final String explanation;
  final String source; // "news_verified" or "pattern_only"
  const _CheckResult({required this.verdict, required this.explanation, required this.source});
}

class FakeNewsDetectorPage extends StatefulWidget {
  const FakeNewsDetectorPage({super.key});

  @override
  State<FakeNewsDetectorPage> createState() => _FakeNewsDetectorPageState();
}

class _FakeNewsDetectorPageState extends State<FakeNewsDetectorPage> {
  final TextEditingController _controller = TextEditingController();
  _CheckResult? _result;
  String? _error;
  bool _checking = false;

  Future<void> _checkClaim() async {
    final claim = _controller.text.trim();
    if (claim.isEmpty || _checking) return;
    setState(() {
      _checking = true;
      _result = null;
      _error = null;
    });

    try {
      final res = await http
          .post(
            Uri.parse('$backendBaseUrl/fake-news-check'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'claim': claim}),
          )
          .timeout(const Duration(seconds: 25));

      if (res.statusCode != 200) {
        throw Exception('Request failed (${res.statusCode})');
      }

      final data = jsonDecode(res.body);
      setState(() {
        _checking = false;
        _result = _CheckResult(
          verdict: data['verdict'] as String,
          explanation: data['explanation'] as String,
          source: data['source'] as String,
        );
      });
    } catch (e) {
      setState(() {
        _checking = false;
        _error = "Couldn't reach the detector. ($e)";
      });
    }
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
              'Paste a claim you\'ve seen online. We check it against '
              'live election news, and fall back to pattern analysis '
              'when there\'s nothing recent to compare it to.',
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
            if (_error != null) _ErrorCard(message: _error!),
            if (_result != null) _VerdictCard(result: _result!),
          ],
        ),
      ),
    );
  }
}

class _VerdictCard extends StatelessWidget {
  final _CheckResult result;
  const _VerdictCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final v = result.verdict.toLowerCase();
    late Color color;
    late IconData icon;

    if (v.contains('true')) {
      color = const Color(0xFF2ECC71);
      icon = Icons.check_circle_rounded;
    } else if (v.contains('false')) {
      color = const Color(0xFFE24B4A);
      icon = Icons.cancel_rounded;
    } else {
      color = const Color(0xFFEF9F27);
      icon = Icons.help_rounded;
    }

    final isNewsVerified = result.source == 'news_verified';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.verdict,
                      style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.explanation,
                      style: const TextStyle(color: AppColors.textDark, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isNewsVerified ? Icons.newspaper_rounded : Icons.psychology_alt_rounded,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  isNewsVerified ? 'Checked against live news' : 'Pattern analysis (no matching news found)',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: AppColors.textDark, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}