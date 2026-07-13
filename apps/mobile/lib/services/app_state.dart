import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_record.dart';

class AppState extends ChangeNotifier {
  static const _kHistory = 'scan_history_v1';
  static const _kOnboardingSeen = 'onboarding_seen_v1';

  final List<ScanRecord> _history = [];
  ScanRecord? _lastScan;
  bool _isScanning = false;
  bool _onboardingSeen = false;
  bool _loaded = false;

  AppState() {
    _load();
  }

  List<ScanRecord> get history => _history;
  ScanRecord? get lastScan => _lastScan;
  bool get isScanning => _isScanning;
  bool get onboardingSeen => _onboardingSeen;

  /// True once persisted state has been read from disk (the splash waits on it).
  bool get isLoaded => _loaded;

  int get totalScans => _history.length;
  int get registeredCount =>
      _history.where((r) => r.status == VerificationStatus.registered).length;
  int get notFoundCount =>
      _history.where((r) => r.status == VerificationStatus.notFound).length;

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _onboardingSeen = prefs.getBool(_kOnboardingSeen) ?? false;
      final raw = prefs.getString(_kHistory);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        _history
          ..clear()
          ..addAll(decoded
              .map((e) => ScanRecord.fromJson(e as Map<String, dynamic>)));
      }
    } catch (_) {
      // Corrupt or missing prefs — start clean rather than crash.
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _persistHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kHistory,
        jsonEncode(_history.map((r) => r.toJson()).toList()),
      );
    } catch (_) {
      // Best-effort; losing a write is not fatal.
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────────────
  void addScan(ScanRecord record) {
    _history.insert(0, record);
    _lastScan = record;
    notifyListeners();
    _persistHistory();
  }

  void setScanning(bool value) {
    _isScanning = value;
    notifyListeners();
  }

  void setLastScan(ScanRecord record) {
    _lastScan = record;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    _lastScan = null;
    notifyListeners();
    await _persistHistory();
  }

  /// Remember that the intro has been shown so it doesn't replay every launch.
  Future<void> markOnboardingSeen() async {
    if (_onboardingSeen) return;
    _onboardingSeen = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kOnboardingSeen, true);
    } catch (_) {}
  }
}
