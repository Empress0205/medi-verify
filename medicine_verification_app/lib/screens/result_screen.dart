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

    final isVerified = record.status == VerificationStatus.verified;
    final isCounterfeit = record.status == VerificationStatus.counterfeit;
    final isUnknown = record.status == VerificationStatus.unknown;

    Color headerColor;
    Gradient headerGradient;
    IconData statusIcon;
    String statusTitle;
    String statusMessage;

    if (isVerified) {
      headerColor = AppTheme.success;
      headerGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF27AE60), Color(0xFF1E8449)],
      );
      statusIcon = Icons.verified_rounded;
      statusTitle = 'Medicine Verified!';
      statusMessage =
          'This medicine has been authenticated and is safe for use. All details match our database.';
    } else if (isCounterfeit) {
      headerColor = AppTheme.danger;
      headerGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE05C2A), Color(0xFFC03A10)],
      );
      statusIcon = Icons.dangerous_rounded;
      statusTitle = 'Counterfeit Detected!';
      statusMessage =
          'WARNING: This medicine appears to be counterfeit. Do not consume it. Please report it immediately.';
    } else {
      headerColor = AppTheme.warning;
      headerGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF5A623), Color(0xFFD4891C)],
      );
      statusIcon = Icons.help_rounded;
      statusTitle = 'Verification Inconclusive';
      statusMessage =
          'We could not definitively verify this medicine. Exercise caution and consult a pharmacist.';
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                                  'AI Confidence: ${record.confidenceScore.toStringAsFixed(1)}%',
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
                      if (isCounterfeit)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.danger,
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

class _NotesCard extends StatelessWidget {
  final String notes;
  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              notes,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.danger,
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