import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../widgets/brand.dart';

/// Branded launch screen: brand gradient + logo lockup + tagline, then routes
/// into onboarding. Kept short so it feels like a splash, not a wait.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _routeOnward();
  }

  /// Hold the splash for a brief, intentional pause, then go to onboarding on a
  /// first run or straight to the app if the intro has already been seen.
  Future<void> _routeOnward() async {
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;

    final state = context.read<AppState>();
    // Wait for persisted state to load (capped, so we never hang on the splash).
    var waited = 0;
    while (mounted && !state.isLoaded && waited < 2000) {
      await Future.delayed(const Duration(milliseconds: 50));
      waited += 50;
    }
    if (!mounted) return;

    Navigator.of(context)
        .pushReplacementNamed(state.onboardingSeen ? '/main' : '/onboarding');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              // ── Logo + wordmark ──────────────────────────────────────────
              Expanded(
                flex: 4,
                child: Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // White shield with gradient check, on a soft halo.
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const MediLogo(size: 96, onLight: false),
                          ),
                          const SizedBox(height: 26),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: Colors.white,
                              ),
                              children: [
                                TextSpan(text: 'Medi'),
                                TextSpan(
                                  text: 'Verify',
                                  style: TextStyle(fontWeight: FontWeight.w400),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Check medicines on the TMDA register',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // ── Loader ───────────────────────────────────────────────────
              const Spacer(flex: 2),
              FadeTransition(
                opacity: _fade,
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
