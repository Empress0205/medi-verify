
/// Most photos of one pack the backend will accept in a single check.
/// Mirrors `MAX_PHOTOS` in services/api — sending more is rejected with a 400.
const int kMaxScanPhotos = 3;

/// Outcome of a TMDA registration check. The app never claims "counterfeit" —
/// it can only say whether the product matches the TMDA register.
enum VerificationStatus { registered, notFound, unknown, notMedicine }

/// What a scan should LEAD WITH anywhere it is summarised — a list tile, a
/// counter, a filter chip.
///
/// [VerificationStatus] alone is NOT safe to render on its own: a product can
/// be perfectly registered and still be an expired box. Badging that green
/// "Registered" is the false reassurance the whole safety layer exists to
/// prevent, so a fact we actually READ off the pack (an expiry date that has
/// passed) outranks the register match. Absence of evidence never does —
/// an unreadable expiry becomes [checkExpiry], never "valid".
enum ScanVerdict {
  expired,      // the pack is out of date — red, regardless of registration
  lapsed,       // on the register, but the registration itself has expired
  checkExpiry,  // on the register, expiry unreadable — we cannot call it safe
  expiringSoon, // on the register, in date, but not for much longer
  registered,   // on the register, in date — the only green state
  notFound,     // readable medicine, no register match (uncertainty, not proof)
  unknown,      // the check could not be completed
  notMedicine,  // the image isn't a medicine at all
}

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
  final String registrationValidity; // current | lapsed | unknown
  final String? registrationExpiry;
  final bool reportable;

  /// The photos of this pack that produced the result. Kept so the result
  /// screen can offer "photograph the other side" and ADD to the set rather
  /// than throwing away the panels already captured.
  final List<String> photoPaths;

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
    this.registrationValidity = 'unknown',
    this.registrationExpiry,
    this.reportable = false,
    this.photoPaths = const [],
  });

  bool get isExpired => expiryStatus == 'expired';
  bool get isExpiryUnknown => expiryStatus == 'unknown';

  /// Single source of truth for how this scan is summarised everywhere.
  /// Facts read off the pack outrank the register match — see [ScanVerdict].
  ScanVerdict get verdict {
    if (status == VerificationStatus.notMedicine) return ScanVerdict.notMedicine;
    if (expiryStatus == 'expired') return ScanVerdict.expired;
    if (status == VerificationStatus.notFound) return ScanVerdict.notFound;
    if (status == VerificationStatus.unknown) return ScanVerdict.unknown;

    // Registered — but "registered" is not the same as "safe to take".
    if (registrationValidity == 'lapsed') return ScanVerdict.lapsed;
    if (expiryStatus == 'unknown') return ScanVerdict.checkExpiry;
    if (expiryStatus == 'expiring_soon') return ScanVerdict.expiringSoon;
    return ScanVerdict.registered;
  }

  /// True when the pack is on the register — a fact worth keeping visible even
  /// when a safety concern owns the headline.
  bool get isOnRegister => status == VerificationStatus.registered;

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
        'registrationValidity': registrationValidity,
        'registrationExpiry': registrationExpiry,
        'reportable': reportable,
        'photoPaths': photoPaths,
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
        registrationValidity: json['registrationValidity'] ?? 'unknown',
        registrationExpiry: json['registrationExpiry'],
        reportable: json['reportable'] ?? false,
        photoPaths: json['photoPaths'] != null
            ? List<String>.from(json['photoPaths'])
            : const [],
      );

  /// Short label for badges and chips. Deliberately terse — the full story
  /// lives in [safetyHeadline] on the result screen.
  String get verdictLabel {
    switch (verdict) {
      case ScanVerdict.expired:
        return 'Expired';
      case ScanVerdict.lapsed:
        return 'Registration lapsed';
      case ScanVerdict.checkExpiry:
        return 'Check expiry';
      case ScanVerdict.expiringSoon:
        return 'Expiring soon';
      case ScanVerdict.registered:
        return 'Registered';
      case ScanVerdict.notFound:
        return 'Not on register';
      case ScanVerdict.unknown:
        return 'Unknown';
      case ScanVerdict.notMedicine:
        return 'Not a medicine';
    }
  }
}
