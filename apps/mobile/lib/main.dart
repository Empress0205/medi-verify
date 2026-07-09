import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';

import 'theme/app_theme.dart';
import 'services/app_state.dart';
import 'screens/onboarding_screen.dart';
import 'main_shell.dart';
import 'screens/scan_screen.dart';
import 'screens/result_screen.dart';
import 'screens/history_screen.dart';
import 'screens/report_screen.dart';
import 'screens/help_screen.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize cameras
  cameras = await availableCameras();

  // Lock portrait orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // System UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MediVerifyApp());
}

class MediVerifyApp extends StatelessWidget {
  const MediVerifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'MediVerify',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/onboarding',
        routes: {
          '/onboarding': (_) => const OnboardingScreen(),
          '/main': (_) => const MainShell(),

          // Pass cameras to ScanScreen
          '/scan': (_) => ScanScreen(cameras: cameras),

          '/result': (_) => const ResultScreen(),
          '/history': (_) => const HistoryScreen(),
          '/report': (_) => const ReportScreen(),
          '/help': (_) => const HelpScreen(),
        },
      ),
    );
  }
}