import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/tender_models.dart';
import 'firebase/auth_service.dart';

class ApiService {
  // ─────────────────────────────────────────────────────────────────────────
  // PRODUCTION API URL CONFIGURATION (RENDER WEB SERVICE)
  //
  // Permanent production backend service URL on Render:
  //   https://gem-backend-rrom.onrender.com
  //
  // You can also override at build time without touching this file:
  //   flutter build apk --release \
  //     --dart-define=API_HOST_URL=https://gem-backend-rrom.onrender.com \
  //     --dart-define=API_BASE_URL=https://gem-backend-rrom.onrender.com/api/v1
  //
  // DO NOT use localhost, 127.0.0.1, or any laptop LAN IP here.
  // The laptop must NOT be required for production app to function.
  // ─────────────────────────────────────────────────────────────────────────
  static const String _defaultProductionHost =
      'https://gem-backend-rrom.onrender.com';

  static const String hostUrl = String.fromEnvironment(
    'API_HOST_URL',
    defaultValue: _defaultProductionHost,
  );

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '$_defaultProductionHost/api/v1',
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Internal helpers
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, String>> _getHeaders() async {
    final token = await FirebaseAuthService.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Logs useful debug information about a failed request.
  /// Never logs PINs, service-account credentials, or private keys.
  static void _debugLogError(
    String endpoint,
    Object error, {
    int? statusCode,
    String? responseBody,
  }) {
    if (kDebugMode) {
      debugPrint('[ApiService] ❌ $endpoint — error: $error');
      if (statusCode != null) {
        debugPrint('[ApiService]    HTTP $statusCode');
      }
      if (responseBody != null && responseBody.length <= 500) {
        // Only log short bodies; never log if body contains sensitive keywords
        final lower = responseBody.toLowerCase();
        if (!lower.contains('"pin"') && !lower.contains('private_key')) {
          debugPrint('[ApiService]    Response: $responseBody');
        }
      }
    }
  }

  /// Returns a user-friendly connection error message for production UI.
  static String _networkErrorMessage(Object e) {
    return 'Unable to connect to the verification service. '
        'Please check your internet connection and try again.';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tender API
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<TenderModel>> fetchTenders() async {
    try {
      final headers = await _getHeaders();
      final response =
          await http.get(Uri.parse('$baseUrl/tenders'), headers: headers);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body) as List;
        return data.map((j) => TenderModel.fromJson(j as Map<String, dynamic>)).toList();
      }
      _debugLogError('GET /tenders', 'HTTP ${response.statusCode}',
          statusCode: response.statusCode, responseBody: response.body);
    } catch (e) {
      _debugLogError('GET /tenders', e);
    }
    return [];
  }

