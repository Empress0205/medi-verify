import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_responses.dart';
import '../utils/constant.dart';

class ApiService {
  ApiService._(); // prevent instantiation — use static methods only

  // ─── Main Verification Method ─────────────────────────────────────────────
  /// Sends [imageFile] to POST /verify and returns a [VerificationResult].
  ///
  /// The image is sent as multipart/form-data with field name "image".
  /// Adjust [imageFieldName] if your backend expects a different field name.
  static Future<VerificationResult> verifyMedicine(
    File imageFile, {
    String imageFieldName = 'image',
  }) async {
    // ── 1. Validate file exists & size ─────────────────────────────────────
    if (!imageFile.existsSync()) {
      return VerificationResult.failure(
        'Image file not found. Please try again.',
        VerificationFailureType.imageError,
      );
    }

    final fileSize = await imageFile.length();
    if (fileSize > AppConstants.maxImageSizeBytes) {
      return VerificationResult.failure(
        'Image is too large (max 10MB). Please use a smaller image.',
        VerificationFailureType.imageError,
      );
    }

    // ── 2. Build multipart request ──────────────────────────────────────────
    try {
      final uri = Uri.parse(AppConstants.verifyUrl);

      final request = http.MultipartRequest('POST', uri);

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          imageFieldName,
          imageFile.path,
          // Let the server detect content type automatically
          // or explicitly set: contentType: MediaType('image', 'jpeg')
        ),
      );

      // Optional metadata your backend might need
      request.fields['app_version'] = AppConstants.appVersion;

      // ── 3. Send with timeout ──────────────────────────────────────────────
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: AppConstants.receiveTimeoutSeconds),
        onTimeout: () {
          throw const SocketException('Connection timed out');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      // ── 4. Handle HTTP status codes ───────────────────────────────────────
      return _handleResponse(response);
    } on SocketException {
      return VerificationResult.failure(
        'No internet connection. Please check your network and try again.',
        VerificationFailureType.networkError,
      );
    } on HttpException {
      return VerificationResult.failure(
        'Could not reach the server. Please try again later.',
        VerificationFailureType.networkError,
      );
    } on FormatException {
      return VerificationResult.failure(
        'Server returned an unexpected response. Please try again.',
        VerificationFailureType.serverError,
      );
    } catch (e) {
      return VerificationResult.failure(
        'An unexpected error occurred: ${e.toString()}',
        VerificationFailureType.unknown,
      );
    }
  }

  // ─── Response Handler ──────────────────────────────────────────────────────
  static VerificationResult _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    // Success range
    if (statusCode >= 200 && statusCode < 300) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = VerifyApiResponse.fromJson(json);
        return VerificationResult.success(apiResponse);
      } catch (e) {
        return VerificationResult.failure(
          'Could not parse server response. Please try again.',
          VerificationFailureType.serverError,
        );
      }
    }

    // Client errors
    if (statusCode == 400) {
      return VerificationResult.failure(
        'Invalid image or request. Please try a clearer photo.',
        VerificationFailureType.imageError,
      );
    }

    if (statusCode == 413) {
      return VerificationResult.failure(
        'Image file is too large for the server. Please use a smaller image.',
        VerificationFailureType.imageError,
      );
    }

    if (statusCode == 422) {
      return VerificationResult.failure(
        'Image could not be processed. Please ensure it shows the medicine packaging clearly.',
        VerificationFailureType.imageError,
      );
    }

    if (statusCode == 429) {
      return VerificationResult.failure(
        'Too many requests. Please wait a moment and try again.',
        VerificationFailureType.serverError,
      );
    }

    // Server errors
    if (statusCode >= 500) {
      return VerificationResult.failure(
        'Server error ($statusCode). Please try again later.',
        VerificationFailureType.serverError,
      );
    }

    return VerificationResult.failure(
      'Unexpected error (HTTP $statusCode). Please try again.',
      VerificationFailureType.unknown,
    );
  }

  // ─── Submit Report ─────────────────────────────────────────────────────────
  /// POST /reports (public). Returns the report_code on success, or throws
  /// with a user-facing message on failure.
  static Future<String> submitReport({
    String? scanId,
    required String medicineName,
    required String manufacturer,
    required String batchNumber,
    required String expiryDate,
    required double confidence, // canonical 0.0–1.0
    required String region,
    required String street,
    required String pharmacy,
    required String category,
    String? description,
  }) async {
    try {
      final uri = Uri.parse(AppConstants.reportUrl);
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'scan_id': scanId,
              'medicine_name': medicineName,
              'manufacturer': manufacturer,
              'batch_number': batchNumber,
              'expiry_date': expiryDate,
              'confidence': confidence.clamp(0.0, 1.0),
              'region': region,
              'street': street,
              'pharmacy': pharmacy,
              'category': category,
              'description': description,
            }),
          )
          .timeout(const Duration(seconds: AppConstants.receiveTimeoutSeconds));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return (json['report_code'] ?? 'RPT-UNKNOWN').toString();
      }
      throw Exception('Server responded ${response.statusCode}');
    } on SocketException {
      throw Exception('No internet connection. Please try again.');
    }
  }
}
