/// Represents the raw response from POST /verify
class VerifyApiResponse {
  final bool success;
  final String status; // "verified" | "counterfeit" | "invalid" | "unknown"
  final double confidenceScore;
  final MedicineInfo? medicineInfo;
  final String? message;
  final String? errorMessage;

  VerifyApiResponse({
    required this.success,
    required this.status,
    required this.confidenceScore,
    this.medicineInfo,
    this.message,
    this.errorMessage,
  });

  factory VerifyApiResponse.fromJson(Map<String, dynamic> json) {
    return VerifyApiResponse(
      success: json['success'] ?? false,
      status: json['status'] ?? json['verification_status'] ?? 'unknown',
      confidenceScore: _parseDouble(
          json['confidence_score'] ?? json['confidenceScore'] ?? 0.0),
      medicineInfo: json['medicine_info'] != null
          ? MedicineInfo.fromJson(json['medicine_info'])
          : json['medicineInfo'] != null
              ? MedicineInfo.fromJson(json['medicineInfo'])
              : null,
      message: json['message'] ?? json['error'] ?? json['error_message'],
      errorMessage: (json['success'] == false)
          ? (json['message'] ?? json['error'] ?? json['error_message'])
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// True only when the scanned item is confirmed NOT a medicine
  bool get isNonMedicineScan =>
      status == 'invalid' || status == 'unknown';

  /// True only when a real medicine is confirmed counterfeit
  bool get isConfirmedCounterfeit =>
      status == 'counterfeit' && !isNonMedicineScan;

  /// True when a real medicine is verified authentic
  bool get isVerified => status == 'verified';
}

/// Medicine details returned by the backend
class MedicineInfo {
  final String name;
  final String manufacturer;
  final String batchNumber;
  final String? manufactureDate;
  final String expiryDate;
  final String scanTime; // ISO String
  final String? description;
  final String? activeIngredient;
  final String? dosage;
  final List<String>? warnings;

  MedicineInfo({
    required this.name,
    required this.manufacturer,
    required this.batchNumber,
    required this.manufactureDate,
    required this.expiryDate,
    required this.scanTime,
    this.description,
    this.activeIngredient,
    this.dosage,
    this.warnings,
  });

  factory MedicineInfo.fromJson(Map<String, dynamic> json) {
    return MedicineInfo(
      name: json['name'] ?? json['medicine_name'] ?? 'Unknown Medicine',
      manufacturer: json['manufacturer'] ?? json['company'] ?? 'Unknown',
      batchNumber: json['batch_number'] ?? json['batchNumber'] ?? 'N/A',
      manufactureDate: json['manufactureDate'] ?? json['manufacture_date'] ?? 'N/A',
      expiryDate: json['expiry_date'] ?? json['expiryDate'] ?? 'N/A',
      scanTime: json['scan_time'] ?? DateTime.now().toIso8601String(),
      description: json['description'],
      activeIngredient: json['active_ingredient'] ?? json['activeIngredient'],
      dosage: json['dosage'],
      warnings: json['warnings'] != null
          ? List<String>.from(json['warnings'])
          : null,
    );
  }
}

/// Internal result after mapping API response to app model
class VerificationResult {
  final bool isSuccess;
  final VerifyApiResponse? data;
  final String? errorMessage;
  final VerificationFailureType? failureType;

  VerificationResult.success(this.data)
      : isSuccess = true,
        errorMessage = null,
        failureType = null;

  VerificationResult.failure(this.errorMessage, [this.failureType])
      : isSuccess = false,
        data = null;

  /// Whether the scan failed because item is not a medicine
  bool get isNonMedicineScan =>
      isSuccess && (data?.isNonMedicineScan ?? false);

  /// Whether a real medicine was scanned and found counterfeit
  bool get isCounterfeit =>
      isSuccess && (data?.isConfirmedCounterfeit ?? false);

  /// Whether a real medicine was scanned and verified authentic
  bool get isVerified =>
      isSuccess && (data?.isVerified ?? false);
}

enum VerificationFailureType {
  networkError,
  serverError,
  imageError,
  timeout,
  unknown,
}