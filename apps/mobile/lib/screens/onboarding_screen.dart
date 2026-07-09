import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = [
    _OnboardingData(
      icon: Icons.shield_rounded,
      iconColor: AppTheme.primary,
      iconBg: AppTheme.primaryLight,
      title: 'Protect Your\nHealth Today',
      subtitle:
          'MediVerify uses AI to instantly verify the authenticity of your medicines. Stay safe, stay protected.',
      gradient: AppTheme.headerGradient,
    ),
    _OnboardingData(
      icon: Icons.qr_code_scanner_rounded,
      iconColor: Colors.white,
      iconBg: Colors.white.withOpacity(0.2),
      title: 'Scan & Verify\nIn Seconds',
      subtitle:
          'Simply scan the QR code or barcode on your medicine packaging. Get instant AI-powered verification results.',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2F80ED), Color(0xFF1557C0)],
      ),
    ),
    _OnboardingData(
      icon: Icons.report_problem_rounded,
      iconColor: Colors.white,
      iconBg: Colors.white.withOpacity(0.2),
      title: 'Report\nCounterfeits',
      subtitle:
          'Found a suspicious medicine? Report it to protect others in your community. Together we fight counterfeit drugs.',
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
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Gradient gradient;

  _OnboardingData({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: data.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(data.icon, color: data.iconColor, size: 60),
                ),
                const SizedBox(height: 32),
                // Decorative circles
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _decorativeCircle(60, Colors.white.withOpacity(0.1)),
                    const SizedBox(width: 12),
                    _decorativeCircle(40, Colors.white.withOpacity(0.08)),
                    const SizedBox(width: 12),
                    _decorativeCircle(50, Colors.white.withOpacity(0.1)),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
      ],
    );
  }

  Widget _decorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
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
                vertical: 14,
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
                        fontSize: 15,
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