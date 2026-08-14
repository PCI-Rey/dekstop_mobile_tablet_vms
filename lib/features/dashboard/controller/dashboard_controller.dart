import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/api_result.dart';
import '../repository/dashboard_repository.dart';
import '../../../core/services/storage_service.dart';

class DashboardController extends GetxController {
  final DashboardRepository _dashboardRepository;

  DashboardController(this._dashboardRepository);

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
  final rxRelatedVisitors = <Map<String, dynamic>>[].obs;
  final rxAllRelatedVisitors =
      <Map<String, dynamic>>[]; // original copy for search
  final rxTimeline = <Map<String, dynamic>>[].obs;

  // UI Interactive States
  final rxSearchQuery = ''.obs;
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
    final query = rxSearchQuery.value;
    if (query.isNotEmpty) {
      list = list.where((visitor) {
        final name = (visitor['name'] as String).toLowerCase();
        final company = (visitor['company'] as String).toLowerCase();
        return name.contains(query.toLowerCase()) ||
            company.contains(query.toLowerCase());
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

    final startIndex = (rxCurrentPage.value > 0 ? (rxCurrentPage.value - 1) : 0) * pageSize;
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
    rxAllRelatedVisitors.clear();
    rxRelatedVisitors.clear();
    rxSelectedItems.clear();
    rxTimeline.clear();
    rxSearchQuery.value = '';
    rxActiveFilter.value = 'All';
    rxCurrentPage.value = 0;
    rxTotalPages.value = 0;
    applyFiltersAndPagination();
  }

  // --- Visitor Actions ---
  Future<void> executeAction(String action) async {
    final visitor = rxSelectedVisitor.value;
    if (visitor == null) return;

    rxIsActionLoading.value = true;
    final visitorId = visitor['id'] ?? "";

    final result = await _dashboardRepository.performVisitorAction(
      visitorId,
      action,
    );
    rxIsActionLoading.value = false;

    if (result is Success) {
      // Modify state locally to provide instant visual update
      final updated = Map<String, dynamic>.from(visitor);

      if (action == 'check_in') {
        updated['status'] = 'Checked In';
        updated['check_in_time'] =
            '${DateTime.now().hour}:${DateTime.now().minute}';
        // Add to timeline
        rxTimeline.insert(0, {
          'time': '${DateTime.now().hour}:${DateTime.now().minute}',
          'title': 'Checked In',
          'desc': 'By Operator VMS',
          'status': 'checked_in',
        });
      } else if (action == 'check_out') {
        updated['status'] = 'Checked Out';
        updated['check_out_time'] =
            '${DateTime.now().hour}:${DateTime.now().minute}';
        rxTimeline.insert(0, {
          'time': '${DateTime.now().hour}:${DateTime.now().minute}',
          'title': 'Checked Out',
          'desc': 'By Operator VMS',
          'status': 'checked_out',
        });
      } else if (action == 'blacklist') {
        updated['vip'] = false;
        updated['status'] = 'Blacklisted';
      } else if (action == 'whitelist') {
        updated['status'] = 'Whitelisted';
      }

      rxSelectedVisitor.value = updated;

      Get.snackbar(
        'Success',
        'Visitor ${visitor['name']} action executed: $action',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Failed',
        'Failed to execute action.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
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

  String formatApiDate(dynamic dateStr) {
    if (dateStr == null || dateStr.toString().trim().isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr.toString().trim()).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute';
    } catch (_) {
      return dateStr.toString();
    }
  }

  Map<String, dynamic> mapApiVisitorToUi(Map<String, dynamic> item) {
    final hostsList = (item['hosts'] as List?) ?? [];
    Map<String, dynamic> primaryHost = {};
    if (hostsList.isNotEmpty) {
      primaryHost = Map<String, dynamic>.from(hostsList[0] as Map);
    }

    final rawCards = (item['card'] as List?) ?? [];
    final parsedCards = rawCards.map((c) => Map<String, dynamic>.from(c as Map)).toList();

    final visitorName = (item['visitor_name'] ?? item['visitor']?['name'] ?? item['name'] ?? '-').toString();
    final visitorOrg = (item['visitor_organization_name'] ?? item['company'] ?? item['organization'] ?? '-').toString();
    final visitorEmail = (item['visitor_email'] ?? item['visitor']?['email'] ?? item['email'] ?? '-').toString();
    final visitorPhone = (item['visitor_phone'] ?? item['phone'] ?? '-').toString();
    final visitorIdentityId = (item['visitor_identity_id'] ?? item['id_number'] ?? item['visitor_number'] ?? '-').toString();
    final visitorRole = (item['visitor_role'] ?? 'Visitor').toString();
    final visitorTypeName = (item['visitor_type_name'] ?? 'General Visitor').toString();
    final visitorStatus = (item['visitor_status'] ?? item['status'] ?? 'Preregis').toString();
    final invitationCode = (item['invitation_code'] ?? item['initial_trx_code'] ?? '-').toString();
    final groupName = (item['group_name'] ?? '-').toString();
    final visitorNumber = (item['visitor_number'] ?? item['visitor_code'] ?? '-').toString();
    final vehiclePlate = (item['vehicle_plate_number'] ?? item['parking_slot'] ?? '-').toString();
    final invitedBy = (item['invited_by_name'] ?? item['host_name'] ?? '-').toString();
    final agenda = (item['agenda'] ?? item['remarks'] ?? 'Meeting').toString();
    final siteName = (item['site_place_name'] ?? 'Gedung SINERGI').toString();
    final periodStart = formatApiDate(item['visitor_period_start']);
    final periodEnd = formatApiDate(item['visitor_period_end']);
    final checkinAt = formatApiDate(item['checkin_at']);
    final isGroup = item['is_group'] == true;

    final hostName = (primaryHost['name'] ?? item['host_name'] ?? '-').toString();
    final hostOrg = (item['host_organization_name'] ?? 'Organization SPU').toString();
    final hostPhone = (primaryHost['phone'] ?? item['host_phone'] ?? '-').toString();
    final hostEmail = (primaryHost['email'] ?? item['host_email'] ?? '-').toString();
    final hostFaceImage = (primaryHost['faceimage'] ?? '').toString();

    return {
      'id': item['visitor_id'] ?? item['id'] ?? item['transaction_visitor_id'] ?? 'v_${DateTime.now().millisecondsSinceEpoch}',
      'name': visitorName,
      'company': visitorOrg,
      'organization': visitorOrg,
      'email': visitorEmail,
      'phone': visitorPhone,
      'id_card_no': visitorIdentityId,
      'gender': primaryHost['gender'] ?? item['gender'] ?? '-',
      'nationality': 'Indonesia',
      'status': visitorStatus,
      'visitor_status': visitorStatus,
      'occupancy': visitorRole,
      'visitor_role': visitorRole,
      'visitor_type_name': visitorTypeName,
      'vip': item['vip'] == true,
      'frequent': false,
      'verified': item['is_praregister_done'] == true || item['approval_status'] == 'Approved',
      'avatar': 'assets/images/ava_person1.png',
      'photo': 'assets/images/ava_person1.png',
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
      'vehicle_type': vehiclePlate.isNotEmpty && vehiclePlate != '-' ? 'Car' : '-',
      'vehicle_plate': vehiclePlate,
      'vehicle_plate_number': vehiclePlate,
      'invited_by_name': invitedBy,
      'is_group': isGroup,
      'qr_code_data': item['initial_trx_code'] ?? invitationCode,
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

      final list = (collection['data'] as List?) ?? (data['data'] as List?) ?? [];
      
      if (list.isNotEmpty) {
        final firstItem = Map<String, dynamic>.from(list[0] as Map);
        final uiVisitor = mapApiVisitorToUi(firstItem);
        
        rxSelectedVisitor.value = uiVisitor;

        // Populate Related Visitors Feed from API response
        final newRelated = <Map<String, dynamic>>[];
        
        // 1. Add the main visitor
        newRelated.add(uiVisitor);

        // 2. Add the hosts / group members
        final hosts = (firstItem['hosts'] as List?) ?? [];
        for (final h in hosts) {
          final hostMap = Map<String, dynamic>.from(h as Map);
          newRelated.add({
            'id': hostMap['id'] ?? hostMap['person_id'] ?? 'host_1',
            'name': hostMap['name'] ?? 'Endru',
            'company': firstItem['host_organization_name'] ?? 'Organization SPU',
            'organization': firstItem['host_organization_name'] ?? 'Organization SPU',
            'email': hostMap['email'] ?? 'reyjanumbs@gmail.com',
            'phone': hostMap['phone'] ?? '08898765678',
            'id_card_no': hostMap['identity_id'] ?? '77182',
            'gender': hostMap['gender'] ?? 'Male',
            'status': 'Host (Available)',
            'visitor_status': 'Host',
            'occupancy': 'Host',
            'visitor_type_name': 'Employee Host',
            'vip': false,
            'verified': true,
            'faceimage': hostMap['faceimage'] ?? '',
            'avatar': hostMap['faceimage'] ?? '',
            'host_faceimage': hostMap['faceimage'] ?? '',
            'invitation_code': uiVisitor['invitation_code'],
            'group_name': uiVisitor['group_name'],
            'visitor_code': hostMap['identity_id'] ?? '77182',
            'ticket_no': hostMap['identity_id'] ?? '77182',
            'vehicle_plate': '-',
            'invited_by_name': uiVisitor['invited_by_name'],
            'is_group': true,
            'agenda': uiVisitor['agenda'],
            'site': uiVisitor['site'],
            'period_start': uiVisitor['period_start'],
            'period_end': uiVisitor['period_end'],
            'cards': uiVisitor['cards'],
            'card': uiVisitor['card'],
          });
        }

        rxAllRelatedVisitors.clear();
        rxAllRelatedVisitors.addAll(newRelated);
        applyFiltersAndPagination();

        // Update Timeline
        rxTimeline.clear();
        rxTimeline.addAll([
          {
            'time': '10:23',
            'title': 'Invitation Created',
            'desc': 'By ${uiVisitor['invited_by_name']}',
            'status': 'invitation',
          },
          {
            'time': '10:25',
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
}
