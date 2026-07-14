import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const List<Map<String, String>> _steps = [
    {
      'title': 'Prepare the Medicine',
      'description':
          'Make sure the packaging is clean and the printed label is fully visible.',
    },
    {
      'title': 'Take a Clear Photo',
      'description':
          'Use good lighting and fit the whole label or box inside the frame.',
    },
    {
      'title': 'Automatic Check',
      'description':
          'The app reads the label and checks it against the TMDA register of approved products.',
    },
    {
      'title': 'Review the Result',
      'description':
          'See whether the product is on the register and follow the recommended action.',
    },
  ];

  static const List<Map<String, dynamic>> _results = [
    {
      'label': 'Registered',
      'description':
          'The product matches a record on the TMDA register. Registration confirms approval — still check the packaging condition and expiry before use.',
      'color': AppTheme.success,
      'icon': Icons.verified_rounded,
    },
    {
      'label': 'Not on register',
      'description':
          'No matching product was found on the TMDA register. This does not prove it is fake — but do not use it until confirmed, and please report it.',
      'color': AppTheme.warning,
      'icon': Icons.search_off_rounded,
    },
    {
      'label': 'Unknown',
      'description':
          'The check could not be completed (unclear photo or unreadable label). Retake the photo or consult a pharmacist.',
      'color': AppTheme.textSecondary,
      'icon': Icons.help_rounded,
    },
  ];

  static const List<String> _reportingSteps = [
    'Use the "Report Suspicious Medicine" feature',
    'Provide clear photos and detailed information',
    'Include where the medicine was purchased',
    'Do not consume the medicine',
  ];

  static const List<String> _bestPractices = [
    'Always buy medicines from licensed pharmacies',
    'Check expiry dates before purchasing',
    'Look for proper seals and packaging quality',
    'Be wary of unusually cheap prices',
    'Verify batch numbers and manufacturer details',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          // ── Pinned header (matches the rest of the app) ───────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppTheme.headerGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (Navigator.canPop(context)) ...[
                          GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          'Help & Guide',
                          style:
                              Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How to use MediVerify and understand your results',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Scrolling content ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                // Welcome card
                _Card(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.shield_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to MediVerify',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'MediVerify reads your medicine\'s packaging and checks it against the TMDA register of approved products, helping you spot medicines that may not be legitimate.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _SectionHeader(
                    icon: Icons.camera_alt_rounded,
                    label: 'How to Scan Medicine'),
                const SizedBox(height: 12),
                _Card(
                  child: Column(
                    children: List.generate(_steps.length, (i) {
                      final step = _steps[i];
                      final isLast = i == _steps.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(step['title']!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 3),
                                  Text(step['description']!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 24),
                _SectionHeader(
                    icon: Icons.fact_check_rounded,
                    label: 'Understanding Your Results'),
                const SizedBox(height: 12),
                ..._results.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: (r['color'] as Color).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: (r['color'] as Color).withOpacity(0.25)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(r['icon'] as IconData,
                              color: r['color'] as Color, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r['label'] as String,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: r['color'] as Color),
                                ),
                                const SizedBox(height: 4),
                                Text(r['description'] as String,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                // Reporting card
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.report_problem_rounded,
                              color: AppTheme.danger, size: 22),
                          const SizedBox(width: 8),
                          Text('Reporting Suspicious Medicines',
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'If you find a suspicious medicine or one that is not on the register:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      ..._reportingSteps.map((s) => _Bullet(text: s)),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                // Best practices
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppTheme.primary.withOpacity(0.20)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_rounded,
                              color: AppTheme.primary, size: 22),
                          const SizedBox(width: 8),
                          Text('Best Practices',
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._bestPractices.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: AppTheme.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(p,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppTheme.textPrimary)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _SectionHeader(
                    icon: Icons.verified_user_rounded,
                    label: 'Official TMDA Channels'),
                const SizedBox(height: 12),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'The Tanzania Medicines and Medical Devices Authority (TMDA) regulates medicines and receives reports of suspicious products.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      const _ContactTile(
                        icon: Icons.public_rounded,
                        label: 'Website',
                        value: 'www.tmda.go.tz',
                      ),
                      const SizedBox(height: 10),
                      const _ContactTile(
                        icon: Icons.email_rounded,
                        label: 'Email',
                        value: 'info@tmda.go.tz',
                      ),
                      const SizedBox(height: 10),
                      const _ContactTile(
                        icon: Icons.phone_rounded,
                        label: 'Toll-free',
                        value: '0800 110 084',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _SectionHeader(
                    icon: Icons.privacy_tip_rounded,
                    label: 'Your Privacy'),
                const SizedBox(height: 12),
                // The consent sheet is shown once, before the first scan. It has
                // to be readable again afterwards — a disclosure you can never
                // re-open is not really a disclosure.
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What happens to your data when you scan:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      const _Bullet(
                        text:
                            'Your photo is sent to our server and read by Google Gemini, an AI service, to pull the medicine name and registration number off the pack.',
                      ),
                      const _Bullet(
                        text:
                            'Your scan history is stored on this phone only. Clear it any time from the History screen — swipe a scan away, or use the bin icon to clear all.',
                      ),
                      const _Bullet(
                        text:
                            'If you submit a report, the pharmacy details you type are shared with TMDA reviewers. Nothing else is.',
                      ),
                      const _Bullet(
                        text:
                            'We never ask for your name, phone number or GPS location.',
                      ),
                    ],
                  ),
                ),

                if (Navigator.canPop(context)) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 22),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.headlineMedium),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ContactTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      )),
              Text(value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primary,
                        fontSize: 15,
                      )),
            ],
          ),
        ],
      ),
    );
  }
}
