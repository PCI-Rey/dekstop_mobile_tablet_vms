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
  final rxIsLoading = true.obs;
  final rxIsActionLoading = false.obs;

  // Data States
  final rxOccupancy = <String, int>{
    'employees': 0,
    'visitors': 0,
    'contractors': 0,
    'vehicles': 0,
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
  final rxCurrentPage = 1.obs;
  final rxTotalPages = 5.obs;
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

    fetchDashboardData();

    // Debounce search query to automatically trigger filtering
    debounce(rxSearchQuery, (query) {
      rxCurrentPage.value = 1;
      applyFiltersAndPagination();

      final qStr = query.toString().trim();
      if (qStr.isNotEmpty) {
        final matchingVisitor = rxAllRelatedVisitors.firstWhere((v) {
          // (v['name'] as String).toLowerCase().contains(
          //   qStr.toLowerCase(),
          // ) ||
          // (v['ticket_no'] as String).toLowerCase().contains(
          //   qStr.toLowerCase(),
          // ) ||
          // (v['qr_code_data'] as String).toLowerCase().contains(
          //   qStr.toLowerCase(),
          // )
          return (v['name'] as String).toLowerCase().contains(
            qStr.toLowerCase(),
          );
        }, orElse: () => <String, dynamic>{});
        if (matchingVisitor.isNotEmpty) {
          rxSelectedVisitor.value = matchingVisitor;
        }
      }
    }, time: const Duration(milliseconds: 300));

    // Listen to changes in filter or page and apply rules
    ever(rxActiveFilter, (_) {
      rxCurrentPage.value = 1;
      applyFiltersAndPagination();
    });
    ever(rxCurrentPage, (_) => applyFiltersAndPagination());
  }

  Future<void> fetchDashboardData() async {
    rxIsLoading.value = true;

    // Fetch in parallel
    final results = await Future.wait([
      _dashboardRepository.getDashboardSummary(),
      _dashboardRepository.getVisitorsData(),
    ]);

    final summaryResult = results[0];
    final visitorsResult = results[1];

    if (summaryResult is Success<Map<String, dynamic>>) {
      final data = summaryResult.data;
      final occupancyData = data['occupancy'] as Map<String, dynamic>;
      rxOccupancy.value = {
        'employees': occupancyData['employees'] ?? 0,
        'visitors': occupancyData['visitors'] ?? 0,
        'contractors': occupancyData['contractors'] ?? 0,
        'vehicles': occupancyData['vehicles'] ?? 0,
      };

      final alertsData = data['alerts'] as List;
      rxAlerts.value = List<Map<String, dynamic>>.from(alertsData);
    }

    if (visitorsResult is Success<Map<String, dynamic>>) {
      final data = visitorsResult.data;
      rxSelectedVisitor.value = null; // Start with no scanned visitor

      final relatedData = data['related'] as List;
      rxAllRelatedVisitors.clear();
      rxAllRelatedVisitors.addAll(List<Map<String, dynamic>>.from(relatedData));

      applyFiltersAndPagination();

      final timelineData = data['timeline'] as List;
      rxTimeline.value = List<Map<String, dynamic>>.from(timelineData);
    }

    rxIsLoading.value = false;
  }

  // --- Real-time Search, Status Filtering, and Pagination computation ---
  void applyFiltersAndPagination() {
    var list = List<Map<String, dynamic>>.from(rxAllRelatedVisitors);

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
    rxTotalPages.value = calculatedPages > 0 ? calculatedPages : 1;

    if (rxCurrentPage.value > rxTotalPages.value) {
      rxCurrentPage.value = rxTotalPages.value;
    }

    final startIndex = (rxCurrentPage.value - 1) * pageSize;
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

  Map<String, dynamic> mapApiVisitorToUi(Map<String, dynamic> item) {
    return {
      'id': item['visitor_id'] ?? item['id'] ?? '8057210110',
      'name': item['visitor_name'] ?? item['visitor']?['name'] ?? 'Maza Instansi',
      'company': item['visitor_organization_name'] ?? 'Instansi Maza',
      'email': item['visitor_email'] ?? item['visitor']?['email'] ?? 'maza24@gmail.com',
      'phone': item['visitor_phone'] ?? '085123123412',
      'id_card_no': item['visitor_identity_id'] ?? '8057210110',
      'gender': 'Laki-laki',
      'nationality': 'Indonesia',
      'status': item['visitor_status'] ?? 'Checked In',
      'vip': false,
      'frequent': false,
      'verified': item['is_praregister_done'] == true,
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=300&h=300',
      'address': item['visitor_organization_name'] ?? 'Jl. Kemang Raya No. 42, Jakarta Selatan',
      'organization': item['visitor_organization_name'] ?? 'PT. Maju Jaya Bersama',
      'occupation': item['visitor_type_name'] ?? 'Marketing Manager',
      'id_type': 'KTP',
      'id_number': item['visitor_identity_id'] ?? '3175050101990001',
      'visit_purpose': item['agenda'] ?? 'Pertemuan Bisnis & Pembahasan Kontrak Kerjasama',
      'host': item['host_name'] ?? 'John Doe',
      'host_title': 'IT Manager',
      'host_phone': 'Ext. 2234',
      'host_email': 'john.doe@company.com',
      'host_avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?fit=crop&w=150&h=150',
      'host_status': 'Available',
      'department': item['host_organization_name'] ?? 'IT Department',
      'visit_period': '${item['visitor_period_start'] ?? ""} - ${item['visitor_period_end'] ?? ""}',
      'created_by': item['invited_by_name'] ?? 'Admin Lobby A',
      'qr_code_data': item['invitation_code'] ?? 'QRXMFQ-HGNLFT',
      'check_in_time': item['checkin_at'] ?? '14 Jan 2026, 09:47',
      'check_out_time': '-',
      'ticket_no': item['visitor_number'] ?? '8057210110',
      'invitation_code': item['invitation_code'] ?? 'QRXMFQ-HGNLFT',
      'visit_type': item['visitor_type_name'] ?? 'Meeting',
      'identity_doc_url': 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?fit=crop&w=600&h=400',
    };
  }

  Future<bool> searchInvitationCode(String code) async {
    rxIsActionLoading.value = true;
    final result = await _dashboardRepository.searchInvitation(code);
    rxIsActionLoading.value = false;

    if (result is Success<Map<String, dynamic>>) {
      final data = result.data;
      final collection = data['collection'];
      if (collection != null) {
        final list = collection['data'] as List?;
        if (list != null && list.isNotEmpty) {
          final firstItem = list[0] as Map<String, dynamic>;
          final uiVisitor = mapApiVisitorToUi(firstItem);
          
          rxSelectedVisitor.value = uiVisitor;
          return true;
        }
      }
    }
    return false;
  }
}
