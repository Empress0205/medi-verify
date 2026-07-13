// Dev tool: render the vector MediLogo to PNG source images for the launcher
// icon (there's no image generator / SVG rasteriser on the build machine).
//
//   flutter test tool/gen_app_icon.dart
//
// then `dart run flutter_launcher_icons` consumes the PNGs written to
// assets/branding/. Not a real test — it just paints and saves.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediverify/theme/app_theme.dart';
import 'package:mediverify/widgets/brand.dart';

Future<void> _capture(GlobalKey key, String path) async {
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1.0);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path)..createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('wrote $path (${bytes.lengthInBytes} bytes)');
}

void main() {
  testWidgets('generate launcher icon PNGs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // ── Full/legacy icon: brand gradient background + white shield ──────────
    final fullKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: fullKey,
        child: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          alignment: Alignment.center,
          child: const MediLogo(size: 640, onLight: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
        () => _capture(fullKey, 'assets/branding/app_icon.png'));

    // ── Adaptive foreground: transparent bg, white shield in the safe zone ──
    final fgKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: fgKey,
        child: const SizedBox.expand(
          child: Align(
            alignment: Alignment.center,
            child: MediLogo(size: 560, onLight: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
        () => _capture(fgKey, 'assets/branding/app_icon_foreground.png'));
  });
}
