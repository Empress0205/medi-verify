import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/scan_record.dart';

// ─── Gradient Header ──────────────────────────────────────────────────────────
class GradientHeader extends StatelessWidget {
  final Widget child;
  final double height;
  const GradientHeader({super.key, required this.child, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: child,
    );
  }
}

// ─── Stats Card ───────────────────────────────────────────────────────────────
/// Home "Protection Stats".
///
/// [registered] counts only scans that are on the register AND in date — an
/// expired pack is not a win, so it is counted under [needsAttention] instead.
/// Counting it as "Registered" was the same false reassurance the history tile
/// used to give.
class StatsCard extends StatelessWidget {
  final int scans;
  final int registered;
  final int needsAttention;
  const StatsCard({
    super.key,
    required this.scans,
    required this.registered,
    required this.needsAttention,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            'Your Protection Stats',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                    value: scans, label: 'Scans', color: AppTheme.primary),
              ),
              _Divider(),
              Expanded(
                child: _StatItem(
                    value: registered,
                    label: 'Registered',
                    color: AppTheme.success),
              ),
              _Divider(),
              Expanded(
                child: _StatItem(
                  value: needsAttention,
                  label: 'Needs attention',
                  color: needsAttention > 0
                      ? AppTheme.warning
                      : AppTheme.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: AppTheme.divider,
    );
  }
}

class _StatItem extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _StatItem({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 30,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.2,
              ),
        ),
      ],
    );
  }
}

// ─── Quick Action Card ────────────────────────────────────────────────────────
class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.textLight,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Verdict Badge ────────────────────────────────────────────────────────────
/// Colour + icon for a [ScanVerdict]. Shared by the badge, the history tile
/// and the home stats so a scan can never look green on one surface and red on
/// another. Only [ScanVerdict.registered] is allowed to be green.
class VerdictStyle {
  final Color color;
  final IconData icon;
  const VerdictStyle(this.color, this.icon);

  static VerdictStyle of(ScanVerdict v) {
    switch (v) {
      case ScanVerdict.expired:
        return const VerdictStyle(AppTheme.danger, Icons.dangerous_rounded);
      case ScanVerdict.lapsed:
        return const VerdictStyle(AppTheme.warning, Icons.gpp_maybe_rounded);
      case ScanVerdict.checkExpiry:
        return const VerdictStyle(
            AppTheme.warning, Icons.event_busy_rounded);
      case ScanVerdict.expiringSoon:
        return const VerdictStyle(AppTheme.warning, Icons.schedule_rounded);
      case ScanVerdict.registered:
        return const VerdictStyle(AppTheme.success, Icons.verified_rounded);
      case ScanVerdict.notFound:
        return const VerdictStyle(AppTheme.warning, Icons.search_off_rounded);
      case ScanVerdict.unknown:
        return const VerdictStyle(AppTheme.textSecondary, Icons.help_rounded);
      case ScanVerdict.notMedicine:
        return const VerdictStyle(AppTheme.info, Icons.image_search_rounded);
    }
  }
}

/// The badge shown on history tiles and the result screen's details card.
///
/// It renders the [ScanVerdict], NOT the raw register status — an expired pack
/// that happens to be registered must never carry a reassuring green
/// "Registered" badge.
class VerdictBadge extends StatelessWidget {
  final ScanRecord record;
  final bool large;
  const VerdictBadge({super.key, required this.record, this.large = false});

  @override
  Widget build(BuildContext context) {
    final style = VerdictStyle.of(record.verdict);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: style.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, color: style.color, size: large ? 18 : 14),
          const SizedBox(width: 5),
          Text(
            record.verdictLabel,
            style: TextStyle(
              color: style.color,
              fontWeight: FontWeight.w600,
              fontSize: large ? 15 : 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scan History Tile ────────────────────────────────────────────────────────
class ScanHistoryTile extends StatelessWidget {
  final ScanRecord record;
  final VoidCallback? onTap;

  const ScanHistoryTile({super.key, required this.record, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Everything on this tile follows the VERDICT, not the register status.
    // A registered-but-expired pack has to read as expired here too — showing
    // it as green "Registered" in history would undo the safety layer.
    final style = VerdictStyle.of(record.verdict);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: style.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.medication_rounded,
                color: style.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.medicineName,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    record.manufacturer,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _timeAgo(record.scannedAt),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: AppTheme.textLight,
                            ),
                      ),
                      // Keep the registration fact visible when the badge is
                      // owned by a safety concern, so the tile isn't misread
                      // as "this medicine is not registered".
                      if (record.isOnRegister &&
                          record.verdict != ScanVerdict.registered) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded,
                            size: 12, color: AppTheme.success),
                        const SizedBox(width: 3),
                        Text(
                          'On register',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontSize: 12,
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            VerdictBadge(record: record),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── Custom Bottom Nav Bar ────────────────────────────────────────────────────
class MediBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onScanTap;

  const MediBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'History',
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              const SizedBox(width: 72), // space for FAB
              _NavItem(
                icon: Icons.flag_rounded,
                label: 'Report',
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.help_outline_rounded,
                label: 'Help',
                selected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
          Positioned(
            top: -28,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onScanTap,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.primaryShadow,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? AppTheme.primary : AppTheme.textLight,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.primary : AppTheme.textLight,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}