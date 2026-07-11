import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/app_state.dart';
import '../../models/scan_record.dart';
import '../../widgets/shared_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'All';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  final _filters = ['All', 'Registered', 'Not found', 'Unknown'];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filtered = _applyFilter(state.history);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.headerGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (Navigator.canPop(context))
                          GestureDetector(
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
                        if (Navigator.canPop(context)) const SizedBox(width: 14),
                        Text(
                          'Scan History',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                              ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            '${state.totalScans} scans',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                        decoration: const InputDecoration(
                          hintText: 'Search medicines...',
                          hintStyle: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppTheme.textLight,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Filter Chips ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: f,
                            selected: _filter == f,
                            onTap: () => setState(() => _filter = f),
                            count: _countForFilter(state.history, f),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),

          // ── Summary row ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${filtered.length} result${filtered.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                ),
              ],
            ),
          ),

          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(filter: _filter)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => ScanHistoryTile(
                      record: filtered[i],
                      onTap: () {
                        context.read<AppState>().setLastScan(filtered[i]);
                        Navigator.pushNamed(context, '/result');
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<ScanRecord> _applyFilter(List<ScanRecord> records) {
    var list = records;
    if (_filter != 'All') {
      final statusMap = {
        'Registered': VerificationStatus.registered,
        'Not found': VerificationStatus.notFound,
        'Unknown': VerificationStatus.unknown,
      };
      list = list.where((r) => r.status == statusMap[_filter]).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((r) =>
              r.medicineName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              r.manufacturer.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

  int _countForFilter(List<ScanRecord> records, String filter) {
    if (filter == 'All') return records.length;
    final statusMap = {
      'Registered': VerificationStatus.registered,
      'Not found': VerificationStatus.notFound,
      'Unknown': VerificationStatus.unknown,
    };
    return records.where((r) => r.status == statusMap[filter]).length;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int count;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(50),
          boxShadow: selected ? AppTheme.primaryShadow : AppTheme.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withOpacity(0.25)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppTheme.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            filter == 'All' ? 'No scans yet' : 'No $filter medicines',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            filter == 'All'
                ? 'Start scanning medicines to see\nyour history here'
                : 'No medicines with this status\nin your scan history',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}