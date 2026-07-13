import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// MediVerify brand mark — a rounded shield (protection) carrying a verify
/// checkmark (registration confirmed). Drawn as vectors so it stays crisp at
/// any size and needs no image assets. Used in the splash, onboarding and
/// (optionally) headers, and rendered to a PNG for the launcher icon.
class MediLogo extends StatelessWidget {
  final double size;

  /// When true the shield is filled with the brand gradient on a white/!light
  /// background (for light surfaces). When false it's a white shield with a
  /// gradient check (for use on top of the brand gradient itself).
  final bool onLight;

  const MediLogo({super.key, this.size = 96, this.onLight = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShieldPainter(onLight: onLight),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  final bool onLight;
  _ShieldPainter({required this.onLight});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Shield path (normalised to the box) ────────────────────────────────
    final shield = Path();
    final topInset = h * 0.06;
    final shoulder = h * 0.30;
    final bodyBottom = h * 0.62;
    final tip = h * 0.96;

    shield.moveTo(w * 0.5, topInset);
    // top-right shoulder
    shield.quadraticBezierTo(w * 0.94, shoulder * 0.55, w * 0.94, shoulder);
    shield.lineTo(w * 0.94, bodyBottom);
    // right flank down to the pointed tip
    shield.cubicTo(
      w * 0.94, h * 0.80,
      w * 0.74, h * 0.90,
      w * 0.5, tip,
    );
    // left flank up
    shield.cubicTo(
      w * 0.26, h * 0.90,
      w * 0.06, h * 0.80,
      w * 0.06, bodyBottom,
    );
    shield.lineTo(w * 0.06, shoulder);
    shield.quadraticBezierTo(w * 0.06, shoulder * 0.55, w * 0.5, topInset);
    shield.close();

    final rect = Offset.zero & size;

    if (onLight) {
      // Gradient-filled shield with a soft shadow, white check.
      canvas.drawShadow(shield, AppTheme.primary.withOpacity(0.5), h * 0.05, true);
      final fill = Paint()
        ..shader = AppTheme.primaryGradient.createShader(rect)
        ..isAntiAlias = true;
      canvas.drawPath(shield, fill);
    } else {
      // White shield (for placing on the brand gradient), gradient check.
      final fill = Paint()
        ..color = Colors.white
        ..isAntiAlias = true;
      canvas.drawPath(shield, fill);
    }

    // ── Checkmark ──────────────────────────────────────────────────────────
    final check = Path()
      ..moveTo(w * 0.32, h * 0.50)
      ..lineTo(w * 0.45, h * 0.63)
      ..lineTo(w * 0.70, h * 0.36);

    final checkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    if (onLight) {
      checkPaint.color = Colors.white;
    } else {
      checkPaint.shader = AppTheme.primaryGradient.createShader(rect);
    }
    canvas.drawPath(check, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter oldDelegate) =>
      oldDelegate.onLight != onLight;
}

/// Full logo lockup: mark + "MediVerify" wordmark. `vertical` stacks them
/// (splash / onboarding); otherwise they sit side-by-side (headers).
class MediLogoLockup extends StatelessWidget {
  final double markSize;
  final bool vertical;
  final Color? textColor;
  final bool onLight;

  const MediLogoLockup({
    super.key,
    this.markSize = 88,
    this.vertical = true,
    this.textColor,
    this.onLight = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? AppTheme.textPrimary;
    final wordmark = RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: markSize * 0.34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: color,
        ),
        children: const [
          TextSpan(text: 'Medi'),
          TextSpan(text: 'Verify', style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );

    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MediLogo(size: markSize, onLight: onLight),
          SizedBox(height: markSize * 0.18),
          wordmark,
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MediLogo(size: markSize, onLight: onLight),
        SizedBox(width: markSize * 0.28),
        wordmark,
      ],
    );
  }
}
