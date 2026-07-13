
/// Outcome of a TMDA registration check. The app never claims "counterfeit" —
/// it can only say whether the product matches the TMDA register.
enum VerificationStatus { registered, notFound, unknown, notMedicine }

class ScanRecord {
  final String id;
  final String? serverScanId; // id of the persisted Scan on the backend
  final String medicineName;
  final String manufacturer;
  final String batchNumber;
  final String expiryDate;
  final VerificationStatus status;
  final DateTime scannedAt;
  final String? imagePath;
  final String? notes;
  final double confidenceScore; // canonical 0.0–1.0 (format to % at display)

  // ── TMDA register match evidence (present on registered results) ──
  final String? regNo;
  final String? registrationStatus;
  final String? physicalDescription;
  final String? activeIngredient;

  // ── Safety layer (expiry / registration validity) ──
  // Independent of [status]: a registered medicine can still be an expired box.
  final String severity;             // ok | caution | warning | danger | unknown
  final String? safetyHeadline;
  final String? safetyDetail;
  final String expiryStatus;         // valid | expiring_soon | expired | unknown
  final String? registrationExpiry;
  final bool reportable;

  ScanRecord({
    required this.id,
    this.serverScanId,
    required this.medicineName,
    required this.manufacturer,
    required this.batchNumber,
    required this.expiryDate,
    required this.status,
    required this.scannedAt,
    this.imagePath,
    this.notes,
    required this.confidenceScore,
    this.regNo,
    this.registrationStatus,
    this.physicalDescription,
    this.activeIngredient,
    this.severity = 'unknown',
    this.safetyHeadline,
    this.safetyDetail,
    this.expiryStatus = 'unknown',
    this.registrationExpiry,
    this.reportable = false,
  });

  bool get isExpired => expiryStatus == 'expired';
  bool get isExpiryUnknown => expiryStatus == 'unknown';

  Map<String, dynamic> toJson() => {
        'id': id,
        'serverScanId': serverScanId,
        'medicineName': medicineName,
        'manufacturer': manufacturer,
        'batchNumber': batchNumber,
        'expiryDate': expiryDate,
        'status': status.index,
        'scannedAt': scannedAt.toIso8601String(),
        'imagePath': imagePath,
        'notes': notes,
        'confidenceScore': confidenceScore,
        'regNo': regNo,
        'registrationStatus': registrationStatus,
        'physicalDescription': physicalDescription,
        'activeIngredient': activeIngredient,
        'severity': severity,
        'safetyHeadline': safetyHeadline,
        'safetyDetail': safetyDetail,
        'expiryStatus': expiryStatus,
        'registrationExpiry': registrationExpiry,
        'reportable': reportable,
      };

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
        id: json['id'],
        serverScanId: json['serverScanId'],
        medicineName: json['medicineName'],
        manufacturer: json['manufacturer'],
        batchNumber: json['batchNumber'],
        expiryDate: json['expiryDate'],
        status: VerificationStatus.values[json['status']],
        scannedAt: DateTime.parse(json['scannedAt']),
        imagePath: json['imagePath'],
        notes: json['notes'],
        confidenceScore: (json['confidenceScore'] as num).toDouble(),
        regNo: json['regNo'],
        registrationStatus: json['registrationStatus'],
        physicalDescription: json['physicalDescription'],
        activeIngredient: json['activeIngredient'],
        severity: json['severity'] ?? 'unknown',
        safetyHeadline: json['safetyHeadline'],
        safetyDetail: json['safetyDetail'],
        expiryStatus: json['expiryStatus'] ?? 'unknown',
        registrationExpiry: json['registrationExpiry'],
        reportable: json['reportable'] ?? false,
      );

  String get statusLabel {
    switch (status) {
      case VerificationStatus.registered:
        return 'Registered';
      case VerificationStatus.notFound:
        return 'Not on register';
      case VerificationStatus.unknown:
        return 'Unknown';
      case VerificationStatus.notMedicine:
        return 'Unrecognised';
    }
  }
}
