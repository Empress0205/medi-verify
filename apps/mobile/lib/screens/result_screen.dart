import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/app_state.dart';
import '../../models/scan_record.dart';
import '../../widgets/shared_widgets.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final record = context.watch<AppState>().lastScan;
    if (record == null) {
      return const Scaffold(body: Center(child: Text('No scan data')));
    }

    final isRegistered = record.status == VerificationStatus.registered;
    final isNotFound = record.status == VerificationStatus.notFound;

    Gradient headerGradient;
    IconData statusIcon;
    String statusTitle;
    String statusMessage;

    if (isRegistered) {
      headerGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF27AE60), Color(0xFF1E8449)],
      );
      statusIcon = Icons.verified_rounded;
      statusTitle = 'Registered with TMDA';
      statusMessage =
          'This product matches a record on the TMDA register. Registration confirms the product is approved — still check the packaging condition and expiry date before use.';
    } else if (isNotFound) {
      headerGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF5A623), Color(0xFFD4891C)],
      );
      statusIcon = Icons.search_off_rounded;
      statusTitle = 'Not Found on Register';
      statusMessage =
          'We could not find this product on the TMDA register. This does not prove it is fake — it may be newly registered or the label may have been misread. Be cautious: do not use it until confirmed, and please report it.';
    } else {
      headerGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF90A4AE), Color(0xFF607D8B)],
      );
      statusIcon = Icons.help_rounded;
      statusTitle = 'Check Inconclusive';
      statusMessage =
          'We could not complete the register check for this medicine. Try scanning again with a clearer photo, or consult a pharmacist.';
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                // ── Result Header ────────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: headerGradient,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                      child: Column(
                        children: [
                          // Back button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Status icon
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(statusIcon, color: Colors.white, size: 48),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            statusTitle,
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            statusMessage,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.88),
                                  height: 1.5,
                                  fontSize: 13,
                                ),
                          ),
                          const SizedBox(height: 16),
                          // Confidence score
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.psychology_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Match confidence: ${(record.confidenceScore * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
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

                // ── Medicine Details ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _DetailsCard(record: record),
                ),

                // ── What the genuine product should look like ─────────────
                if (record.physicalDescription != null &&
                    record.physicalDescription!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _LooksCard(text: record.physicalDescription!),
                  ),
                ],

                // ── Notes if any ─────────────────────────────────────────
                if (record.notes != null) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _NotesCard(notes: record.notes!),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Action Buttons ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (isNotFound)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.warning,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/report'),
                            icon: const Icon(Icons.report_rounded),
                            label: const Text('Report This Medicine'),
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/scan'),
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: const Text('Scan Another Medicine'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: const BorderSide(color: AppTheme.divider),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () =>
                              Navigator.pushNamedAndRemoveUntil(
                                  context, '/main', (_) => false),
                          icon: const Icon(Icons.home_rounded),
                          label: const Text('Back to Home'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final ScanRecord record;
  const _DetailsCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Medicine Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              StatusBadge(status: record.status),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.divider),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.medication_rounded,
            label: 'Medicine Name',
            value: record.medicineName,
          ),
          _DetailRow(
            icon: Icons.business_rounded,
            label: 'Manufacturer',
            value: record.manufacturer,
          ),
          if (record.regNo != null)
            _DetailRow(
              icon: Icons.verified_user_rounded,
              label: 'TMDA Reg. No.',
              value: record.regNo!,
            ),
          if (record.registrationStatus != null)
            _DetailRow(
              icon: Icons.fact_check_rounded,
              label: 'Registration',
              value: record.registrationStatus!,
            ),
          if (record.activeIngredient != null)
            _DetailRow(
              icon: Icons.science_rounded,
              label: 'Active Ingredient',
              value: record.activeIngredient!,
            ),
          _DetailRow(
            icon: Icons.numbers_rounded,
            label: 'Batch Number',
            value: record.batchNumber,
          ),
          _DetailRow(
            icon: Icons.calendar_month_rounded,
            label: 'Expiry Date',
            value: record.expiryDate,
          ),
          _DetailRow(
            icon: Icons.access_time_rounded,
            label: 'Scanned At',
            value: _formatDate(record.scannedAt),
            isLast: true,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} at $h:$min $ampm';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Shows the register's physical description of the genuine product — an
// anti-counterfeit aid so the user can compare against what's in their hand.
class _LooksCard extends StatelessWidget {
  final String text;
  const _LooksCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_rounded,
                  color: AppTheme.success, size: 18),
              const SizedBox(width: 8),
              Text(
                'How the genuine product looks',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.success,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  height: 1.5,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Compare this with your medicine. If it looks different, report it.',
            style: TextStyle(
              fontSize: 11.5,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String notes;
  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    // Neutral styling — this note carries the backend message for ANY outcome
    // (registered / not found), so it must not look like a red warning.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.textSecondary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              notes,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}