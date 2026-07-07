import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/scan_record.dart';
import '../../services/app_state.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Pharmacy location (user fills these) ───────────────────────────────────
  final _regionCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _pharmacyCtrl = TextEditingController();

  // ── Description (user fills this) ─────────────────────────────────────────
  final _descCtrl = TextEditingController();

  String _selectedCategory = 'Packaging Issues';
  bool _submitted = false;
  bool _isLoading = false;

  final _categories = [
    'Packaging Issues',
    'Wrong Color/Smell/Taste',
    'Incorrect Dosage',
    'Suspicious Source',
    'Expired Medicine',
    'Other',
  ];

  @override
  void dispose() {
    _regionCtrl.dispose();
    _streetCtrl.dispose();
    _pharmacyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return const _SuccessScreen();

    // Pull the last scan from AppState — this has all the pre-filled data
    final record = context.read<AppState>().lastScan;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE05C2A), Color(0xFFC03A10)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 20),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.report_problem_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Report Suspicious\nMedicine',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 26,
                              height: 1.2,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Help protect others by reporting counterfeit medicines.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Section 1: Medicine Info (pre-filled, read-only) ────
                    _sectionLabel(context, 'Medicine Information'),
                    const SizedBox(height: 6),
                    // Subtle note so user knows this was auto-filled
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 13, color: AppTheme.primary),
                        SizedBox(width: 5),
                        Text(
                          'Auto-filled from your scan',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (record != null) ...[
                      _ReadOnlyInfoCard(
                        items: [
                          _InfoItem(
                            icon: Icons.medication_rounded,
                            label: 'Medicine Name',
                            value: record.medicineName,
                          ),
                          _InfoItem(
                            icon: Icons.business_rounded,
                            label: 'Manufacturer',
                            value: record.manufacturer,
                          ),
                          _InfoItem(
                            icon: Icons.numbers_rounded,
                            label: 'Batch Number',
                            value: record.batchNumber,
                          ),
                          _InfoItem(
                            icon: Icons.calendar_month_rounded,
                            label: 'Expiry Date',
                            value: record.expiryDate,
                          ),
                        ],
                      ),
                    ] else ...[
                      // Fallback if somehow no scan record exists
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppTheme.warning.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: AppTheme.warning, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No scan data found. Please scan a medicine first.',
                                style: TextStyle(
                                    fontSize: 13, color: AppTheme.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // ── Section 2: Pharmacy Location ────────────────────────
                    _sectionLabel(context, 'Where Did You Get It?'),
                    const SizedBox(height: 4),
                    const Text(
                      'Tell us where you purchased this medicine.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      context,
                      controller: _regionCtrl,
                      label: 'Region / District',
                      hint: 'e.g., Arusha, Dar es Salaam',
                      icon: Icons.map_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      context,
                      controller: _streetCtrl,
                      label: 'Street / Area',
                      hint: 'e.g., Sokoine Road, Kariakoo',
                      icon: Icons.signpost_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      context,
                      controller: _pharmacyCtrl,
                      label: 'Pharmacy Name',
                      hint: 'e.g., Afya Pharmacy',
                      icon: Icons.local_pharmacy_rounded,
                    ),

                    const SizedBox(height: 28),

                    // ── Section 3: Issue Category ───────────────────────────
                    _sectionLabel(context, 'Issue Category'),
                    const SizedBox(height: 12),
                    _CategorySelector(
                      categories: _categories,
                      selected: _selectedCategory,
                      onSelect: (c) => setState(() => _selectedCategory = c),
                    ),

                    const SizedBox(height: 28),

                    // ── Section 4: Description ──────────────────────────────
                    _sectionLabel(context, 'Description'),
                    const SizedBox(height: 4),
                    const Text(
                      'Describe what makes this medicine look suspicious.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: TextFormField(
                        controller: _descCtrl,
                        maxLines: 5,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText:
                              'e.g., The packaging looks faded, the pills smell unusual, the seal was broken...',
                          hintStyle: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Warning notice ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppTheme.warning.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: AppTheme.warning, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your report will be reviewed by our team. False reports may result in account suspension.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.warning,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Submit Button ───────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.danger,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                'Submit Report',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    // Require at least pharmacy name so report has location context
    if (_pharmacyCtrl.text.trim().isEmpty &&
        _regionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
          content: const Text(
            'Please enter at least a region or pharmacy name.',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isLoading = false;
      _submitted = true;
    });
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle:
              const TextStyle(color: AppTheme.textLight, fontSize: 13),
          labelStyle: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 13),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }
}

// ── Read-only medicine info card ───────────────────────────────────────────────
class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(
      {required this.icon, required this.label, required this.value});
}

class _ReadOnlyInfoCard extends StatelessWidget {
  final List<_InfoItem> items;
  const _ReadOnlyInfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon,
                          color: AppTheme.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Lock icon to signal read-only
                    const Icon(Icons.lock_outline_rounded,
                        size: 15,
                        color: AppTheme.textLight),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                    height: 1, indent: 64, color: AppTheme.divider),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Category selector ──────────────────────────────────────────────────────────
class _CategorySelector extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final Function(String) onSelect;

  const _CategorySelector({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((c) {
        final isSelected = c == selected;
        return GestureDetector(
          onTap: () => onSelect(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.danger : Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(
                color: isSelected ? AppTheme.danger : AppTheme.divider,
              ),
            ),
            child: Text(
              c,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Success screen ─────────────────────────────────────────────────────────────
class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.success,
                  size: 56,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Report Submitted!',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Thank you for helping protect your community. Our team will review your report and take appropriate action.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_rounded,
                        color: AppTheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Report ID',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'RPT-${DateTime.now().millisecondsSinceEpoch % 100000}',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/main', (_) => false),
                  child: const Text('Back to Home'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/scan'),
                child: const Text(
                  'Scan Another Medicine',
                  style: TextStyle(color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}