  static Future<TenderModel?> fetchTender(String tenderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/tenders/$tenderId'),
          headers: headers);
      if (response.statusCode == 200) {
        return TenderModel.fromJson(
            json.decode(response.body) as Map<String, dynamic>);
      }
      _debugLogError('GET /tenders/$tenderId', 'HTTP ${response.statusCode}',
          statusCode: response.statusCode);
    } catch (e) {
      _debugLogError('GET /tenders/$tenderId', e);
    }
    return null;
  }

  static String getTenderDocumentUrl(String tenderId) {
    return '$baseUrl/tenders/$tenderId/document';
  }

  static Future<Uint8List?> fetchTenderDocumentBytes(String tenderId) async {
    try {
      final token = await FirebaseAuthService.getIdToken();
      final response = await http.get(
        Uri.parse('$baseUrl/tenders/$tenderId/document'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
      _debugLogError('GET /tenders/$tenderId/document',
          'HTTP ${response.statusCode} or empty body',
          statusCode: response.statusCode);
    } catch (e) {
      _debugLogError('GET /tenders/$tenderId/document', e);
    }
    return null;
  }

  static Future<List<RequirementModel>> fetchTenderRequirements(
      String tenderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/tenders/$tenderId/requirements'),
          headers: headers);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body) as List;
        return data
            .map((j) => RequirementModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _debugLogError('GET /tenders/$tenderId/requirements', e);
    }
    return [];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Application API
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<BidderApplicationModel>> fetchApplications(
      {String? tenderId}) async {
    try {
      final headers = await _getHeaders();
      final url = tenderId != null
          ? '$baseUrl/applications?tender_id=$tenderId'
          : '$baseUrl/applications';
      final response =
          await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body) as List;
        return data
            .map((j) =>
                BidderApplicationModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _debugLogError('GET /applications', e);
    }
    return [];
  }

  static Future<BidderApplicationModel?> fetchApplication(
      String appId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/applications/$appId'),
          headers: headers);
      if (response.statusCode == 200) {
        return BidderApplicationModel.fromJson(
            json.decode(response.body) as Map<String, dynamic>);
      }
    } catch (e) {
      _debugLogError('GET /applications/$appId', e);
    }
    return null;
  }

  static Future<BidderApplicationModel?> createApplication(
      String tenderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tenders/$tenderId/applications'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return BidderApplicationModel.fromJson(
            json.decode(response.body) as Map<String, dynamic>);
      }
    } catch (e) {
      _debugLogError('POST /tenders/$tenderId/applications', e);
    }
    return null;
  }

  static Future<List<EvidenceModel>> fetchApplicationEvidence(
      String appId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/applications/$appId/evidence'),
          headers: headers);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body) as List;
        return data
            .map((j) => EvidenceModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _debugLogError('GET /applications/$appId/evidence', e);
    }
    return [];
  }

  static Future<bool> uploadEvidence({
    required String applicationId,
    required String requirementId,
    required String documentType,
    required String fileName,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/applications/$applicationId/evidence'),
        headers: headers,
        body: json.encode({
          'requirement_id': requirementId,
          'document_type': documentType,
          'file_name': fileName,
          'company_name': FirebaseAuthService.currentCompanyName,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      _debugLogError('POST /applications/$applicationId/evidence', e);
      return false;
    }
  }

  static Future<List<RuleEvaluationModel>> fetchApplicationResults(
      String appId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/applications/$appId/results'),
          headers: headers);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body) as List;
        return data
            .map((j) =>
                RuleEvaluationModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _debugLogError('GET /applications/$appId/results', e);
    }
    return [];
  }

  static Future<bool> submitApplication(String appId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/applications/$appId/submit'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      _debugLogError('POST /applications/$appId/submit', e);
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Notifications API
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/notifications'),
          headers: headers);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body) as List;
        return data
            .map((j) => NotificationModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _debugLogError('GET /notifications', e);
    }
    return [];
  }

  static Future<bool> markNotificationAsRead(String notifId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/$notifId/read'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      _debugLogError('POST /notifications/$notifId/read', e);
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // User Profile API
  // ─────────────────────────────────────────────────────────────────────────

  static Future<UserProfileModel?> fetchMeProfile() async {
    try {
      final headers = await _getHeaders();
      final response =
          await http.get(Uri.parse('$baseUrl/me'), headers: headers);
      if (response.statusCode == 200) {
        return UserProfileModel.fromJson(
            json.decode(response.body) as Map<String, dynamic>);
      }
    } catch (e) {
      _debugLogError('GET /me', e);
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Legacy combined government verification (kept for backwards compatibility)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> verifyGovernmentDetails({
    required String panNumber,
    required String gstNumber,
    required String udyamNumber,
    required String oemAuthorizationNumber,
    required String pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-government-details'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'pan_number': panNumber.trim().toUpperCase(),
          'gst_number': gstNumber.trim().toUpperCase(),
          'udyam_number': udyamNumber.trim().toUpperCase(),
          'oem_authorization_number':
              oemAuthorizationNumber.trim().toUpperCase(),
          'pin': pin.trim(),
        }),
      );
      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['verified'] == true) {
        return {
          'success': true,
          'message':
              data['message'] ?? 'Government details verified successfully',
          'company': data['company'],
          'government_details': data['government_details'],
          'custom_token': data['custom_token'],
          'user_id': data['user_id'],
        };
      }
      return {
        'success': false,
        'message': data['detail'] ?? data['message'] ?? 'Verification failed.',
      };
    } catch (e) {
      _debugLogError('POST /auth/verify-government-details', e);
      return {'success': false, 'message': _networkErrorMessage(e)};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step-by-Step Simulated DigiLocker Verification
  // Endpoints: POST /government/verify/{pan|udyam|gst|oem|finalize}
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> verifyPanStep({
    required String panNumber,
    required String pin,
  }) async {
    const endpoint = 'POST /government/verify/pan';
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/government/verify/pan'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'pan_number': panNumber.trim().toUpperCase(),
          'pin': pin.trim(),
        }),
      );
      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['verified'] == true) {
        return {
          'success': true,
          'details': data['details'],
          'message': data['message']
        };
      }
      // HTTP 4xx — preserve backend's specific error (wrong PIN, not found, etc.)
      _debugLogError(endpoint, 'HTTP ${response.statusCode}',
          statusCode: response.statusCode);
      return {
        'success': false,
        'message': data['detail'] ?? 'PAN verification failed.'
      };
    } catch (e) {
      _debugLogError(endpoint, e);
      return {'success': false, 'message': _networkErrorMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> verifyUdyamStep({
    required String udyamNumber,
    required String pin,
  }) async {
    const endpoint = 'POST /government/verify/udyam';
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/government/verify/udyam'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'udyam_number': udyamNumber.trim().toUpperCase(),
          'pin': pin.trim(),
        }),
      );
      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['verified'] == true) {
        return {
          'success': true,
          'details': data['details'],
          'message': data['message']
        };
      }
      _debugLogError(endpoint, 'HTTP ${response.statusCode}',
          statusCode: response.statusCode);
      return {
        'success': false,
        'message': data['detail'] ?? 'Udyam verification failed.'
      };
    } catch (e) {
      _debugLogError(endpoint, e);
      return {'success': false, 'message': _networkErrorMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> verifyGstStep({
    required String gstNumber,
    required String pin,
  }) async {
    const endpoint = 'POST /government/verify/gst';
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/government/verify/gst'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'gst_number': gstNumber.trim().toUpperCase(),
          'pin': pin.trim(),
        }),
      );
      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['verified'] == true) {
        return {
          'success': true,
          'details': data['details'],
          'message': data['message']
        };
      }
      _debugLogError(endpoint, 'HTTP ${response.statusCode}',
          statusCode: response.statusCode);
      return {
        'success': false,
        'message': data['detail'] ?? 'GST verification failed.'
      };
    } catch (e) {
      _debugLogError(endpoint, e);
      return {'success': false, 'message': _networkErrorMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> verifyOemStep({
    required String oemAuthorizationNumber,
    required String pin,
  }) async {
    const endpoint = 'POST /government/verify/oem';
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/government/verify/oem'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'oem_authorization_number':
              oemAuthorizationNumber.trim().toUpperCase(),
          'pin': pin.trim(),
        }),
      );
      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['verified'] == true) {
        return {
          'success': true,
          'details': data['details'],
          'message': data['message']
        };
      }
      _debugLogError(endpoint, 'HTTP ${response.statusCode}',
          statusCode: response.statusCode);
      return {
        'success': false,
        'message': data['detail'] ?? 'OEM verification failed.'
      };
    } catch (e) {
      _debugLogError(endpoint, e);
      return {'success': false, 'message': _networkErrorMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> finalizeGovernmentVerification({
    required Map<String, dynamic> pan,
    required Map<String, dynamic> udyam,
    required Map<String, dynamic> gst,
    required Map<String, dynamic> oem,
  }) async {
    const endpoint = 'POST /government/verify/finalize';
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/government/verify/finalize'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'pan': pan,
          'udyam': udyam,
          'gst': gst,
          'oem': oem,
        }),
      );
      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['verified'] == true) {
        return {
          'success': true,
          'company': data['company'],
          'user_id': data['user_id'],
          'custom_token': data['custom_token'],
          'message': data['message'],
        };
      }
      _debugLogError(endpoint, 'HTTP ${response.statusCode}',
          statusCode: response.statusCode);
      return {
        'success': false,
        'message': data['detail'] ?? 'Company finalization failed.'
      };
    } catch (e) {
      _debugLogError(endpoint, e);
      return {'success': false, 'message': _networkErrorMessage(e)};
    }
  }
}
