import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../theme/app_theme.dart';
import '../../services/app_state.dart';
import '../../widgets/brand.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = <_OnboardingData>[
    _OnboardingData(
      illustration: const _ProtectScene(),
      title: 'Protect Your\nHealth Today',
      subtitle:
          'MediVerify reads your medicine\'s packaging and checks it against the TMDA register of approved products in seconds.',
      gradient: AppTheme.headerGradient,
    ),
    _OnboardingData(
      illustration: const _ScanScene(),
      title: 'Scan & Check\nIn Seconds',
      subtitle:
          'Photograph the medicine label and we\'ll look it up on the TMDA register instantly — no typing needed.',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2F80ED), Color(0xFF1557C0)],
      ),
    ),
    _OnboardingData(
      illustration: const _ReportScene(),
      title: 'Report\nSuspicious Medicine',
      subtitle:
          'Found a medicine that is not on the register or looks wrong? Report it so TMDA reviewers can investigate and protect your community.',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE05C2A), Color(0xFFC03A10)],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              return _OnboardingPage(data: _pages[index], size: size);
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomSection(
              controller: _controller,
              currentPage: _currentPage,
              total: _pages.length,
              onGetStarted: () {
                context.read<AppState>().markOnboardingSeen();
                Navigator.of(context).pushReplacementNamed('/main');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final Widget illustration;
  final String title;
  final String subtitle;
  final Gradient gradient;

  _OnboardingData({
    required this.illustration,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  final Size size;

  const _OnboardingPage({required this.data, required this.size});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: size.height * 0.55,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: data.gradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(48),
              bottomRight: Radius.circular(48),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Center(child: data.illustration),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  data.subtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Illustration: soft stacked halos shared by every scene ──────────────────
class _Stage extends StatelessWidget {
  final Widget child;
  const _Stage({required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 172,
            height: 172,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ─── Small floating badge (a white pill/circle carrying an icon) ─────────────
class _Badge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const _Badge({required this.icon, required this.color, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

// ─── Scene 1: brand shield ───────────────────────────────────────────────────
class _ProtectScene extends StatelessWidget {
  const _ProtectScene();

  @override
  Widget build(BuildContext context) {
    return _Stage(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          const MediLogo(size: 132, onLight: false),
          const Positioned(
            top: 6,
            right: 4,
            child: _Badge(icon: Icons.check_rounded, color: AppTheme.success),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            child: _Badge(
              icon: Icons.medication_liquid_rounded,
              color: AppTheme.primary,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scene 2: scanning a medicine label ──────────────────────────────────────
class _ScanScene extends StatelessWidget {
  const _ScanScene();

  @override
  Widget build(BuildContext context) {
    return _Stage(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Phone card
          Container(
            width: 150,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Medicine box
                  Container(
                    width: 78,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.35)),
                    ),
                    child: const Icon(Icons.medication_rounded,
                        color: AppTheme.primary, size: 30),
                  ),
                  const SizedBox(height: 12),
                  _line(60, AppTheme.divider),
                  const SizedBox(height: 6),
                  _line(40, AppTheme.divider),
                ],
              ),
            ),
          ),
          // Scan frame overlay
          CustomPaint(
            size: const Size(120, 120),
            painter: _ScanCornersPainter(),
          ),
          // Verified badge
          const Positioned(
            bottom: 2,
            right: 8,
            child: _Badge(
              icon: Icons.verified_rounded,
              color: AppTheme.success,
              size: 46,
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(double w, Color c) => Container(
        width: w,
        height: 6,
        decoration:
            BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
      );
}

class _ScanCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const len = 22.0;
    final w = size.width, h = size.height;
    // top-left
    canvas.drawLine(const Offset(0, len), const Offset(0, 0), p);
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), p);
    // top-right
    canvas.drawLine(Offset(w - len, 0), Offset(w, 0), p);
    canvas.drawLine(Offset(w, 0), Offset(w, len), p);
    // bottom-left
    canvas.drawLine(Offset(0, h - len), Offset(0, h), p);
    canvas.drawLine(Offset(0, h), Offset(len, h), p);
    // bottom-right
    canvas.drawLine(Offset(w - len, h), Offset(w, h), p);
    canvas.drawLine(Offset(w, h), Offset(w, h - len), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Scene 3: report a suspicious product ────────────────────────────────────
class _ReportScene extends StatelessWidget {
  const _ReportScene();

  @override
  Widget build(BuildContext context) {
    return _Stage(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Document card
          Container(
            width: 150,
            height: 190,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _line(90, AppTheme.divider),
                  const SizedBox(height: 10),
                  _line(110, AppTheme.divider),
                  const SizedBox(height: 10),
                  _line(70, AppTheme.divider),
                  const SizedBox(height: 10),
                  _line(100, AppTheme.divider),
                ],
              ),
            ),
          ),
          // Alert badge
          Positioned(
            top: 2,
            right: 6,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.danger,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(Icons.priority_high_rounded,
                  color: Colors.white, size: 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(double w, Color c) => Container(
        width: w,
        height: 7,
        decoration:
            BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
      );
}

class _BottomSection extends StatelessWidget {
  final PageController controller;
  final int currentPage;
  final int total;
  final VoidCallback onGetStarted;

  const _BottomSection({
    required this.controller,
    required this.currentPage,
    required this.total,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == total - 1;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SmoothPageIndicator(
            controller: controller,
            count: total,
            effect: const ExpandingDotsEffect(
              activeDotColor: AppTheme.primary,
              dotColor: AppTheme.divider,
              dotHeight: 8,
              dotWidth: 8,
              expansionFactor: 3,
            ),
          ),
          GestureDetector(
            onTap: isLast
                ? onGetStarted
                : () => controller.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(
                horizontal: isLast ? 28 : 20,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(50),
                boxShadow: AppTheme.primaryShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLast)
                    const Text(
                      'Get Started',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  if (isLast) const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
