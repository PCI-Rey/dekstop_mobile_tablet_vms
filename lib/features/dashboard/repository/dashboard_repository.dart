import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';

class DashboardRepository {
  final DioClient _dioClient;

  DashboardRepository(this._dioClient);

  Future<ApiResult<Map<String, dynamic>>> getDashboardSummary() async {
    return await _dioClient.get<Map<String, dynamic>>('/dashboard-summary');
  }

  Future<ApiResult<Map<String, dynamic>>> getTransactionDataTable({
    int page = 1,
    int length = 20,
    String? search,
  }) async {
    // 1. Try GET /api/visitor/transaction/dt
    final getApiDt = await _dioClient.get<Map<String, dynamic>>(
      '/api/visitor/transaction/dt',
      queryParameters: {
        'page': page,
        'length': length,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    if (getApiDt is Success) return getApiDt;

    // 2. Try GET /visitor/transaction/dt
    final getDt = await _dioClient.get<Map<String, dynamic>>(
      '/visitor/transaction/dt',
      queryParameters: {
        'page': page,
        'length': length,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    if (getDt is Success) return getDt;

    // 3. Try POST /api/visitor/transaction/dt
    final postApiDt = await _dioClient.post<Map<String, dynamic>>(
      '/api/visitor/transaction/dt',
      data: {
        'page': page,
        'length': length,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    if (postApiDt is Success) return postApiDt;

    return getApiDt;
  }

  Future<ApiResult<Map<String, dynamic>>> getVisitorsByTransactionId(
    String transactionId,
  ) async {
    final cleanId = transactionId.trim();

    // 1. Try GET /api/visitor/transaction/{transaction_visitor_id}/visitors
    final getApiVisitors = await _dioClient.get<Map<String, dynamic>>(
      '/api/visitor/transaction/$cleanId/visitors',
    );
    if (getApiVisitors is Success) return getApiVisitors;

    // 2. Try GET /visitor/transaction/{transaction_visitor_id}/visitors
    final getVisitors = await _dioClient.get<Map<String, dynamic>>(
      '/visitor/transaction/$cleanId/visitors',
    );
    if (getVisitors is Success) return getVisitors;

    return getApiVisitors;
  }

  Future<ApiResult<Map<String, dynamic>>> getInvitationRelatedVisitors(
    String id, {
    int start = 0,
    int length = 10,
    int draw = 1,
  }) async {
    final cleanId = id.trim();

    // 1. Try GET /api/operator-invitation/invitation-related-visitor/{id}
    final getApiRelated = await _dioClient.get<Map<String, dynamic>>(
      '/api/operator-invitation/invitation-related-visitor/$cleanId',
      queryParameters: {'start': start, 'length': length, 'draw': draw},
    );
    if (getApiRelated is Success) return getApiRelated;

    // 2. Try GET /operator-invitation/invitation-related-visitor/{id}
    final getRelated = await _dioClient.get<Map<String, dynamic>>(
      '/operator-invitation/invitation-related-visitor/$cleanId',
      queryParameters: {'start': start, 'length': length, 'draw': draw},
    );
    if (getRelated is Success) return getRelated;

    // 3. Fallback GET /api/visitor/transaction/{transaction_visitor_id}/visitors
    return await getVisitorsByTransactionId(cleanId);
  }

  Future<ApiResult<Map<String, dynamic>>> getVisitorsData() async {
    return await _dioClient.get<Map<String, dynamic>>('/visitors');
  }

  Future<ApiResult<Map<String, dynamic>>> performOperatorInvitationAction({
    required String trxId,
    required String action,
    required String reason,
  }) async {
    final cleanId = trxId.trim();

    // 1. Try POST /api/operator-invitation/action/{trxid}
    final postApi = await _dioClient.post<Map<String, dynamic>>(
      '/api/operator-invitation/action/$cleanId',
      data: {'action': action, 'reason': reason},
    );
    if (postApi is Success) return postApi;

    // 2. Try POST /operator-invitation/action/{trxid}
    final postDirect = await _dioClient.post<Map<String, dynamic>>(
      '/operator-invitation/action/$cleanId',
      data: {'action': action, 'reason': reason},
    );
    if (postDirect is Success) return postDirect;

    return postApi;
  }

  Future<ApiResult<Map<String, dynamic>>>
  performMultipleOperatorInvitationAction(Map<String, dynamic> payload) async {
    // 1. Try POST /api/operator-invitation/multiple-action
    final postApi = await _dioClient.post<Map<String, dynamic>>(
      '/api/operator-invitation/multiple-action',
      data: payload,
    );
    if (postApi is Success) return postApi;

    // 2. Try POST /operator-invitation/multiple-action
    final postDirect = await _dioClient.post<Map<String, dynamic>>(
      '/operator-invitation/multiple-action',
      data: payload,
    );
    if (postDirect is Success) return postDirect;

    return postApi;
  }

  Future<ApiResult<Map<String, dynamic>>> performVisitorAction(
    String id,
    String action,
  ) async {
    return await _dioClient.post<Map<String, dynamic>>(
      '/visitor/action',
      data: {'id': id, 'action': action},
    );
  }

  Future<ApiResult<Map<String, dynamic>>> searchInvitation(String code) async {
    final cleanCode = code.trim();

    // 1. Primary: POST /api/operator-invitation/search
    final postApiSearch = await _dioClient.post<Map<String, dynamic>>(
      '/api/operator-invitation/search',
      data: {
        'code': cleanCode,
        'search': cleanCode,
        'invitation_code': cleanCode,
      },
    );
    if (postApiSearch is Success) {
      return postApiSearch;
    }

    // 2. Secondary: POST /operator-invitation/search
    final postSearch = await _dioClient.post<Map<String, dynamic>>(
      '/operator-invitation/search',
      data: {
        'code': cleanCode,
        'search': cleanCode,
        'invitation_code': cleanCode,
      },
    );
    if (postSearch is Success) {
      return postSearch;
    }

    // 3. Fallback: GET /api/operator-invitation/search
    final getApiSearch = await _dioClient.get<Map<String, dynamic>>(
      '/api/operator-invitation/search',
      queryParameters: {'code': cleanCode},
    );
    if (getApiSearch is Success) {
      return getApiSearch;
    }

    return postApiSearch;
  }

  Future<ApiResult<Map<String, dynamic>>> getUpcomingPurpose({
    String filter = 'Today',
  }) async {
    final queryParams = <String, dynamic>{'all-visitor-type': 'true'};

    final now = DateTime.now();
    if (filter.toLowerCase() == 'today') {
      queryParams['today'] = 'true';
    } else if (filter.toLowerCase().contains('week')) {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      queryParams['start-date'] =
          "${monday.year.toString().padLeft(4, '0')}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}";
      queryParams['end-date'] =
          "${sunday.year.toString().padLeft(4, '0')}-${sunday.month.toString().padLeft(2, '0')}-${sunday.day.toString().padLeft(2, '0')}";
    } else if (filter.toLowerCase().contains('month')) {
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);
      queryParams['start-date'] =
          "${firstDay.year.toString().padLeft(4, '0')}-${firstDay.month.toString().padLeft(2, '0')}-${firstDay.day.toString().padLeft(2, '0')}";
      queryParams['end-date'] =
          "${lastDay.year.toString().padLeft(4, '0')}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}";
    } else {
      queryParams['today'] = 'true';
    }

    // 1. Try GET /api/operator-invitation/upcoming-purpose
    final getApi = await _dioClient.get<Map<String, dynamic>>(
      '/api/operator-invitation/upcoming-purpose',
      queryParameters: queryParams,
    );
    if (getApi is Success) return getApi;

    // 2. Try GET /operator-invitation/upcoming-purpose
    final getDirect = await _dioClient.get<Map<String, dynamic>>(
      '/operator-invitation/upcoming-purpose',
      queryParameters: queryParams,
    );
    if (getDirect is Success) return getDirect;

    return getApi;
  }

  Future<ApiResult<Map<String, dynamic>>> getUpcomingVisitors({
    required String visitorTypeId,
    bool allVisitorType = false,
    int start = 0,
    int length = 10,
    String? search,
  }) async {
    final hasSpecificType =
        !allVisitorType &&
        visitorTypeId.isNotEmpty &&
        visitorTypeId.toLowerCase() != 'all';
    final queryParams = <String, dynamic>{
      'today': 'true',
      if (hasSpecificType) 'visitor-type': visitorTypeId,
      'all-visitor-type': hasSpecificType ? 'false' : 'true',
      'start': start,
      'length': length,
      'show-checkout': 'false',
      'show-block': 'false',
      'show-expired': 'false',
      if (search != null && search.isNotEmpty) ...{
        'search[value]': search,
        'search': search,
        'visitor_name': search,
        'name': search,
      },
    };

    // 1. Try GET /api/operator-invitation/upcoming-visitor
    final getApi = await _dioClient.get<Map<String, dynamic>>(
      '/api/operator-invitation/upcoming-visitor',
      queryParameters: queryParams,
    );
    if (getApi is Success) return getApi;

    // 2. Try GET /operator-invitation/upcoming-visitor
    final getDirect = await _dioClient.get<Map<String, dynamic>>(
      '/operator-invitation/upcoming-visitor',
      queryParameters: queryParams,
    );
    if (getDirect is Success) return getDirect;

    return getApi;
  }

  Future<ApiResult<Map<String, dynamic>>> extendVisitorPeriod({
    required String id,
    required int period,
    bool applyToAll = false,
  }) async {
    final body = {'id': id, 'period': period, 'apply_to_all': applyToAll};

    // 1. Try POST /api/operator-invitation/extend-period
    final postApi = await _dioClient.post<Map<String, dynamic>>(
      '/api/operator-invitation/extend-period',
      data: body,
    );
    if (postApi is Success) return postApi;

    // 2. Try PUT /api/operator-invitation/extend-period
    final putApi = await _dioClient.put<Map<String, dynamic>>(
      '/api/operator-invitation/extend-period',
      data: body,
    );
    if (putApi is Success) return putApi;

    // 3. Try PUT /operator-invitation/extend-period
    final putDirect = await _dioClient.put<Map<String, dynamic>>(
      '/operator-invitation/extend-period',
      data: body,
    );
    if (putDirect is Success) return putDirect;

    // 4. Try POST /operator-invitation/extend-period
    final postDirect = await _dioClient.post<Map<String, dynamic>>(
      '/operator-invitation/extend-period',
      data: body,
    );
    if (postDirect is Success) return postDirect;

    return postApi;
  }

  Future<ApiResult<Map<String, dynamic>>> blacklistVisitor({
    required String visitorId,
    required String reason,
    String action = 'blacklist',
  }) async {
    final body = {
      'visitor_id': visitorId.trim(),
      'action': action,
      'reason': reason.trim(),
    };

    // Primary endpoint: POST /api/operator-invitation/blacklist
    return await _dioClient.post<Map<String, dynamic>>(
      '/api/operator-invitation/blacklist',
      data: body,
    );
  }

  // --- Registered Sites (/api/operator-invitation/registered-site) ---
  Future<ApiResult<Map<String, dynamic>>> fetchRegisteredSites() async {
    return await _dioClient.get<Map<String, dynamic>>(
      '/api/operator-invitation/registered-site',
    );
  }

  // --- Return Access Card (/api/operator-invitation/return-access-card) ---
  Future<ApiResult<Map<String, dynamic>>> returnAccessCard({
    required String trxVisitorId,
    required String cardNumber,
    required String registeredSiteId,
  }) async {
    final body = {
      'trx_visitor_id': trxVisitorId.trim(),
      'card_number': cardNumber.trim(),
      'registered_site_id': registeredSiteId.trim(),
    };

    return await _dioClient.put<Map<String, dynamic>>(
      '/api/operator-invitation/return-access-card',
      data: body,
    );
  }

  // --- Available Cards (/api/operator-invitation/available-cards) ---
  Future<ApiResult<Map<String, dynamic>>> fetchAvailableCards() async {
    return await _dioClient.get<Map<String, dynamic>>(
      '/api/operator-invitation/available-cards',
    );
  }

  // --- Grant Access Card (/api/operator-invitation/grant-access-card) ---
  Future<ApiResult<Map<String, dynamic>>> grantAccessCard({
    required String cardNumber,
    required String trxVisitorId,
    required String description,
    required String swapCardFromCard,
    required String swapCardFromCardId,
    required String swapCardFromSiteId,
    required bool isSwapCard,
    required String swapType,
    required String registeredSiteId,
  }) async {
    final body = {
      'card_number': cardNumber.trim(),
      'trx_visitor_id': trxVisitorId.trim(),
      'description': description.trim(),
      'swap_card_from_card': swapCardFromCard.trim(),
      'swap_card_from_card_id': swapCardFromCardId.trim(),
      'swap_card_from_site_id': swapCardFromSiteId.trim(),
      'is_swapcard': isSwapCard,
      'swap_type': swapType.trim(),
      'registered_site_id': registeredSiteId.trim(),
    };

    return await _dioClient.post<Map<String, dynamic>>(
      '/api/operator-invitation/grant-access-card',
      data: body,
    );
  }

  // --- Grant Access Card Multiple (/api/operator-invitation/grant-access-card-multiple) ---
  Future<ApiResult<Map<String, dynamic>>> grantAccessCardMultiple(
    Map<String, dynamic> payload,
  ) async {
    return await _dioClient.post<Map<String, dynamic>>(
      '/api/operator-invitation/grant-access-card-multiple',
      data: payload,
    );
  }

  // --- Invitation Sites (/api/invitation-site) ---
  Future<ApiResult<Map<String, dynamic>>> getInvitationSites() async {
    final getApi = await _dioClient.get<Map<String, dynamic>>(
      '/api/invitation-site',
    );
    if (getApi is Success) return getApi;
    return await _dioClient.get<Map<String, dynamic>>('/invitation-site');
  }

  // --- Invitation Visitor Types (/api/invitation-visitor-type) ---
  Future<ApiResult<Map<String, dynamic>>> getInvitationVisitorTypes() async {
    final getApi = await _dioClient.get<Map<String, dynamic>>(
      '/api/invitation-visitor-type',
    );
    if (getApi is Success) return getApi;
    return await _dioClient.get<Map<String, dynamic>>(
      '/invitation-visitor-type',
    );
  }

  // --- Invitation Visitors (/api/invitation-visitor) ---
  Future<ApiResult<Map<String, dynamic>>> getInvitationVisitors() async {
    final getApi = await _dioClient.get<Map<String, dynamic>>(
      '/api/invitation-visitor',
    );
    if (getApi is Success) return getApi;
    return await _dioClient.get<Map<String, dynamic>>('/invitation-visitor');
  }

  // --- Invitation Employees (/api/invitation-visitor/employee) ---
  Future<ApiResult<Map<String, dynamic>>> getInvitationEmployees() async {
    final getApi = await _dioClient.get<Map<String, dynamic>>(
      '/api/invitation-visitor/employee',
    );
    if (getApi is Success) return getApi;
    return await _dioClient.get<Map<String, dynamic>>(
      '/invitation-visitor/employee',
    );
  }

  // --- Invitation Hosts (/api/invitation-visitor/host) ---
  Future<ApiResult<Map<String, dynamic>>> getInvitationHosts() async {
    final getApi = await _dioClient.get<Map<String, dynamic>>(
      '/api/invitation-visitor/host',
    );
    if (getApi is Success) return getApi;
    return await _dioClient.get<Map<String, dynamic>>(
      '/invitation-visitor/host',
    );
  }

  // --- Visitor Type Detail / Form Structure (/api/visitor-type/{id}) ---
  Future<ApiResult<Map<String, dynamic>>> getVisitorTypeDetail(
    String id,
  ) async {
    final cleanId = id.trim();
    final getApi = await _dioClient.get<Map<String, dynamic>>(
      '/api/visitor-type/$cleanId',
    );
    if (getApi is Success) return getApi;
    return await _dioClient.get<Map<String, dynamic>>('/visitor-type/$cleanId');
  }

  // --- Submit Operator Pra-Invite Single (/api/operator-invitation/new-pra-invite) ---
  Future<ApiResult<Map<String, dynamic>>> submitOperatorNewPraInvite(
    Map<String, dynamic> body,
  ) async {
    return await _dioClient.post<Map<String, dynamic>>(
      '/api/operator-invitation/new-pra-invite',
      data: body,
    );
  }

  // --- Submit Operator Pra-Invite Group (/api/operator-invitation/new-pra-invite-group) ---
  Future<ApiResult<Map<String, dynamic>>> submitOperatorNewPraInviteGroup(
    Map<String, dynamic> body,
  ) async {
    return await _dioClient.post<Map<String, dynamic>>(
      '/api/operator-invitation/new-pra-invite-group',
      data: body,
    );
  }

  // --- Submit Operator Invitation / Walk-In Single (/api/operator-invitation/new-visit) ---
  Future<ApiResult<Map<String, dynamic>>> submitOperatorNewVisit(
    Map<String, dynamic> body,
  ) async {
    return await _dioClient.post<Map<String, dynamic>>(
      '/api/operator-invitation/new-visit',
      data: body,
    );
  }

  // --- Submit Operator Invitation / Walk-In Group (/api/operator-invitation/new-visit-group) ---
  Future<ApiResult<Map<String, dynamic>>> submitOperatorNewVisitGroup(
    Map<String, dynamic> body,
  ) async {
    return await _dioClient.post<Map<String, dynamic>>(
      '/api/operator-invitation/new-visit-group',
      data: body,
    );
  }

  // --- Upload CDN File (Selfie / KTP / Documents) ---
  Future<String?> uploadCdnFile(
    List<int> bytes,
    String filename, {
    String path = 'face',
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
        'file_name': filename,
        'path': path,
      });

      final res = await _dioClient.post<dynamic>(
        '/cdn/upload',
        data: formData,
      );

      if (res is Success) {
        final dynamic data = res.data;
        debugPrint('==> Upload SUCCESS on /cdn/upload: $data');
        if (data is String && data.isNotEmpty) {
          return data;
        } else if (data is Map) {
          final p =
              data['collection']?['file_url'] ??
              data['collection']?['path'] ??
              data['collection']?['file_path'] ??
              data['collection']?['url'] ??
              data['collection'] ??
              data['file_url'] ??
              data['path'] ??
              data['url'] ??
              data['file_path'] ??
              data['data']?['file_url'] ??
              data['data']?['path'] ??
              data['data']?['url'] ??
              data['data'];
          if (p != null && p is String && p.isNotEmpty) {
            return p;
          }
        }
      } else if (res is Failure) {
        final msg = res.exception.message;
        debugPrint('==> Upload failure on /cdn/upload: $msg');
      }
    } catch (e) {
      debugPrint('Error uploading CDN file: $e');
    }
    return null;
  }
}
