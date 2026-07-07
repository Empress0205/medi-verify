
enum VerificationStatus { verified, counterfeit, unknown, notMedicine }

class ScanRecord {
  final String id;
  final String medicineName;
  final String manufacturer;
  final String batchNumber;
  final String expiryDate;
  final VerificationStatus status;
  final DateTime scannedAt;
  final String? imagePath;
  final String? notes;
  final double confidenceScore;

  ScanRecord({
    required this.id,
    required this.medicineName,
    required this.manufacturer,
    required this.batchNumber,
    required this.expiryDate,
    required this.status,
    required this.scannedAt,
    this.imagePath,
    this.notes,
    required this.confidenceScore,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicineName': medicineName,
        'manufacturer': manufacturer,
        'batchNumber': batchNumber,
        'expiryDate': expiryDate,
        'status': status.index,
        'scannedAt': scannedAt.toIso8601String(),
        'imagePath': imagePath,
        'notes': notes,
        'confidenceScore': confidenceScore,
      };

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
        id: json['id'],
        medicineName: json['medicineName'],
        manufacturer: json['manufacturer'],
        batchNumber: json['batchNumber'],
        expiryDate: json['expiryDate'],
        status: VerificationStatus.values[json['status']],
        scannedAt: DateTime.parse(json['scannedAt']),
        imagePath: json['imagePath'],
        notes: json['notes'],
        confidenceScore: json['confidenceScore'],
      );

  String get statusLabel {
    switch (status) {
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.counterfeit:
        return 'Counterfeit';
      case VerificationStatus.unknown:
        return 'Unknown';
      case VerificationStatus.notMedicine:
        return 'Unrecognised';
    }
  }
}

// Sample data for demo
List<ScanRecord> sampleScanHistory = [
  ScanRecord(
    id: '1',
    medicineName: 'Amoxicillin 500mg',
    manufacturer: 'GSK Pharmaceuticals',
    batchNumber: 'BN-2024-0892',
    expiryDate: '12/2026',
    status: VerificationStatus.verified,
    scannedAt: DateTime.now().subtract(const Duration(hours: 2)),
    confidenceScore: 98.5,
  ),
  ScanRecord(
    id: '2',
    medicineName: 'Paracetamol 1000mg',
    manufacturer: 'Pfizer Ltd',
    batchNumber: 'BN-2024-1204',
    expiryDate: '06/2025',
    status: VerificationStatus.verified,
    scannedAt: DateTime.now().subtract(const Duration(days: 1)),
    confidenceScore: 96.2,
  ),
  ScanRecord(
    id: '3',
    medicineName: 'Metformin 850mg',
    manufacturer: 'Unknown Supplier',
    batchNumber: 'BN-XXXX-0001',
    expiryDate: '01/2024',
    status: VerificationStatus.counterfeit,
    scannedAt: DateTime.now().subtract(const Duration(days: 3)),
    confidenceScore: 12.1,
    notes: 'Packaging inconsistency detected. Batch number mismatch.',
  ),
  ScanRecord(
    id: '4',
    medicineName: 'Atorvastatin 20mg',
    manufacturer: 'AstraZeneca',
    batchNumber: 'BN-2024-0567',
    expiryDate: '09/2026',
    status: VerificationStatus.verified,
    scannedAt: DateTime.now().subtract(const Duration(days: 5)),
    confidenceScore: 99.1,
  ),
  ScanRecord(
    id: '5',
    medicineName: 'Ciprofloxacin 250mg',
    manufacturer: 'Roche',
    batchNumber: 'BN-2023-4521',
    expiryDate: '03/2025',
    status: VerificationStatus.unknown,
    scannedAt: DateTime.now().subtract(const Duration(days: 7)),
    confidenceScore: 55.4,
    notes: 'Database lookup inconclusive.',
  ),
  ScanRecord(
    id: '6',
    medicineName: 'Omeprazole 20mg',
    manufacturer: 'Sanofi',
    batchNumber: 'BN-2024-0981',
    expiryDate: '11/2026',
    status: VerificationStatus.verified,
    scannedAt: DateTime.now().subtract(const Duration(days: 10)),
    confidenceScore: 97.8,
  ),
  ScanRecord(
    id: '7',
    medicineName: 'Ibuprofen 400mg',
    manufacturer: 'Bayer AG',
    batchNumber: 'BN-2024-2345',
    expiryDate: '08/2026',
    status: VerificationStatus.verified,
    scannedAt: DateTime.now().subtract(const Duration(days: 14)),
    confidenceScore: 94.3,
  ),
  ScanRecord(
    id: '8',
    medicineName: 'Losartan 50mg',
    manufacturer: 'Novartis',
    batchNumber: 'BN-2024-7823',
    expiryDate: '05/2027',
    status: VerificationStatus.verified,
    scannedAt: DateTime.now().subtract(const Duration(days: 21)),
    confidenceScore: 99.9,
  ),
];