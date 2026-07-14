import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_record.dart';

class AppState extends ChangeNotifier {
  static const _kHistory = 'scan_history_v1';
  static const _kOnboardingSeen = 'onboarding_seen_v1';
  static const _kPrivacyAccepted = 'privacy_accepted_v1';

  final List<ScanRecord> _history = [];
  ScanRecord? _lastScan;
  bool _isScanning = false;
  bool _onboardingSeen = false;
  bool _privacyAccepted = false;
  bool _loaded = false;

  AppState() {
    _load();
  }

  List<ScanRecord> get history => _history;
  ScanRecord? get lastScan => _lastScan;
  bool get isScanning => _isScanning;
  bool get onboardingSeen => _onboardingSeen;

  /// Whether the user has been told what leaves their phone when they scan.
  /// Photos go to our server and on to a third-party AI — that has to be said
  /// out loud, once, before the first scan.
  bool get privacyAccepted => _privacyAccepted;

  /// True once persisted state has been read from disk (the splash waits on it).
  bool get isLoaded => _loaded;

  int get totalScans => _history.length;

  // Counters follow the VERDICT, not the raw register status. A registered but
  // EXPIRED pack is not a clean result, so it is not counted as "Registered" —
  // doing so would tell the user everything is fine about a box they must not
  // take. It lands under [needsAttentionCount] instead.
  int get registeredCount =>
      _history.where((r) => r.verdict == ScanVerdict.registered).length;

  /// Scans the user should do something about: an expired pack, a lapsed
  /// registration, an expiry we could not read, or no register match at all.
  int get needsAttentionCount => _history
      .where((r) => const {
            ScanVerdict.expired,
            ScanVerdict.lapsed,
            ScanVerdict.checkExpiry,
            ScanVerdict.notFound,
          }.contains(r.verdict))
      .length;

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _onboardingSeen = prefs.getBool(_kOnboardingSeen) ?? false;
      _privacyAccepted = prefs.getBool(_kPrivacyAccepted) ?? false;
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

  /// Remove one scan. Clearing everything is too blunt when the user just wants
  /// a mis-scan (a blurry shot, someone else's box) out of their history.
  Future<void> removeScan(String id) async {
    _history.removeWhere((r) => r.id == id);
    if (_lastScan?.id == id) _lastScan = null;
    notifyListeners();
    await _persistHistory();
  }

  Future<void> clearHistory() async {
    _history.clear();
    _lastScan = null;
    notifyListeners();
    await _persistHistory();
  }

  Future<void> acceptPrivacy() async {
    if (_privacyAccepted) return;
    _privacyAccepted = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrivacyAccepted, true);
    } catch (_) {}
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
