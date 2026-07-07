import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const List<Map<String, String>> _steps = [
    {
      'title': 'Prepare the Medicine',
      'description':
          'Ensure the medicine packaging is clean and all labels are visible.',
    },
    {
      'title': 'Take a Clear Photo',
      'description':
          'Use good lighting and ensure the entire packaging is visible in the frame.',
    },
    {
      'title': 'AI Analysis',
      'description':
          'Our AI will analyze the packaging, extract text, and verify against our database.',
    },
    {
      'title': 'Review Results',
      'description':
          'Check the verification status and follow the recommended actions.',
    },
  ];

  static const List<Map<String, dynamic>> _results = [
    {
      'label': 'Verified',
      'description':
          'The medicine is authentic and registered in our database. Safe to use as directed.',
      'color': Color(0xFF16A34A),
      'bgColor': Color(0xFFDCFCE7),
      'borderColor': Color(0xFFBBF7D0),
      'icon': Icons.check_circle_outline,
    },
    {
      'label': 'Suspicious',
      'description':
          'Inconsistencies detected in packaging or labels. Verify with a pharmacist before use.',
      'color': Color(0xFFD97706),
      'bgColor': Color(0xFFFEF9C3),
      'borderColor': Color(0xFFFDE68A),
      'icon': Icons.warning_amber_outlined,
    },
    {
      'label': 'Counterfeit',
      'description':
          'Strong indicators of counterfeit medicine. DO NOT USE. Report immediately.',
      'color': Color(0xFFDC2626),
      'bgColor': Color(0xFFFEE2E2),
      'borderColor': Color(0xFFFECACA),
      'icon': Icons.cancel_outlined,
    },
  ];

  static const List<String> _reportingSteps = [
    'Use the "Report Suspicious Drug" feature',
    'Provide clear photos and detailed information',
    'Include location where the medicine was purchased',
    'Do not consume the medicine',
  ];

  static const List<String> _bestPractices = [
    'Always purchase medicines from licensed pharmacies',
    'Check expiry dates before purchasing',
    'Look for proper seals and packaging quality',
    'Be wary of unusually cheap prices',
    'Verify batch numbers and manufacturer details',
  ];

  // ── Brand colours ──────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF4F46E5);
  static const Color _bgPage = Color(0xFFEEF2FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        backgroundColor: _bgPage,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Help & Instructions',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── Welcome card ──────────────────────────────────────────────────
          _Card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to MediVerify',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'MediVerify uses advanced AI technology to help you verify the authenticity of medicines and protect yourself from counterfeit drugs.',
                        style:
                            TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── How to Scan ───────────────────────────────────────────────────
          const _SectionHeader(
            icon: Icons.camera_alt_outlined,
            label: 'How to Scan Medicine',
          ),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              children: List.generate(_steps.length, (i) {
                final step = _steps[i];
                final isLast = i == _steps.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: _primary,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step['title']!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              step['description']!,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black54),
                            ),
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

          // ── Understanding Results ─────────────────────────────────────────
          const _SectionHeader(
            icon: Icons.description_outlined,
            label: 'Understanding Verification Results',
          ),
          const SizedBox(height: 12),
          ..._results.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: r['bgColor'] as Color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: r['borderColor'] as Color),
                ),
                padding: const EdgeInsets.all(14),
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
                            style: TextStyle(
                              color: r['color'] as Color,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            r['description'] as String,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Reporting suspicious medicines ────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        color: Color(0xFFDC2626), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Reporting Suspicious Medicines',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'If you encounter suspicious or counterfeit medicine:',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                ..._reportingSteps.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(s,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black87)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Best Practices ────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFEFCE8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: Color(0xFFD97706), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Best Practices',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._bestPractices.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✓  ',
                          style: TextStyle(
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(p,
                              style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Need More Help ────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            padding: const EdgeInsets.all(16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_outline, color: _primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Need More Help?',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Our support team is here to assist you with any questions or concerns.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                SizedBox(height: 14),
                _ContactTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: 'support@mediverify.org',
                ),
                SizedBox(height: 10),
                _ContactTile(
                  icon: Icons.phone_outlined,
                  label: 'Hotline',
                  value: '+255 123 456 789',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Back to Home button ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Back to Home',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),

          const SizedBox(height: 32),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
        Icon(icon, color: const Color(0xFF4F46E5), size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF4F46E5), size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black45)),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}