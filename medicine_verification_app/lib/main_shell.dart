import 'package:flutter/material.dart';
import '../Screens/home_screen.dart';
import '../screens/history_screen.dart';
import '../screens/report_screen.dart';
import '../screens/help_screen.dart';
import '../../widgets/shared_widgets.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    HistoryScreen(),
    ReportScreen(),
    HelpScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: MediBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        onScanTap: () => Navigator.pushNamed(context, '/scan'),
      ),
    );
  }
}