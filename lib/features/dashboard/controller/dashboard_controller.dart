import 'dart:async';
import 'package:get/get.dart';
import '../../../core/network/api_result.dart';
import '../../../core/shared/widgets/app_snackbar.dart';
import '../repository/dashboard_repository.dart';
import '../../../core/services/storage_service.dart';

class DashboardController extends GetxController {
  final DashboardRepository _dashboardRepository;

  DashboardController(this._dashboardRepository);

  Timer? _liveSyncTimer;
  String? _activeSearchVisitorId;

  @override
  void onClose() {
    _liveSyncTimer?.cancel();
    super.onClose();
  }

  void _startLiveAutoSync() {
    _liveSyncTimer?.cancel();
    _liveSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      syncCurrentInvitationState();
    });
  }

  Future<void> syncCurrentInvitationState() async {
    if (rxAllRelatedVisitors.isEmpty && rxSelectedVisitor.value == null) return;
    if (rxIsActionLoading.value) return;

    final firstItem = rxAllRelatedVisitors.isNotEmpty ? rxAllRelatedVisitors.first : rxSelectedVisitor.value;
    final parentId = (_activeSearchVisitorId != null && _activeSearchVisitorId!.isNotEmpty)
        ? _activeSearchVisitorId!
        : (firstItem?['id'] ?? firstItem?['transaction_visitor_id'] ?? '').toString();
    if (parentId.isEmpty) return;

    try {
      final relatedResult = await _dashboardRepository.getInvitationRelatedVisitors(
        parentId,
        start: 0,
        length: 10,
        draw: 1,
      );

      if (relatedResult is Success<Map<String, dynamic>>) {
        final relatedData = relatedResult.data;
        final rawList = (relatedData['collection'] is List)
            ? relatedData['collection'] as List
            : ((relatedData['collection'] is Map &&
                    relatedData['collection']['data'] is List)
                ? relatedData['collection']['data'] as List
                : (relatedData['data'] is List ? relatedData['data'] as List : []));

        if (rawList.isEmpty) return;

        final currentSelectedId = (rxSelectedVisitor.value?['id'] ?? '').toString();

        for (final vItem in rawList) {
          final mapped = mapApiVisitorToUi(Map<String, dynamic>.from(vItem as Map));
          final vId = mapped['id'].toString();

          final matchIdx = rxAllRelatedVisitors.indexWhere((item) => item['id'].toString() == vId);
          if (matchIdx != -1) {
            rxAllRelatedVisitors[matchIdx] = mapped;
          } else {
            rxAllRelatedVisitors.add(mapped);
          }
        }

        if (currentSelectedId.isNotEmpty) {
          final matched = rxAllRelatedVisitors.firstWhereOrNull((v) => v['id'].toString() == currentSelectedId);
          if (matched != null) {
            rxSelectedVisitor.value = Map<String, dynamic>.from(matched);
          }
        }
        applyFiltersAndPagination();
      }
    } catch (_) {}
  }

  // Theme State
  final rxIsDarkMode = false.obs;

  // Loading States
  final rxIsLoading = false.obs;
  final rxIsActionLoading = false.obs;

  // Data States
  final rxOccupancy = <String, int>{
    'employees': 142,
    'visitors': 28,
    'contractors': 15,
    'vehicles': 46,
  }.obs;

  final rxAlerts = <Map<String, dynamic>>[].obs;

  final rxSelectedVisitor = Rxn<Map<String, dynamic>>();
  final rxPrimaryHost = Rxn<Map<String, dynamic>>();
  final rxLiveVisitors = <Map<String, dynamic>>[].obs;
  final rxRelatedVisitors = <Map<String, dynamic>>[].obs;
  final rxAllRelatedVisitors =
      <Map<String, dynamic>>[]; // original copy for search
  final rxTimeline = <Map<String, dynamic>>[].obs;

  // UI Interactive States
  final rxSearchQuery = ''.obs;
  final rxFeedTabIndex = 1.obs; // 0 for Live Visitors, 1 for Related Visitors
  final rxSelectedTab =
      0.obs; // Tab index for visitor information details (desktop)
  final rxMobileNavIndex = 0.obs; // Bottom nav index (mobile)
  final rxSelectMultiple = false.obs;
  final rxSelectedItems = <String>{}.obs; // Set of visitor names checked

  // Configurable Quick Actions
  final rxQuickActions = <Map<String, dynamic>>[
    {
      'icon': 'qr_code_scanner',
      'label': 'Scan QR / Card',
      'color': 'blue',
      'enabled': true,
    },
    {'icon': 'login', 'label': 'Check In', 'color': 'green', 'enabled': true},
    {'icon': 'logout', 'label': 'Check Out', 'color': 'red', 'enabled': true},
    {
      'icon': 'credit_card',
      'label': 'Swipe Card',
      'color': 'purple',
      'enabled': true,
    },
    {
      'icon': 'key',
      'label': 'Access Control',
      'color': 'orange',
      'enabled': true,
    },
    {
      'icon': 'local_parking',
      'label': 'Parking',
      'color': 'teal',
      'enabled': true,
    },
    {
      'icon': 'door_sliding_outlined',
      'label': 'Open Door',
      'color': 'deepOrange',
      'enabled': true,
    },
    {
      'icon': 'update',
      'label': 'Extend Visit',
      'color': 'amber',
      'enabled': true,
    },
    {
      'icon': 'restore',
      'label': 'Arrival Log',
      'color': 'greenAccent',
      'enabled': true,
    },
    {'icon': 'block', 'label': 'Blacklist', 'color': 'grey', 'enabled': true},
    {
      'icon': 'check_circle',
      'label': 'Whitelist',
      'color': 'grey',
      'enabled': true,
    },
    {
      'icon': 'directions_walk',
      'label': 'Walk-in / Pre Reg',
      'color': 'indigo',
      'enabled': true,
    },
  ].obs;

  // Pagination & Filtering for Today's Visitors list
  final rxCurrentPage = 0.obs;
  final rxTotalPages = 0.obs;
  final rxActiveFilter = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    _startLiveAutoSync();
    // Load initial theme state locally to prevent lag
    try {
      final storage = Get.find<StorageService>();
      storage.getThemeMode().then((mode) {
        rxIsDarkMode.value = (mode == 'dark');
      });
    } catch (_) {}

    // Initial empty state
    resetDashboardToInitialState();
  }

  Future<void> fetchDashboardData() async {
    // No automatic summary/visitors calls since API endpoints do not exist in backend
  }

  // --- Real-time Search, Status Filtering, and Pagination computation ---
  void applyFiltersAndPagination() {
    var list = List<Map<String, dynamic>>.from(rxAllRelatedVisitors);

    if (list.isEmpty) {
      rxCurrentPage.value = 0;
      rxTotalPages.value = 0;
      rxRelatedVisitors.value = [];
      return;
    }

    // 1. Search Query filtering
    final query = rxSearchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((visitor) {
        final name = (visitor['name'] ?? '').toString().toLowerCase();
        final company = (visitor['company'] ?? visitor['organization'] ?? '')
            .toString()
            .toLowerCase();
        final code =
            (visitor['invitation_code'] ?? visitor['visitor_code'] ?? '')
                .toString()
                .toLowerCase();
        return name.contains(query) ||
            company.contains(query) ||
            code.contains(query);
      }).toList();
    }

    // 2. Active Category filtering
    final filter = rxActiveFilter.value;
    if (filter != 'All') {
      if (filter == 'VIP') {
        list = list
            .where(
              (v) =>
                  v['vip'] == true ||
                  v['name'].toString().contains('VIP') ||
                  v['company'].toString().contains('VIP'),
            )
            .toList();
      } else if (filter == 'Frequent') {
        list = list
            .where(
              (v) =>
                  v['name'].toString().contains('Frequent') ||
                  v['company'].toString().contains('Frequent') ||
                  v['id'] == '3' ||
                  v['id'] == '5',
            )
            .toList();
      } else if (filter == 'Verified') {
        list = list
            .where(
              (v) =>
                  v['status'].toString().contains('Verified') ||
                  v['name'].toString().contains('Verified') ||
                  v['id'] == '1' ||
                  v['id'] == '2',
            )
            .toList();
      }
    }

    // 3. Paginate items (simulated size 4)
    final pageSize = 4;
    final totalItems = list.length;
    final calculatedPages = (totalItems / pageSize).ceil();
    rxTotalPages.value = calculatedPages > 0 ? calculatedPages : 0;

    if (rxCurrentPage.value > rxTotalPages.value) {
      rxCurrentPage.value = rxTotalPages.value;
    }
    if (rxCurrentPage.value == 0 && totalItems > 0) {
      rxCurrentPage.value = 1;
    }

    final startIndex =
        (rxCurrentPage.value > 0 ? (rxCurrentPage.value - 1) : 0) * pageSize;
    final endIndex = startIndex + pageSize;

    if (startIndex < list.length) {
      rxRelatedVisitors.value = list.sublist(
        startIndex,
        endIndex > list.length ? list.length : endIndex,
      );
    } else {
      rxRelatedVisitors.value = [];
    }
  }

  void clearSearch() {
    rxSearchQuery.value = '';
    applyFiltersAndPagination();
  }

  /// Reset all visitor data, related feeds, tabs, and search back to the clean initial empty state
  void resetDashboardToInitialState() {
    rxSelectedVisitor.value = null;
    rxPrimaryHost.value = null;
    rxLiveVisitors.clear();
    rxAllRelatedVisitors.clear();
    rxRelatedVisitors.clear();
    rxSelectedItems.clear();
    rxSelectMultiple.value = false;
    rxFeedTabIndex.value = 1;
    rxTimeline.clear();
    rxSearchQuery.value = '';
    rxActiveFilter.value = 'All';
    rxCurrentPage.value = 0;
    rxTotalPages.value = 0;
    applyFiltersAndPagination();
  }

  // --- Operator Invitation Actions (/api/operator-invitation/action/{trxid}) ---
  Future<bool> performOperatorInvitationAction({
    required String action,
    String? reason,
  }) async {
    final visitor = rxSelectedVisitor.value;
    if (visitor == null) {
      AppSnackbar.warning(
        title: 'Warning',
        message: 'Please select a visitor first.',
      );
      return false;
    }

    final rawStatus = (visitor['visitor_status'] ?? visitor['status'] ?? '')
        .toString()
        .toLowerCase();
    final lowerAction = action.toLowerCase();

    // Validation rules
    if (lowerAction == 'checkout') {
      if (!rawStatus.contains('checkin') && !rawStatus.contains('in')) {
        AppSnackbar.warning(
          title: 'Cannot Check Out',
          message: 'Please check in the visitor first before checking out.',
        );
        return false;
      }
      if (rawStatus.contains('checkout') || rawStatus == 'out') {
        AppSnackbar.warning(
          title: 'Warning',
          message: 'Visitor has already checked out.',
        );
        return false;
      }
    }

    if (lowerAction == 'checkin') {
      final isPraregisterDone = visitor['is_praregister_done'] == true;
      final approvalStatus = (visitor['approval_status'] ?? '').toString().toLowerCase();

      if (rawStatus.contains('preregis') || rawStatus.contains('praregis') || !isPraregisterDone) {
        AppSnackbar.warning(
          title: 'Registration Form Required',
          message: 'Please complete the registration form first. Visitor will be automatically checked in upon form completion.',
        );
        return false;
      }
      if (rawStatus.contains('waiting') || approvalStatus.contains('pending') || approvalStatus.contains('wait')) {
        AppSnackbar.warning(
          title: 'Awaiting Host Approval',
          message: 'This visitor is awaiting confirmation from the host. Please wait for approval.',
        );
        return false;
      }
      if (rawStatus.contains('checkin') || rawStatus == 'in') {
        AppSnackbar.warning(
          title: 'Already Checked In',
          message: 'Visitor is already checked in.',
        );
        return false;
      }
      if (rawStatus.contains('block') || rawStatus.contains('blacklist')) {
        AppSnackbar.error(
          title: 'Action Denied',
          message: 'Cannot check in a blocked visitor. Please unblock first.',
        );
        return false;
      }
    }

    final trxId =
        (visitor['trx_id'] ??
                visitor['id'] ??
                visitor['transaction_visitor_id'] ??
                '')
            .toString();
    if (trxId.isEmpty) {
      AppSnackbar.error(
        title: 'Error',
        message: 'Invalid visitor transaction ID.',
      );
      return false;
    }

    final actualReason = (reason != null && reason.trim().isNotEmpty)
        ? reason.trim()
        : (lowerAction == 'checkin'
              ? 'Checked in by operator'
              : lowerAction == 'checkout'
              ? 'Checked out by operator'
              : lowerAction == 'block'
              ? 'Blocked by operator'
              : 'Unblocked by operator');

    final apiAction = (lowerAction == 'checkin')
        ? 'Checkin'
        : (lowerAction == 'checkout')
        ? 'Checkout'
        : (lowerAction == 'block')
        ? 'Block'
        : (lowerAction == 'unblock')
        ? 'Unblock'
        : action;

    rxIsActionLoading.value = true;
    final result = await _dashboardRepository.performOperatorInvitationAction(
      trxId: trxId,
      action: apiAction,
      reason: actualReason,
    );
    rxIsActionLoading.value = false;

    if (result is Success) {
      final updated = Map<String, dynamic>.from(visitor);
      final nowFormatted =
          formatApiTime(DateTime.now().toIso8601String()) ?? '12:00';
      final nowFullDate = formatApiDate(DateTime.now().toIso8601String());

      if (apiAction == 'Checkin') {
        updated['visitor_status'] = 'Checkin';
        updated['status'] = 'Checkin';
        updated['checkin_at'] = nowFullDate;
        updated['check_in'] = nowFullDate;
        rxTimeline.insert(0, {
          'time': nowFormatted,
          'title': 'Checked In',
          'desc': 'Status: Checkin',
          'status': 'checkin',
        });
      } else if (apiAction == 'Checkout') {
        updated['visitor_status'] = 'Checkout';
        updated['status'] = 'Checkout';
        updated['check_out'] = nowFullDate;
        rxTimeline.insert(0, {
          'time': nowFormatted,
          'title': 'Checked Out',
          'desc': 'Status: Checkout',
          'status': 'checkout',
        });
      } else if (apiAction == 'Block') {
        updated['is_block'] = true;
        updated['last_activity'] = 'Block';
        updated['block_reason'] = actualReason;
        updated['visitor_status'] = 'Block';
        updated['status'] = 'Block';
        rxTimeline.insert(0, {
          'time': nowFormatted,
          'title': 'Visitor Blocked',
          'desc': 'Reason: $actualReason',
          'status': 'block',
        });
      } else if (apiAction == 'Unblock') {
        updated['is_block'] = false;
        updated['last_activity'] = 'UnBlock';
        final hasCheckinTime = (updated['checkin_at'] != null && updated['checkin_at'] != '-') ||
            (updated['check_in'] != null && updated['check_in'] != '-');
        final defaultUnblockStatus = hasCheckinTime ? 'Checkin' : 'Praregis';
        updated['visitor_status'] = defaultUnblockStatus;
        updated['status'] = defaultUnblockStatus;
        rxTimeline.insert(0, {
          'time': nowFormatted,
          'title': 'Visitor Unblocked',
          'desc': 'Reason: $actualReason',
          'status': 'unblock',
        });
      }

      rxSelectedVisitor.value = updated;

      final indexInAll = rxAllRelatedVisitors.indexWhere(
        (v) => (v['id'] ?? v['transaction_visitor_id']).toString() == trxId,
      );
      if (indexInAll != -1) {
        rxAllRelatedVisitors[indexInAll] = updated;
      }
      applyFiltersAndPagination();

      // Automatically sync visitor_status and is_block strictly from backend API response
      try {
        final queryId = (rxAllRelatedVisitors.isNotEmpty
                ? (rxAllRelatedVisitors.first['id'] ?? trxId)
                : trxId)
            .toString();
        if (queryId.isNotEmpty) {
          final relatedResult = await _dashboardRepository.getInvitationRelatedVisitors(
            queryId,
            start: 0,
            length: 10,
            draw: 1,
          );
          if (relatedResult is Success<Map<String, dynamic>>) {
            final relatedData = relatedResult.data;
            final rawList = (relatedData['collection'] is List)
                ? relatedData['collection'] as List
                : ((relatedData['collection'] is Map &&
                        relatedData['collection']['data'] is List)
                    ? relatedData['collection']['data'] as List
                    : (relatedData['data'] is List
                        ? relatedData['data'] as List
                        : []));

            for (final vItem in rawList) {
              final vMap = Map<String, dynamic>.from(vItem as Map);
              final vId = (vMap['id'] ?? vMap['transaction_visitor_id'] ?? '').toString();
              final apiStatus = (vMap['visitor_status'] ?? vMap['status'] ?? '').toString();
              final apiIsBlock = vMap['is_block'] == true;

              if (vId == trxId) {
                if (apiStatus.isNotEmpty) {
                  updated['visitor_status'] = apiStatus;
                  updated['status'] = apiStatus;
                }
                updated['is_block'] = apiIsBlock;
                updated['last_activity'] = vMap['last_activity'] ?? '';
                rxSelectedVisitor.value = Map<String, dynamic>.from(updated);
              }

              final matchIdx = rxAllRelatedVisitors.indexWhere(
                (item) => (item['id'] ?? item['transaction_visitor_id']).toString() == vId,
              );
              if (matchIdx != -1) {
                final existing = Map<String, dynamic>.from(rxAllRelatedVisitors[matchIdx]);
                if (apiStatus.isNotEmpty) {
                  existing['visitor_status'] = apiStatus;
                  existing['status'] = apiStatus;
                }
                existing['is_block'] = apiIsBlock;
                existing['last_activity'] = vMap['last_activity'] ?? '';
                rxAllRelatedVisitors[matchIdx] = existing;
              }
            }
            applyFiltersAndPagination();
          }
        }
      } catch (_) {}

      AppSnackbar.success(
        title: 'Action Success',
        message:
            '$apiAction successfully executed for ${visitor['name'] ?? 'Visitor'}',
      );
      return true;
    } else {
      AppSnackbar.error(
        title: 'Action Failed',
        message: 'Failed to execute $apiAction on visitor.',
      );
      return false;
    }
  }

  // --- Multiple Operator Invitation Actions (/api/operator-invitation/multiple-action) ---
  Future<bool> performMultipleOperatorInvitationAction({
    required String action,
    required List<Map<String, dynamic>> visitors,
    String? reason,
  }) async {
    if (visitors.isEmpty) {
      AppSnackbar.warning(
        title: 'Warning',
        message: 'No visitors selected for this action.',
      );
      return false;
    }

    final cleanAction = (action == 'Check In' || action.toLowerCase() == 'checkin')
        ? 'Checkin'
        : ((action == 'Check Out' || action.toLowerCase() == 'checkout')
            ? 'Checkout'
            : (action.toLowerCase() == 'unblock' ? 'Unblock' : 'Block'));

    final actualReason = (reason != null && reason.trim().isNotEmpty)
        ? reason.trim()
        : (cleanAction == 'Checkin'
            ? 'Checked in by operator'
            : (cleanAction == 'Checkout'
                ? 'Checked out by operator'
                : (cleanAction == 'Unblock'
                    ? 'Unblocked by operator'
                    : 'Blocked by operator')));

    final payload = {
      'data': visitors.map((v) {
        final trxId = (v['trx_id'] ?? v['id'] ?? v['transaction_visitor_id'] ?? '').toString();
        return {
          'trx_visitor_id': trxId,
          'action': cleanAction,
          'reason': actualReason,
        };
      }).toList(),
    };

    rxIsActionLoading.value = true;
    final result = await _dashboardRepository.performMultipleOperatorInvitationAction(payload);
    rxIsActionLoading.value = false;

    if (result is Success) {
      await syncCurrentInvitationState();

      AppSnackbar.success(
        title: 'Action Success',
        message: '$cleanAction successfully applied to ${visitors.length} visitors.',
      );
      return true;
    } else {
      AppSnackbar.error(
        title: 'Action Failed',
        message: 'Failed to apply $cleanAction to selected visitors.',
      );
      return false;
    }
  }

  // --- Visitor Actions ---
  Future<void> executeAction(String action) async {
    return;
  }

  void toggleSelectItem(String name) {
    if (rxSelectedItems.contains(name)) {
      rxSelectedItems.remove(name);
    } else {
      rxSelectedItems.add(name);
    }
  }

  void clearSelectedItems() {
    rxSelectedItems.clear();
  }

  void toggleTheme() {
    rxIsDarkMode.value = !rxIsDarkMode.value;
    try {
      final storage = Get.find<StorageService>();
      storage.saveThemeMode(rxIsDarkMode.value ? 'dark' : 'light');
    } catch (_) {}
  }

  DateTime? parseApiDateTime(dynamic dateStr) {
    if (dateStr == null || dateStr.toString().trim().isEmpty) return null;
    final s = dateStr.toString().trim();
    try {
      if (!s.endsWith('Z') && !RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(s)) {
        // Backend stores timestamps in UTC without trailing 'Z'
        return DateTime.parse('${s}Z').toLocal();
      }
      return DateTime.parse(s).toLocal();
    } catch (_) {
      try {
        return DateTime.parse(s).toLocal();
      } catch (_) {
        return null;
      }
    }
  }

  String? formatApiTime(dynamic dateStr) {
    final dt = parseApiDateTime(dateStr);
    if (dt == null) return null;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String formatApiDate(dynamic dateStr) {
    if (dateStr == null || dateStr.toString().trim().isEmpty) return '-';
    final dt = parseApiDateTime(dateStr);
    if (dt == null) return dateStr.toString();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  Map<String, dynamic> mapApiVisitorToUi(Map<String, dynamic> item) {
    final hostsList = (item['hosts'] as List?) ?? [];
    Map<String, dynamic> primaryHost = {};
    if (hostsList.isNotEmpty) {
      primaryHost = Map<String, dynamic>.from(hostsList[0] as Map);
    }

    final rawCards = (item['card'] as List?) ?? [];
    final parsedCards = rawCards
        .map((c) => Map<String, dynamic>.from(c as Map))
        .toList();

    String sanitize(dynamic val, {String fallback = '-'}) {
      if (val == null) return fallback;
      final s = val.toString().trim();
      if (s.isEmpty || s == 'null') return fallback;
      return s;
    }

    final visitorName = sanitize(
      item['visitor_name'] ??
          item['visitor']?['name'] ??
          item['visitor']?['employee']?['name'] ??
          item['name'],
      fallback: 'Visitor',
    );
    final visitorOrg = sanitize(
      item['visitor_organization_name'] ??
          item['organization'] ??
          item['company'] ??
          item['host_organization_name'],
    );
    final visitorEmail = sanitize(
      item['visitor_email'] ?? item['visitor']?['email'] ?? item['email'],
    );
    final visitorPhone = sanitize(item['visitor_phone'] ?? item['phone']);
    final visitorIdentityId = sanitize(
      item['visitor_identity_id'] ??
          item['visitor']?['employee']?['identity_id'] ??
          item['id_number'] ??
          item['visitor_number'] ??
          item['identity_id'],
    );
    final visitorGender = sanitize(
      item['visitor_gender'] ??
          item['visitor']?['employee']?['gender'] ??
          item['gender'],
    );
    final visitorRole = sanitize(item['visitor_role'], fallback: 'Visitor');
    final visitorTypeName = sanitize(
      item['visitor_type_name'],
      fallback: 'General Visitor',
    );
    final visitorStatus = sanitize(
      item['visitor_status'] ?? item['status'] ?? item['transaction_status'],
      fallback: 'Preregis',
    );
    final invitationCode = sanitize(
      item['invitation_code'] ?? item['initial_trx_code'],
    );
    final groupName = sanitize(item['group_name']);
    final visitorNumber = sanitize(
      item['visitor_number'] ?? item['visitor_code'] ?? item['ticket_no'],
    );
    final rawPlate = sanitize(
      item['vehicle_plate_number'] ??
          item['vehicle_plate'] ??
          item['parking_slot'],
    );
    final vehiclePlate = rawPlate;
    final vehicleType = (rawPlate != '-') ? 'Car' : '-';
    final invitedBy = sanitize(item['invited_by_name'] ?? item['host_name']);
    final agenda = sanitize(
      item['agenda'] ?? item['remarks'],
      fallback: 'Meeting',
    );
    final siteName = sanitize(
      item['site_place_name'] ?? item['site'],
      fallback: 'Gedung SINERGI',
    );
    final periodStart = formatApiDate(item['visitor_period_start']);
    final periodEnd = formatApiDate(item['visitor_period_end']);
    final checkinAt = formatApiDate(item['checkin_at'] ?? item['check_in']);
    final isGroup = item['is_group'] == true || (groupName != '-');

    final photo =
        (item['selfie_image'] ??
                item['visitor_face'] ??
                item['faceimage'] ??
                item['visitor']?['faceimage'] ??
                item['avatar'] ??
                item['photo'] ??
                '')
            .toString()
            .trim();

    final hostName = sanitize(primaryHost['name'] ?? item['host_name']);
    final hostOrg = sanitize(
      item['host_organization_name'] ?? primaryHost['organization'],
      fallback: 'Organization SPU',
    );
    final hostPhone = sanitize(primaryHost['phone'] ?? item['host_phone']);
    final hostEmail = sanitize(primaryHost['email'] ?? item['host_email']);
    final hostFaceImage = sanitize(primaryHost['faceimage'], fallback: '');

    return {
      'id':
          item['id'] ??
          item['transaction_visitor_id'] ??
          item['visitor_id'] ??
          'v_${DateTime.now().millisecondsSinceEpoch}',
      'trx_id': item['id'] ?? item['transaction_visitor_id'] ?? '',
      'visitor_id': item['visitor_id'] ?? '',
      'transaction_visitor_id':
          item['transaction_visitor_id'] ?? item['id'] ?? '',
      'name': visitorName,
      'company': visitorOrg,
      'organization': visitorOrg,
      'email': visitorEmail,
      'phone': visitorPhone,
      'id_card_no': visitorIdentityId,
      'gender': visitorGender,
      'nationality': 'Indonesia',
      'status': visitorStatus,
      'visitor_status': visitorStatus,
      'occupancy': visitorRole,
      'visitor_role': visitorRole,
      'visitor_type_name': visitorTypeName,
      'vip': item['vip'] == true,
      'frequent': false,
      'is_block': item['is_block'] == true,
      'last_activity': item['last_activity'] ?? '',
      'block_reason': item['block_reason'] ?? '',
      'is_praregister_done': item['is_praregister_done'] == true,
      'approval_status': item['approval_status'] ?? '',
      'verified':
          item['is_praregister_done'] == true ||
          item['approval_status'] == 'Approved',
      'avatar': photo,
      'photo': photo,
      'faceimage': photo,
      'selfie_image': photo,
      'host_name': hostName,
      'host_dept': hostOrg,
      'host_organization_name': hostOrg,
      'host_phone': hostPhone,
      'host_email': hostEmail,
      'host_faceimage': hostFaceImage,
      'host_status': 'Available',
      'agenda': agenda,
      'purpose': agenda,
      'visit_purpose': agenda,
      'site': siteName,
      'site_place_name': siteName,
      'period_start': periodStart,
      'period_end': periodEnd,
      'visitor_period_start': periodStart,
      'visitor_period_end': periodEnd,
      'group_name': groupName,
      'visitor_code': item['visitor_code'] ?? visitorNumber,
      'ticket_no': visitorNumber,
      'visitor_number': visitorNumber,
      'vehicle_type': vehicleType,
      'vehicle_plate': vehiclePlate,
      'vehicle_plate_number': vehiclePlate,
      'invited_by_name': invitedBy,
      'is_group': isGroup,
      'is_host': item['is_host'] == true,
      'qr_code_data': invitationCode != '-'
          ? invitationCode
          : (item['initial_trx_code'] ?? visitorNumber),
      'invitation_code': invitationCode,
      'check_in': checkinAt,
      'check_out': '-',
      'checkin_at': checkinAt,
      'cards': parsedCards,
      'card': parsedCards,
      'hosts': hostsList,
      'raw': item,
    };
  }

  Future<bool> searchInvitationCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return false;

    rxIsActionLoading.value = true;
    final result = await _dashboardRepository.searchInvitation(cleanCode);
    rxIsActionLoading.value = false;

    if (result is Success<Map<String, dynamic>>) {
      final data = result.data;
      final collection = (data['collection'] is Map)
          ? data['collection'] as Map<String, dynamic>
          : (data['data'] is Map ? data['data'] as Map<String, dynamic> : data);

      final list =
          (collection['data'] as List?) ?? (data['data'] as List?) ?? [];

      if (list.isNotEmpty) {
        final firstItem = Map<String, dynamic>.from(list[0] as Map);
        final uiVisitor = mapApiVisitorToUi(firstItem);

        rxSelectedVisitor.value = uiVisitor;

        // Populate Primary Host for Host Information Card
        final hosts = (firstItem['hosts'] as List?) ?? [];
        if (hosts.isNotEmpty) {
          final hostMap = Map<String, dynamic>.from(hosts[0] as Map);
          rxPrimaryHost.value = {
            'name': hostMap['name'] ?? firstItem['host_name'] ?? 'Endru',
            'organization':
                firstItem['host_organization_name'] ?? 'Organization SPU',
            'phone':
                hostMap['phone'] ?? firstItem['host_phone'] ?? '08898765678',
            'email':
                hostMap['email'] ??
                firstItem['host_email'] ??
                'reyjanumbs@gmail.com',
            'faceimage': hostMap['faceimage'] ?? '',
            'status': 'Available',
          };
        } else if (firstItem['host_name'] != null) {
          rxPrimaryHost.value = {
            'name': firstItem['host_name'] ?? 'Endru',
            'organization':
                firstItem['host_organization_name'] ?? 'Organization SPU',
            'phone': firstItem['host_phone'] ?? '08898765678',
            'email': firstItem['host_email'] ?? 'reyjanumbs@gmail.com',
            'faceimage': '',
            'status': 'Available',
          };
        }
        // 2. Fetch all related visitors via API:
        // /api/operator-invitation/invitation-related-visitor/{id}
        final searchVisitorId =
            (firstItem['id'] ?? firstItem['transaction_visitor_id'] ?? '')
                .toString();
        _activeSearchVisitorId = searchVisitorId;
        final newRelated = <Map<String, dynamic>>[];

        if (searchVisitorId.isNotEmpty) {
          final relatedResult = await _dashboardRepository
              .getInvitationRelatedVisitors(
                searchVisitorId,
                start: 0,
                length: 10,
                draw: 1,
              );
          if (relatedResult is Success<Map<String, dynamic>>) {
            final relatedData = relatedResult.data;
            final rawList = (relatedData['collection'] is List)
                ? relatedData['collection'] as List
                : ((relatedData['collection'] is Map &&
                          relatedData['collection']['data'] is List)
                      ? relatedData['collection']['data'] as List
                      : (relatedData['data'] is List
                            ? relatedData['data'] as List
                            : []));

            for (final vItem in rawList) {
              final mapped = mapApiVisitorToUi(
                Map<String, dynamic>.from(vItem as Map),
              );
              newRelated.add(mapped);
            }
          }
        }

        // Fallback: If related visitors endpoint returned empty, ensure at least uiVisitor is present
        if (newRelated.isEmpty) {
          newRelated.add(uiVisitor);
        }

        // If Host Information is not yet set from primaryHost, check if any visitor is marked is_host
        final hostItem = newRelated.firstWhereOrNull(
          (v) => v['is_host'] == true || v['visitor_role'] == 'Host',
        );
        if (hostItem != null &&
            (rxPrimaryHost.value == null ||
                rxPrimaryHost.value?['name'] == '-' ||
                rxPrimaryHost.value?['name'] == null)) {
          rxPrimaryHost.value = {
            'name': hostItem['name'] ?? 'Endru',
            'organization': hostItem['organization'] ?? 'Organization SPU',
            'phone': hostItem['phone'] ?? '08898765678',
            'email': hostItem['email'] ?? 'reyjanumbs@gmail.com',
            'faceimage': hostItem['avatar'] ?? '',
            'status': 'Available',
          };
        }

        // Ensure selected visitor is synced
        final matchedSelected =
            newRelated.firstWhereOrNull(
              (v) => v['id'].toString() == searchVisitorId,
            ) ??
            newRelated.first;
        rxSelectedVisitor.value = matchedSelected;

        rxAllRelatedVisitors.clear();
        rxAllRelatedVisitors.addAll(newRelated);
        applyFiltersAndPagination();

        // Update Timeline
        rxTimeline.clear();
        final createdTime =
            formatApiTime(firstItem['invitation_created_at']) ?? '10:46';
        final periodStartTime =
            formatApiTime(firstItem['visitor_period_start']) ?? '02:00';
        rxTimeline.addAll([
          {
            'time': createdTime,
            'title': 'Invitation Created',
            'desc': 'By ${uiVisitor['invited_by_name']}',
            'status': 'invitation',
          },
          {
            'time': periodStartTime,
            'title': 'Pra-Register Status',
            'desc': 'Status: ${uiVisitor['status']}',
            'status': 'preregis',
          },
        ]);

        return true;
      }
    }
    return false;
  }

  Future<void> fetchTransactionVisitors(String transactionId) async {
    if (transactionId.isEmpty) return;
    rxIsActionLoading.value = true;
    final result = await _dashboardRepository.getVisitorsByTransactionId(
      transactionId,
    );
    rxIsActionLoading.value = false;

    if (result is Success<Map<String, dynamic>>) {
      final trxData = result.data;
      final trxList = (trxData['collection'] is List)
          ? trxData['collection'] as List
          : (trxData['data'] is List ? trxData['data'] as List : []);

      if (trxList.isNotEmpty) {
        final newRelated = <Map<String, dynamic>>[];
        for (final vItem in trxList) {
          final mapped = mapApiVisitorToUi(
            Map<String, dynamic>.from(vItem as Map),
          );
          newRelated.add(mapped);
        }

        if (newRelated.isNotEmpty) {
          rxSelectedVisitor.value = newRelated.first;
          rxAllRelatedVisitors.clear();
          rxAllRelatedVisitors.addAll(newRelated);
          applyFiltersAndPagination();
        }
      }
    }
  }
}
