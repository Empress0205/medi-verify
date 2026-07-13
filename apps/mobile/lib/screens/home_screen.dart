import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/app_state.dart';
import '../../widgets/shared_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      // Pinned header + scrolling content below it (header stays put).
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ── Stats Card ─────────────────────────────────────────────
                  StatsCard(
                    scans: state.totalScans,
                    registered: state.registeredCount,
                    needsAttention: state.needsAttentionCount,
                  ),

                  const SizedBox(height: 20),

                  // ── Quick Actions ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        QuickActionCard(
                          icon: Icons.qr_code_scanner_rounded,
                          iconColor: Colors.white,
                          iconBg: AppTheme.primary,
                          title: 'Scan Medicine',
                          subtitle: 'Check TMDA registration instantly',
                          onTap: () => Navigator.pushNamed(context, '/scan'),
                        ),
                        QuickActionCard(
                          icon: Icons.history_rounded,
                          iconColor: Colors.white,
                          iconBg: AppTheme.info,
                          title: 'View History',
                          subtitle: 'See your past registration checks',
                          onTap: () => Navigator.pushNamed(context, '/history'),
                        ),
                        QuickActionCard(
                          icon: Icons.report_problem_rounded,
                          iconColor: Colors.white,
                          iconBg: AppTheme.danger,
                          title: 'Report Suspicious',
                          subtitle: 'Flag a medicine for TMDA review',
                          onTap: () => Navigator.pushNamed(context, '/report'),
                        ),
                        QuickActionCard(
                          icon: Icons.help_rounded,
                          iconColor: Colors.white,
                          iconBg: const Color(0xFF9B59B6),
                          title: 'Help & Guide',
                          subtitle: 'Learn how to use the app',
                          onTap: () => Navigator.pushNamed(context, '/help'),
                        ),
                      ],
                    ),
                  ),

                  // ── Stay Protected Banner ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Stay Protected!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('🛡️',
                                        style: TextStyle(fontSize: 20)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Check that your medicines are registered with TMDA before use. If a product is not on the register, be cautious and report it.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.white.withOpacity(0.92),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.health_and_safety_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Recent Scans ───────────────────────────────────────────
                  if (state.history.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Scans',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/history'),
                            child: Text(
                              'See All',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: state.history
                            .take(3)
                            .map((r) => ScanHistoryTile(
                                  record: r,
                                  onTap: () {
                                    context.read<AppState>().setLastScan(r);
                                    Navigator.pushNamed(context, '/result');
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pinned header ────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MediVerify',
                    style:
                        Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Check medicines on the TMDA register',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                ],
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
