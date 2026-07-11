import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/api_responses.dart';
import '../models/scan_record.dart';
import 'api_service.dart';

/// High-level service used by the UI.
/// Handles image picking, compression hint, API call, and model mapping.
class VerificationService {
  VerificationService._();

  static final _picker = ImagePicker();
  static const _uuid = Uuid();

  // ─── Pick from Camera ──────────────────────────────────────────────────────
  static Future<File?> pickFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  // ─── Pick from Gallery ─────────────────────────────────────────────────────
  static Future<File?> pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  // ─── Verify ───────────────────────────────────────────────────────────────
  /// Sends [imageFile] to the backend and maps the result to a [ScanRecord].
  /// Returns null if the API call failed — check [lastError] in that case.
  static Future<ScanRecord?> verify(File imageFile) async {
    final result = await ApiService.verifyMedicine(imageFile);

    if (!result.isSuccess || result.data == null) {
      _lastError = result.errorMessage ?? 'Verification failed.';
      return null;
    }

    return _mapToScanRecord(result.data!);
  }

  // ─── Map API Response → ScanRecord ────────────────────────────────────────
  static ScanRecord _mapToScanRecord(VerifyApiResponse response) {
    // Map backend status string to app enum
    VerificationStatus status;
    switch (response.status.toLowerCase()) {
      case 'registered':
      case 'verified': // legacy backend value
        status = VerificationStatus.registered;
        break;
      case 'not_found':
      case 'counterfeit': // legacy backend value — we no longer claim this
        status = VerificationStatus.notFound;
        break;
      // ── Non-medicine / unrecognised image — must NOT map to notFound ──
      case 'not_medicine':
      case 'invalid':
        status = VerificationStatus.notMedicine;
        break;
      default:
        status = VerificationStatus.unknown;
    }

    final info = response.medicineInfo;

    return ScanRecord(
      id: _uuid.v4(),
      serverScanId: response.scanId,
      medicineName: info?.name ?? 'Unknown Medicine',
      manufacturer: info?.manufacturer ?? 'Unknown Manufacturer',
      batchNumber: info?.batchNumber ?? 'N/A',
      expiryDate: info?.expiryDate ?? 'N/A',
      status: status,
      scannedAt: DateTime.now(),
      confidenceScore: response.confidenceScore,
      notes: _buildNotes(response),
    );
  }

  // ─── Build notes from warnings / message ──────────────────────────────────
  static String? _buildNotes(VerifyApiResponse response) {
    final parts = <String>[];

    if (response.medicineInfo?.warnings != null &&
        response.medicineInfo!.warnings!.isNotEmpty) {
      parts.add(response.medicineInfo!.warnings!.join(' '));
    }

    if (response.message != null && response.message!.isNotEmpty) {
      parts.add(response.message!);
    }

    return parts.isEmpty ? null : parts.join('\n');
  }

  // ─── Last error storage ────────────────────────────────────────────────────
  static String? _lastError;
  static String? get lastError => _lastError;
  static void clearError() => _lastError = null;
}