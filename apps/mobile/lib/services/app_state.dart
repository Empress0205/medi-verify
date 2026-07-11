import 'package:flutter/material.dart';
import '../models/scan_record.dart';

class AppState extends ChangeNotifier {
  final List<ScanRecord> _history = List.from(sampleScanHistory);
  ScanRecord? _lastScan;
  bool _isScanning = false;

  List<ScanRecord> get history => _history;
  ScanRecord? get lastScan => _lastScan;
  bool get isScanning => _isScanning;

  int get totalScans => _history.length;
  int get registeredCount =>
      _history.where((r) => r.status == VerificationStatus.registered).length;
  int get notFoundCount =>
      _history.where((r) => r.status == VerificationStatus.notFound).length;

  void addScan(ScanRecord record) {
    _history.insert(0, record);
    _lastScan = record;
    notifyListeners();
  }

  void setScanning(bool value) {
    _isScanning = value;
    notifyListeners();
  }

  void setLastScan(ScanRecord record) {
    _lastScan = record;
    notifyListeners();
  }

  
}