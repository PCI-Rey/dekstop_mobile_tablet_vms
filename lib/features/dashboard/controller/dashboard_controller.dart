import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/network/api_result.dart';
import '../../../core/shared/widgets/app_snackbar.dart';
import '../repository/dashboard_repository.dart';
import '../../../core/services/storage_service.dart';

class DashboardController extends GetxController {
  final DashboardRepository _dashboardRepository;

  DashboardController(this._dashboardRepository);

  String? _activeSearchVisitorId;

  // --- User Permissions (RBAC) ---
  final rxUserPermissions = <String>{}.obs;
  final rxPermissionScopes = <String, dynamic>{}.obs;
  final rxIsPermissionsLoaded = false.obs;

  bool can(String permission) {
    if (!rxIsPermissionsLoaded.value) {
      return true; // Safe fallback during initial load
    }
    if (rxUserPermissions.isEmpty) {
      return true; // Safe fallback if no permissions configured
    }
    return rxUserPermissions.contains(permission);
  }

  bool get canCheckIn => can('OperatorVisitorCheckIn');
  bool get canCheckOut => can('OperatorVisitorCheckout');
  bool get canWalkIn => can('OperatorVisitorWalkIn') && canManageInvite;
  bool get canPraRegister =>
      can('OperatorVisitorPreregister') && canManageInvite;
  bool get canExtend => can('OperatorVisitorExtend');
  bool get canArrival => can('OperatorVisitorSendNotificationArrival');
  bool get canTriggerOpen => can('OperatorVisitorTriggerOpen');
  bool get canParking => can('OperatorVisitorParkingIssuance');
  bool get canCardIssue => can('OperatorVisitorCardIssuance');
  bool get canBlock => can('OperatorVisitorBlock');
  bool get canManageAccess => true;
  bool get canManageBlacklist => canBlock;
  bool get canManageVisitor => true;
  bool get canManageInvite => can('ManageInvite');

  Set<String> get allowedSiteIds {
    final sites = <String>{};
    final scopes = rxPermissionScopes;
    final manageSites = scopes['manage_sites'] as List?;
    if (manageSites != null) {
      for (final s in manageSites) {
        if (s is Map && s['site_id'] != null) {
          sites.add(s['site_id'].toString().toLowerCase().trim());
        }
      }
    }
    final regSites = scopes['manage_registersites'] as List?;
    if (regSites != null) {
      for (final s in regSites) {
        if (s is Map && s['site_id'] != null) {
          sites.add(s['site_id'].toString().toLowerCase().trim());
        }
      }
    }
    return sites;
  }

  Set<String> get allowedVisitorTypeIds {
    final types = <String>{};
    final scopes = rxPermissionScopes;
    final manageTypes = scopes['manage_visitor_types'] as List?;
    if (manageTypes != null) {
      for (final t in manageTypes) {
        if (t is Map && t['visitor_type_id'] != null) {
          types.add(t['visitor_type_id'].toString().toLowerCase().trim());
        }
      }
    }
    return types;
  }

  Future<void> fetchUserPermissions() async {
    try {
      final res = await _dashboardRepository.getUserPermissions();
      if (res is Success<Map<String, dynamic>>) {
        final data = res.data;
        final collection = (data['collection'] is Map)
            ? data['collection'] as Map<String, dynamic>
            : (data['data'] is Map
                  ? data['data'] as Map<String, dynamic>
                  : data);

        final permsSet = <String>{};

        // Extract manage_visitors scope permissions
        final scopes = (collection['scopes'] as Map?) ?? {};
        final manageVisitors =
            (scopes['manage_visitors'] ?? collection['manage_visitors'])
                as List?;
        if (manageVisitors != null) {
          for (final mv in manageVisitors) {
            if (mv is Map && mv['permission'] != null) {
              permsSet.add(mv['permission'].toString().trim());
            }
          }
        }

        // Extract ManageInvite from root permissions as requested
        final rootPerms =
            (collection['permissions'] ?? data['permissions']) as List?;
        if (rootPerms != null) {
          for (final p in rootPerms) {
            if (p is Map && p['permission'] != null) {
              final permName = p['permission'].toString().trim();
              if (permName == 'ManageInvite') {
                permsSet.add(permName);
              }
            }
          }
        }

        rxUserPermissions.assignAll(permsSet);
        rxIsPermissionsLoaded.value = true;
        _printPermissionsSummary();
      }
    } catch (e) {
      debugPrint('==> Error fetching user permissions: $e');
    }
  }

  void _printPermissionsSummary() {
    final count = rxUserPermissions.length;
    final hasManageInvite = rxUserPermissions.contains('ManageInvite');
    debugPrint(
      '\n╔══════════════════════════════════════════════════════════════════╗',
    );
    debugPrint(
      '║ [RBAC] ==> Permissions loaded: $count (manage_visitors + ManageInvite: $hasManageInvite)',
    );
    debugPrint(
      '╚══════════════════════════════════════════════════════════════════╝\n',
    );
  }

  Future<void> refreshDashboardAllStatus() async {
    rxIsActionLoading.value = true;

    try {
      // 0. Refresh User Permissions
      await fetchUserPermissions();

      // 1. Refresh Registered Sites
      await fetchRegisteredSites();

      // 2. Refresh Available Cards
      await fetchAvailableCards();

      // 3. Refresh Live Occupancy
      await fetchUpcomingPurpose(filter: 'Today');

      // 4. Refresh Live Visitors Feed
      await fetchLiveVisitors();

      // 5. Refresh Active Selected Visitor / Related Visitors if active
      final currentVisitor = rxSelectedVisitor.value;
      final invCode = (currentVisitor?['invitation_code'] ?? '')
          .toString()
          .trim();
      final currentId =
          (_activeSearchVisitorId != null && _activeSearchVisitorId!.isNotEmpty)
          ? _activeSearchVisitorId!
          : (currentVisitor?['id'] ??
                    currentVisitor?['transaction_visitor_id'] ??
                    '')
                .toString()
                .trim();

      if (invCode.isNotEmpty && invCode != '-') {
        await searchInvitationCode(invCode);
      } else if (currentId.isNotEmpty) {
        await syncCurrentInvitationState();
      }

      AppSnackbar.success(title: 'Success', message: 'Refresh Successfully');

      // Print at the very end of refresh so it doesn't get buried
      _printPermissionsSummary();
    } catch (_) {
      AppSnackbar.error(
        title: 'Refresh Failed',
        message: 'Could not refresh statuses from server',
      );
    } finally {
      rxIsActionLoading.value = false;
    }
  }

  Future<void> syncCurrentInvitationState() async {
    if (rxAllRelatedVisitors.isEmpty && rxSelectedVisitor.value == null) return;
    if (rxIsActionLoading.value) return;

    final firstItem = rxAllRelatedVisitors.isNotEmpty
        ? rxAllRelatedVisitors.first
        : rxSelectedVisitor.value;
    final parentId =
        (_activeSearchVisitorId != null && _activeSearchVisitorId!.isNotEmpty)
        ? _activeSearchVisitorId!
        : (firstItem?['id'] ?? firstItem?['transaction_visitor_id'] ?? '')
              .toString();
    if (parentId.isEmpty) return;

    try {
      final relatedResult = await _dashboardRepository
          .getInvitationRelatedVisitors(
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
                  : (relatedData['data'] is List
                        ? relatedData['data'] as List
                        : []));

        if (rawList.isEmpty) return;

        final currentSelectedId = (rxSelectedVisitor.value?['id'] ?? '')
            .toString();

        for (final vItem in rawList) {
          final mapped = mapApiVisitorToUi(
            Map<String, dynamic>.from(vItem as Map),
          );
          final vId = mapped['id'].toString();

          final matchIdx = rxAllRelatedVisitors.indexWhere(
            (item) => item['id'].toString() == vId,
          );
          if (matchIdx != -1) {
            final existing = rxAllRelatedVisitors[matchIdx];
            final existingEndDt = parseApiDateTime(
              existing['visitor_period_end'] ?? existing['period_end'],
            );
            final mappedEndDt = parseApiDateTime(
              mapped['visitor_period_end'] ?? mapped['period_end'],
            );

            if (existingEndDt != null &&
                (mappedEndDt == null || existingEndDt.isAfter(mappedEndDt))) {
              mapped['visitor_period_end'] = existing['visitor_period_end'];
              mapped['period_end'] = existing['period_end'];
              mapped['extend_visitor_period'] =
                  existing['extend_visitor_period'];
            }
            final exIdentity = existing['identity_image'] ?? existing['ktp_image'];
            if (exIdentity != null &&
                exIdentity.toString().isNotEmpty &&
                exIdentity.toString() != '-' &&
                (mapped['identity_image'] == null ||
                    mapped['identity_image'].toString().isEmpty ||
                    mapped['identity_image'].toString() == '-')) {
              mapped['identity_image'] = exIdentity;
              mapped['ktp_image'] = exIdentity;
              mapped['id_card_image'] = exIdentity;
            }
            rxAllRelatedVisitors[matchIdx] = mapped;
          } else {
            rxAllRelatedVisitors.add(mapped);
          }
        }

        if (currentSelectedId.isNotEmpty) {
          final matched = rxAllRelatedVisitors.firstWhereOrNull(
            (v) => v['id'].toString() == currentSelectedId,
          );
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
  final rxIsOccupancyLoading = false.obs;

  // Data States
  final rxOccupancy = <String, int>{'staff': 2}.obs;
  final rxUpcomingPurpose = <Map<String, dynamic>>[].obs;
  final rxUpcomingVisitorsList = <Map<String, dynamic>>[].obs;
  final rxIsUpcomingVisitorsLoading = false.obs;
  final rxUpcomingVisitorsTotal = 0.obs;
  final rxUpcomingVisitorsPage = 1.obs;
  final rxUpcomingVisitorsLength = 10.obs;
  final rxUpcomingVisitorsSearch = ''.obs;
  final rxSelectedPurposeCategory = ''.obs;
  final rxSelectedPurposeId = ''.obs;

  final rxAlerts = <Map<String, dynamic>>[].obs;

  final rxSelectedVisitor = Rxn<Map<String, dynamic>>();
  final rxPrimaryHost = Rxn<Map<String, dynamic>>();
  final rxLiveVisitors = <Map<String, dynamic>>[].obs;
  final rxAllLiveVisitors = <Map<String, dynamic>>[];
  final rxRelatedVisitors = <Map<String, dynamic>>[].obs;
  final rxAllRelatedVisitors =
      <Map<String, dynamic>>[]; // original copy for search
  final rxTimeline = <Map<String, dynamic>>[].obs;
  final rxBlacklistedVisitorIds = <String>{}.obs;
  final rxShowRelatedBottomToolbar = false.obs;
  final rxShowSelectMultiple = false.obs;

  // Registered Sites & Site Selection
  final rxRegisteredSites = <Map<String, dynamic>>[].obs;
  final rxSelectedSiteName = 'SPU'.obs;
  final rxSelectedSiteId = ''.obs;

  // Available Cards
  final rxAvailableCards = <Map<String, dynamic>>[].obs;
  final rxIsAvailableCardsLoading = false.obs;

  // Pra-Registration Form Dependencies
  final rxIsPraRegLoading = false.obs;
  final rxPraRegSites = <Map<String, dynamic>>[].obs;
  final rxPraRegVisitorTypes = <Map<String, dynamic>>[].obs;
  final rxPraRegVisitors = <Map<String, dynamic>>[].obs;
  final rxPraRegEmployees = <Map<String, dynamic>>[].obs;
  final rxPraRegHosts = <Map<String, dynamic>>[].obs;

  Future<void> fetchPraRegistrationDependencies({bool silent = false}) async {
    final hasCache =
        rxPraRegVisitorTypes.isNotEmpty || rxPraRegSites.isNotEmpty;
    if (!hasCache && !silent) {
      rxIsPraRegLoading.value = true;
    }
    try {
      final results = await Future.wait([
        _dashboardRepository.getInvitationSites(),
        _dashboardRepository.getInvitationVisitorTypes(),
        _dashboardRepository.getInvitationVisitors(),
        _dashboardRepository.getInvitationEmployees(),
        _dashboardRepository.getInvitationHosts(),
      ]);

      // 1. Sites
      final sitesRes = results[0];
      if (sitesRes is Success<Map<String, dynamic>>) {
        final collection = sitesRes.data['collection'] as List<dynamic>? ?? [];
        rxPraRegSites.assignAll(
          collection.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );
      }

      // 2. Visitor Types
      final typesRes = results[1];
      if (typesRes is Success<Map<String, dynamic>>) {
        final collection = typesRes.data['collection'] as List<dynamic>? ?? [];
        rxPraRegVisitorTypes.assignAll(
          collection.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );
      }

      // 3. Visitors
      final visitorsRes = results[2];
      if (visitorsRes is Success<Map<String, dynamic>>) {
        final collection =
            visitorsRes.data['collection'] as List<dynamic>? ?? [];
        rxPraRegVisitors.assignAll(
          collection.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );
      }

      // 4. Employees
      final empRes = results[3];
      if (empRes is Success<Map<String, dynamic>>) {
        final collection = empRes.data['collection'] as List<dynamic>? ?? [];
        rxPraRegEmployees.assignAll(
          collection.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );
      }

      // 5. Hosts
      final hostsRes = results[4];
      if (hostsRes is Success<Map<String, dynamic>>) {
        final collection = hostsRes.data['collection'] as List<dynamic>? ?? [];
        rxPraRegHosts.assignAll(
          collection.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );
      }
    } catch (e) {
      debugPrint('Error fetching Pra Registration dependencies: $e');
    } finally {
      rxIsPraRegLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> fetchVisitorTypeDetail(String id) async {
    final res = await _dashboardRepository.getVisitorTypeDetail(id);
    if (res is Success<Map<String, dynamic>>) {
      final collection = res.data['collection'];
      if (collection is Map<String, dynamic>) {
        return collection;
      }
    }
    return null;
  }

  Future<bool> submitOperatorPraRegistration({
    required Map<String, dynamic> payload,
    required bool isGroup,
    bool isWalkIn = false,
  }) async {
    rxIsActionLoading.value = true;
    try {
      final res = isGroup
          ? await _dashboardRepository.submitOperatorNewPraInviteGroup(payload)
          : await _dashboardRepository.submitOperatorNewPraInvite(payload);

      if (res is Success<Map<String, dynamic>>) {
        final data = res.data;
        final status = data['status']?.toString() ?? '';
        final msg =
            data['msg']?.toString() ??
            (isWalkIn
                ? 'Walk In registration created successfully!'
                : 'Pra-registration created successfully!');
        if (status == 'success' || data['status_code'] == 200) {
          AppSnackbar.success(
            title: isWalkIn ? 'Walk In Success' : 'Pra-Registration Success',
            message: msg,
          );
          // Refresh upcoming purpose / visitors
          fetchUpcomingPurpose(filter: 'Today');
          return true;
        } else {
          final isBlocked =
              msg.toLowerCase().contains('block') ||
              msg.toLowerCase().contains('blacklist');
          AppSnackbar.error(
            title: isBlocked
                ? 'Visitor Blocked / Blacklisted'
                : 'Registration Failed',
            message: isBlocked
                ? 'Cannot submit registration: One or more visitors are currently blocked or blacklisted in the system.'
                : msg,
          );
          return false;
        }
      } else if (res is Failure<Map<String, dynamic>>) {
        final errMsg = res.exception.message;
        final isBlocked =
            errMsg.toLowerCase().contains('block') ||
            errMsg.toLowerCase().contains('blacklist');
        AppSnackbar.error(
          title: isBlocked
              ? 'Visitor Blocked / Blacklisted'
              : 'Registration Error',
          message: isBlocked
              ? 'Cannot submit registration: One or more visitors are currently blocked or blacklisted in the system.'
              : errMsg,
        );
        return false;
      }
      return false;
    } catch (e) {
      debugPrint('Error submitting Pra Registration: $e');
      AppSnackbar.error(
        title: 'Error',
        message: 'An unexpected error occurred: $e',
      );
      return false;
    } finally {
      rxIsActionLoading.value = false;
    }
  }

  Future<String?> uploadCdnFile(
    List<int> bytes,
    String filename, {
    String path = 'face',
  }) async {
    return await _dashboardRepository.uploadCdnFile(
      bytes,
      filename,
      path: path,
    );
  }

  Future<bool> submitOperatorWalkInRegistration({
    required Map<String, dynamic> payload,
    required bool isGroup,
  }) async {
    rxIsActionLoading.value = true;
    try {
      final res = isGroup
          ? await _dashboardRepository.submitOperatorNewVisitGroup(payload)
          : await _dashboardRepository.submitOperatorNewVisit(payload);

      if (res is Success<Map<String, dynamic>>) {
        final data = res.data;
        final status = data['status']?.toString() ?? '';
        final msg =
            data['msg']?.toString() ??
            'Walk-In invitation created successfully!';
        if (status == 'success' || data['status_code'] == 200) {
          AppSnackbar.success(title: 'Invitation Success', message: msg);
          fetchUpcomingPurpose(filter: 'Today');
          return true;
        } else {
          final isBlocked =
              msg.toLowerCase().contains('block') ||
              msg.toLowerCase().contains('blacklist');
          AppSnackbar.error(
            title: isBlocked
                ? 'Visitor Blocked / Blacklisted'
                : 'Invitation Failed',
            message: isBlocked
                ? 'Cannot submit invitation: One or more visitors are currently blocked or blacklisted in the system.'
                : msg,
          );
          return false;
        }
      } else if (res is Failure<Map<String, dynamic>>) {
        final errMsg = res.exception.message;
        final isBlocked =
            errMsg.toLowerCase().contains('block') ||
            errMsg.toLowerCase().contains('blacklist');
        AppSnackbar.error(
          title: isBlocked
              ? 'Visitor Blocked / Blacklisted'
              : 'Invitation Error',
          message: isBlocked
              ? 'Cannot submit invitation: One or more visitors are currently blocked or blacklisted in the system.'
              : errMsg,
        );
        return false;
      }
      return false;
    } catch (e) {
      debugPrint('Error submitting Walk-In Invitation: $e');
      AppSnackbar.error(
        title: 'Error',
        message: 'An unexpected error occurred: $e',
      );
      return false;
    } finally {
      rxIsActionLoading.value = false;
    }
  }

  // --- Fetch Detail Invitations Form ---
  Future<Map<String, dynamic>?> fetchDetailInvitationsForm(String trxId) async {
    try {
      final res = await _dashboardRepository.getDetailInvitationsForm(trxId);
      if (res is Success<Map<String, dynamic>>) {
        final collection = res.data['collection'];
        if (collection is Map<String, dynamic>) {
          return collection;
        } else if (res.data['data'] is Map<String, dynamic>) {
          return res.data['data'] as Map<String, dynamic>;
        }
        return res.data;
      }
    } catch (e) {
      debugPrint('Error fetching detail invitations form: $e');
    }
    return null;
  }

  // --- Submit Complete Pra Registration (PUT /api/operator-invitation/submit-complete-pra) ---
  Future<bool> submitCompletePraRegistration({
    required Map<String, dynamic> payload,
  }) async {
    rxIsActionLoading.value = true;
    try {
      final res = await _dashboardRepository.submitCompletePraRegistration(
        payload,
      );
      if (res is Success<Map<String, dynamic>>) {
        final data = res.data;
        final status = (data['status'] ?? '').toString();
        final msg =
            (data['msg'] ??
                    data['message'] ??
                    'Pra-Registration form completed successfully!')
                .toString();

        if (status == 'success' ||
            data['status_code'] == 200 ||
            status == 'fiil_form') {
          AppSnackbar.success(title: 'Form Submitted', message: msg);
          fetchUpcomingPurpose(filter: 'Today');
          return true;
        } else {
          final isBlocked =
              msg.toLowerCase().contains('block') ||
              msg.toLowerCase().contains('blacklist');
          AppSnackbar.error(
            title: isBlocked
                ? 'Visitor Blocked / Blacklisted'
                : 'Submission Failed',
            message: isBlocked
                ? 'Cannot complete form: Visitor is currently blocked or blacklisted in the system.'
                : msg,
          );
          return false;
        }
      } else if (res is Failure<Map<String, dynamic>>) {
        final errMsg = res.exception.message;
        final isBlocked =
            errMsg.toLowerCase().contains('block') ||
            errMsg.toLowerCase().contains('blacklist');
        AppSnackbar.error(
          title: isBlocked
              ? 'Visitor Blocked / Blacklisted'
              : 'Submission Error',
          message: isBlocked
              ? 'Cannot complete form: Visitor is currently blocked or blacklisted in the system.'
              : errMsg,
        );
        return false;
      }
      return false;
    } catch (e) {
      debugPrint('Error submitting complete pra registration: $e');
      AppSnackbar.error(
        title: 'Error',
        message: 'An unexpected error occurred: $e',
      );
      return false;
    } finally {
      rxIsActionLoading.value = false;
    }
  }

  // UI Interactive States
  final rxSearchQuery = ''.obs;
  final rxLiveSearchQuery = ''.obs;
  final rxLiveCurrentPage = 0.obs;
  final rxLiveTotalPages = 0.obs;

  final rxRelatedSearchQuery = ''.obs;
  final rxRelatedCurrentPage = 0.obs;
  final rxRelatedTotalPages = 0.obs;

  final rxFeedTabIndex = 0.obs; // 0 for Live Visitors, 1 for Related Visitors
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
      'label': 'Card Issuance',
      'color': 'purple',
      'enabled': true,
    },
    {
      'icon': 'keyboard_return',
      'label': 'Card Return',
      'color': 'teal',
      'enabled': true,
    },
    {
      'icon': 'access_time',
      'label': 'Extend',
      'color': 'orange',
      'enabled': true,
    },
    {
      'icon': 'call_received',
      'label': 'Arrival',
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
    _loadInitialDashboardData();
  }

  Future<void> _loadInitialDashboardData() async {
    try {
      await fetchUserPermissions();
      await fetchRegisteredSites();
      await fetchUpcomingPurpose(filter: 'Today');
      await fetchLiveVisitors();
      await fetchAvailableCards();
      fetchPraRegistrationDependencies(silent: true);

      // If initial socket timeout occurred, auto-retry smoothly
      if (rxUpcomingPurpose.isEmpty || rxLiveVisitors.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 1200));
        if (rxUpcomingPurpose.isEmpty) {
          await fetchUpcomingPurpose(filter: 'Today');
        }
        if (rxLiveVisitors.isEmpty) {
          await fetchLiveVisitors();
        }
      }

      // Print at the very end of startup so it is clearly visible at bottom of terminal
      Future.delayed(const Duration(milliseconds: 500), () {
        _printPermissionsSummary();
      });
    } catch (_) {}
  }

  Future<void> fetchUpcomingPurpose({String filter = 'Today'}) async {
    rxIsOccupancyLoading.value = true;
    final result = await _dashboardRepository.getUpcomingPurpose(
      filter: filter,
    );
    rxIsOccupancyLoading.value = false;

    if (result is Success<Map<String, dynamic>>) {
      final resData = result.data;
      final rawList = resData['collection'] ?? resData['data'] ?? [];
      if (rawList is List) {
        final parsed = rawList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        rxUpcomingPurpose.assignAll(parsed);

        // Also sync rxOccupancy map for quick reference
        final newMap = <String, int>{};
        for (final item in parsed) {
          final name = (item['name'] ?? item['purpose'] ?? '')
              .toString()
              .toLowerCase();
          final count = int.tryParse(item['count']?.toString() ?? '0') ?? 0;
          if (name.isNotEmpty) {
            newMap[name] = count;
          }
        }
        if (newMap.isNotEmpty) {
          rxOccupancy.assignAll(newMap);
        }

        // Fetch Live Visitors for the first purpose category if active
        if (parsed.isNotEmpty) {
          final firstId = (parsed.first['id'] ?? '').toString();
          if (firstId.isNotEmpty) {
            fetchLiveVisitors(visitorTypeId: firstId);
          }
        }
      }
    }
  }

  Future<void> fetchLiveVisitors({
    String? visitorTypeId,
    String? search,
  }) async {
    String typeId = visitorTypeId ?? '';
    if (typeId.isEmpty && rxUpcomingPurpose.isNotEmpty) {
      typeId = (rxUpcomingPurpose.first['id'] ?? '').toString();
    }

    final result = await _dashboardRepository.getUpcomingVisitors(
      visitorTypeId: typeId.isNotEmpty ? typeId : 'all',
      allVisitorType: true,
      start: 0,
      length: 100,
      search: search,
    );

    if (result is Success<Map<String, dynamic>>) {
      final resData = result.data;
      final rawList = resData['collection'] ?? resData['data'] ?? [];
      if (rawList is List) {
        final mappedList = rawList.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          m['name'] = (m['visitor_name'] ?? m['name'] ?? 'Visitor').toString();
          m['visitor_name'] = m['name'];
          m['organization'] =
              (m['visitor_organization_name'] ??
                      m['organization'] ??
                      m['company'] ??
                      '')
                  .toString();
          m['visitor_organization_name'] = m['organization'];
          m['email'] = (m['visitor_email'] ?? m['email'] ?? '-').toString();
          m['phone'] = (m['visitor_phone'] ?? m['phone'] ?? '-').toString();
          m['identity_id'] =
              (m['identity_id'] ?? m['id_number'] ?? m['nik'] ?? '-')
                  .toString();
          m['gender'] = (m['visitor_gender'] ?? m['gender'] ?? 'Male')
              .toString();
          m['occupancy'] =
              (m['visitor_type_name'] ?? m['occupancy'] ?? 'Visitor')
                  .toString();
          m['faceimage'] =
              (m['selfie_image'] ??
                      m['visitor_face'] ??
                      m['faceimage'] ??
                      m['photo'] ??
                      '')
                  .toString();
          m['invitation_code'] =
              (m['invitation_code'] ??
                      m['visitor_code'] ??
                      m['initial_trx_code'] ??
                      '')
                  .toString();
          m['visitor_code'] = m['invitation_code'];
          m['transaction_visitor_id'] =
              (m['transaction_visitor_id'] ?? m['id'] ?? '').toString();
          m['id'] = m['invitation_code'].isNotEmpty
              ? m['invitation_code']
              : m['transaction_visitor_id'];
          m['visitor_status'] =
              (m['visitor_status'] ?? m['status'] ?? 'Waiting').toString();
          m['status'] = m['visitor_status'];
          m['agenda'] = (m['agenda'] ?? m['purpose'] ?? 'Meeting').toString();
          m['purpose'] = m['agenda'];
          m['vehicle_plate_number'] =
              (m['vehicle_plate_number'] ??
                      m['vehicle_plate'] ??
                      m['plate_number'] ??
                      '')
                  .toString();
          m['vehicle_type'] =
              (m['vehicle_type'] ??
                      m['vehicle_type_name'] ??
                      m['vehicle_name'] ??
                      m['vehicle'] ??
                      m['type_vehicle'] ??
                      m['vehicle_mode'] ??
                      m['transportation_type'] ??
                      m['transportation'] ??
                      m['visitor_vehicle_type'] ??
                      m['visitor_vehicle'] ??
                      '-')
                  .toString();
          m['host_name'] = (m['host_name'] ?? m['host'] ?? 'Host').toString();
          m['host'] = m['host_name'];
          m['host_organization_name'] =
              (m['host_organization_name'] ?? m['host_organization'] ?? '')
                  .toString();
          m['host_email'] = (m['host_email'] ?? '').toString();
          m['host_phone'] = (m['host_phone'] ?? '').toString();
          m['host_faceimage'] = (m['host_faceimage'] ?? m['host_photo'] ?? '')
              .toString();
          return m;
        }).toList();

        rxAllLiveVisitors.clear();
        rxAllLiveVisitors.addAll(mappedList);

        if (search != null && search.trim().isNotEmpty) {
          final query = search.trim().toLowerCase();
          final filtered = mappedList.where((item) {
            final name = (item['name'] ?? '').toString().toLowerCase();
            return name.contains(query);
          }).toList();
          rxLiveVisitors.assignAll(filtered);
        } else {
          rxLiveVisitors.assignAll(mappedList);
        }

        final liveTotal = rxLiveVisitors.isNotEmpty
            ? (rxLiveVisitors.length / 10).ceil()
            : 0;
        rxLiveTotalPages.value = liveTotal;
        if (liveTotal == 0) {
          rxLiveCurrentPage.value = 0;
        } else {
          if (rxLiveCurrentPage.value > liveTotal) {
            rxLiveCurrentPage.value = liveTotal;
          }
          if (rxLiveCurrentPage.value < 1) {
            rxLiveCurrentPage.value = 1;
          }
        }
      } else {
        rxLiveVisitors.clear();
        rxAllLiveVisitors.clear();
        rxLiveTotalPages.value = 0;
        rxLiveCurrentPage.value = 0;
      }
    } else {
      rxLiveVisitors.clear();
      rxAllLiveVisitors.clear();
      rxLiveTotalPages.value = 0;
      rxLiveCurrentPage.value = 0;
    }
  }

  Future<void> fetchUpcomingVisitors({
    String? visitorTypeId,
    int? page,
    int? length,
    String? search,
  }) async {
    final typeId = visitorTypeId ?? rxSelectedPurposeId.value;
    if (typeId.isEmpty) return;

    final targetPage = page ?? rxUpcomingVisitorsPage.value;
    final targetLength = length ?? rxUpcomingVisitorsLength.value;
    final targetSearch = search ?? rxUpcomingVisitorsSearch.value;

    rxIsUpcomingVisitorsLoading.value = true;
    final start = (targetPage - 1) * targetLength;
    final result = await _dashboardRepository.getUpcomingVisitors(
      visitorTypeId: typeId,
      allVisitorType: false,
      start: start,
      length: targetLength,
      search: targetSearch.isNotEmpty ? targetSearch : null,
    );
    rxIsUpcomingVisitorsLoading.value = false;

    if (result is Success<Map<String, dynamic>>) {
      final resData = result.data;
      final rawList = (resData['collection'] is List)
          ? resData['collection'] as List
          : ((resData['collection'] is Map &&
                    resData['collection']['data'] is List)
                ? resData['collection']['data'] as List
                : (resData['data'] is List ? resData['data'] as List : []));

      if (rawList.isNotEmpty) {
        var mappedList = rawList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        // 1. Strict Category Isolation: If specific visitor type was requested, filter items to match that category
        final selectedCatName = rxSelectedPurposeCategory.value
            .trim()
            .toLowerCase();
        if (typeId.isNotEmpty && typeId.toLowerCase() != 'all') {
          final typeFiltered = mappedList.where((item) {
            final vTypeId =
                (item['visitor_type'] ??
                        item['visitor_type_id'] ??
                        item['visitor']?['visitor_type'] ??
                        '')
                    .toString()
                    .trim();
            final vTypeName =
                (item['visitor_type_name'] ??
                        item['occupancy'] ??
                        item['category'] ??
                        item['visitor']?['visitor_type_name'] ??
                        '')
                    .toString()
                    .trim()
                    .toLowerCase();

            if (vTypeId.isNotEmpty && vTypeId == typeId) return true;
            if (selectedCatName.isNotEmpty &&
                (vTypeName == selectedCatName ||
                    vTypeName.contains(selectedCatName) ||
                    selectedCatName.contains(vTypeName))) {
              return true;
            }
            return false;
          }).toList();

          if (typeFiltered.isNotEmpty) {
            mappedList = typeFiltered;
          }
        }

        // 2. Parse total records directly from API DataTables response
        int apiTotal = 0;
        if (resData['recordsFiltered'] != null) {
          apiTotal = int.tryParse(resData['recordsFiltered'].toString()) ?? 0;
        } else if (resData['recordsTotal'] != null) {
          apiTotal = int.tryParse(resData['recordsTotal'].toString()) ?? 0;
        } else if (resData['total'] != null) {
          apiTotal = int.tryParse(resData['total'].toString()) ?? 0;
        } else if (resData['total_records'] != null) {
          apiTotal = int.tryParse(resData['total_records'].toString()) ?? 0;
        } else if (resData['count'] != null) {
          apiTotal = int.tryParse(resData['count'].toString()) ?? 0;
        } else if (resData['collection'] is Map) {
          final c = resData['collection'] as Map;
          apiTotal =
              int.tryParse(
                (c['recordsFiltered'] ??
                        c['recordsTotal'] ??
                        c['total'] ??
                        c['count'] ??
                        0)
                    .toString(),
              ) ??
              0;
        }

        // Cross-check with category's count from rxUpcomingPurpose
        final matchingPurpose = rxUpcomingPurpose.firstWhereOrNull((p) {
          final pId = (p['id'] ?? p['visitor_type_id'] ?? '').toString();
          final pName = (p['name'] ?? p['purpose'] ?? '')
              .toString()
              .toLowerCase();
          return (pId.isNotEmpty && pId == typeId) ||
              (selectedCatName.isNotEmpty &&
                  (pName == selectedCatName ||
                      pName.contains(selectedCatName) ||
                      selectedCatName.contains(pName)));
        });
        final categoryCount = matchingPurpose != null
            ? (int.tryParse(
                    (matchingPurpose['count'] ?? matchingPurpose['total'] ?? 0)
                        .toString(),
                  ) ??
                  0)
            : 0;

        if (categoryCount > 0 &&
            (apiTotal == 0 ||
                apiTotal > categoryCount &&
                    mappedList.length <= categoryCount)) {
          apiTotal = categoryCount;
        }

        // Strict filtering by Visitor Name if search query is active
        if (targetSearch.trim().isNotEmpty) {
          final query = targetSearch.trim().toLowerCase();
          mappedList = mappedList.where((item) {
            final name =
                (item['visitor_name'] ??
                        item['name'] ??
                        item['full_name'] ??
                        item['visitor_full_name'] ??
                        item['guest_name'] ??
                        item['visitor']?['name'] ??
                        item['visitor']?['visitor_name'] ??
                        item['visitor']?['full_name'] ??
                        item['raw']?['name'] ??
                        item['raw']?['visitor_name'] ??
                        '')
                    .toString()
                    .toLowerCase();
            return name.contains(query);
          }).toList();
          apiTotal = mappedList.length;
        }

        if (apiTotal == 0) {
          apiTotal = mappedList.length;
        }

        rxUpcomingVisitorsTotal.value = apiTotal;
        rxUpcomingVisitorsPage.value = targetPage;
        rxUpcomingVisitorsLength.value = targetLength;
        rxUpcomingVisitorsList.assignAll(mappedList);
      } else {
        rxUpcomingVisitorsList.clear();
        rxUpcomingVisitorsTotal.value = 0;
      }
    } else {
      rxUpcomingVisitorsList.clear();
      rxUpcomingVisitorsTotal.value = 0;
    }
  }

  Future<void> fetchDashboardData() async {
    // No automatic summary/visitors calls since API endpoints do not exist in backend
    fetchUpcomingPurpose(filter: 'Today');
  }

  // --- Real-time Search, Status Filtering, and Pagination computation ---
  void applyFiltersAndPagination() {
    var list = List<Map<String, dynamic>>.from(rxAllRelatedVisitors);

    // 1. Strict Search Query filtering by Visitor Name ONLY
    final query = rxRelatedSearchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((visitor) {
        final name = (visitor['name'] ?? visitor['visitor_name'] ?? '')
            .toString()
            .toLowerCase();
        return name.contains(query);
      }).toList();
    }

    rxRelatedVisitors.assignAll(list);
    final total = list.isNotEmpty ? (list.length / 10).ceil() : 0;
    rxRelatedTotalPages.value = total;
    rxTotalPages.value = total;

    if (total == 0) {
      rxRelatedCurrentPage.value = 0;
    } else {
      if (rxRelatedCurrentPage.value > total) {
        rxRelatedCurrentPage.value = total;
      }
      if (rxRelatedCurrentPage.value < 1) {
        rxRelatedCurrentPage.value = 1;
      }
    }
    rxCurrentPage.value = rxRelatedCurrentPage.value;
  }

  void filterVisitors(String query) {
    if (rxFeedTabIndex.value == 0) {
      rxLiveSearchQuery.value = query;
      if (query.trim().isEmpty) {
        rxLiveVisitors.assignAll(rxAllLiveVisitors);
      } else {
        final lower = query.trim().toLowerCase();
        // Strict filtering by Visitor Name ONLY
        final filtered = rxAllLiveVisitors.where((item) {
          final name = (item['name'] ?? item['visitor_name'] ?? '')
              .toString()
              .toLowerCase();
          return name.contains(lower);
        }).toList();
        rxLiveVisitors.assignAll(filtered);
      }
      final total = rxLiveVisitors.isNotEmpty
          ? (rxLiveVisitors.length / 10).ceil()
          : 0;
      rxLiveTotalPages.value = total;
      rxLiveCurrentPage.value = total > 0 ? 1 : 0;
    } else {
      rxRelatedSearchQuery.value = query;
      applyFiltersAndPagination();
      rxRelatedCurrentPage.value = rxRelatedTotalPages.value > 0 ? 1 : 0;
    }
  }

  void clearSearch() {
    filterVisitors('');
  }

  /// Reset all visitor data, related feeds, tabs, and search back to the clean initial empty state
  void resetDashboardToInitialState() {
    rxSelectedVisitor.value = null;
    rxPrimaryHost.value = null;
    rxAllRelatedVisitors.clear();
    rxRelatedVisitors.clear();
    rxSelectedItems.clear();
    rxSelectMultiple.value = false;
    rxFeedTabIndex.value = 0;
    rxTimeline.clear();
    rxSearchQuery.value = '';
    rxLiveSearchQuery.value = '';
    rxLiveCurrentPage.value = 0;
    rxLiveTotalPages.value = 0;
    rxRelatedSearchQuery.value = '';
    rxRelatedCurrentPage.value = 0;
    rxRelatedTotalPages.value = 0;
    rxActiveFilter.value = 'All';
    rxCurrentPage.value = 0;
    rxTotalPages.value = 0;
    applyFiltersAndPagination();
  }

  Future<bool> blacklistVisitor({
    required String reason,
    String? targetVisitorId,
    String? invitationCode,
  }) async {
    final visitor = rxSelectedVisitor.value;
    String vId = targetVisitorId ?? '';
    String invCode = invitationCode ?? '';

    if (vId.isEmpty && visitor != null) {
      vId =
          (visitor['visitor_id'] ??
                  visitor['visitor']?['id'] ??
                  visitor['visitor']?['visitor_id'] ??
                  visitor['raw']?['visitor_id'] ??
                  visitor['raw']?['visitor']?['id'] ??
                  '')
              .toString()
              .trim();
    }

    if (invCode.isEmpty && visitor != null) {
      invCode = (visitor['invitation_code'] ?? '').toString().trim();
    }

    // Step 1: If vId is missing/empty, or if we have an invitation code, call /api/operator-invitation/search to extract visitor_id
    if ((vId.isEmpty || vId == '-' || vId == 'null') &&
        invCode.isNotEmpty &&
        invCode != '-') {
      rxIsActionLoading.value = true;
      final searchResult = await _dashboardRepository.searchInvitation(invCode);
      if (searchResult is Success<Map<String, dynamic>>) {
        final searchData = searchResult.data;
        final coll = searchData['collection'] ?? searchData['data'];
        final list =
            (coll is Map ? coll['data'] : (coll is List ? coll : [])) as List?;
        if (list != null && list.isNotEmpty) {
          final firstItem = Map<String, dynamic>.from(list[0] as Map);
          vId =
              (firstItem['visitor_id'] ??
                      firstItem['visitor']?['id'] ??
                      firstItem['visitor']?['visitor_id'] ??
                      firstItem['id'] ??
                      '')
                  .toString()
                  .trim();
        }
      }
    }

    // Fallback if still empty: use transaction id / visitor id
    if (vId.isEmpty && visitor != null) {
      vId =
          (visitor['id'] ??
                  visitor['trx_id'] ??
                  visitor['transaction_visitor_id'] ??
                  '')
              .toString()
              .trim();
    }

    if (vId.isEmpty) {
      AppSnackbar.error(
        title: 'Validation Error',
        message: 'Could not determine visitor ID to blacklist.',
      );
      return false;
    }

    final actualReason = reason.trim();
    if (actualReason.isEmpty) {
      AppSnackbar.warning(
        title: 'Reason Required',
        message: 'Please provide a reason for blacklisting this visitor.',
      );
      return false;
    }

    rxIsActionLoading.value = true;
    final result = await _dashboardRepository.blacklistVisitor(
      visitorId: vId,
      reason: actualReason,
      action: 'blacklist',
    );
    rxIsActionLoading.value = false;

    bool isSuccess = result is Success;

    if (result is Failure) {
      final err = (result as Failure).exception.message;
      if (err.toLowerCase().contains('blacklisted') ||
          err.toLowerCase().contains('blacklist')) {
        // Backend confirms the visitor is indeed blacklisted
        isSuccess = true;
      } else {
        AppSnackbar.error(
          title: 'Blacklist Failed',
          message: err.isNotEmpty ? err : 'Failed to blacklist visitor',
        );
        return false;
      }
    }

    if (isSuccess) {
      // 1. Record ID into rxBlacklistedVisitorIds
      rxBlacklistedVisitorIds.add(vId);

      // 2. Update active visitor state in memory
      if (visitor != null) {
        final updated = Map<String, dynamic>.from(visitor);
        updated['is_block'] = true;
        updated['last_activity'] = 'Blacklist';
        updated['block_reason'] = actualReason;
        updated['visitor_status'] = 'Blacklist';
        updated['status'] = 'Blacklist';
        rxSelectedVisitor.value = updated;

        final trxId =
            (updated['trx_id'] ??
                    updated['id'] ??
                    updated['transaction_visitor_id'])
                .toString();
        final matchIdx = rxAllRelatedVisitors.indexWhere(
          (v) =>
              (v['trx_id'] ?? v['id'] ?? v['transaction_visitor_id'])
                      .toString() ==
                  trxId ||
              (v['visitor_id'] ?? '').toString() == vId,
        );
        if (matchIdx != -1) {
          rxAllRelatedVisitors[matchIdx] = updated;
        }

        final liveIdx = rxAllLiveVisitors.indexWhere(
          (v) =>
              (v['trx_id'] ?? v['id'] ?? v['transaction_visitor_id'])
                      .toString() ==
                  trxId ||
              (v['visitor_id'] ?? '').toString() == vId,
        );
        if (liveIdx != -1) {
          rxAllLiveVisitors[liveIdx] = updated;
        }

        applyFiltersAndPagination();

        // 3. Add Timeline Entry
        final nowFormatted =
            formatApiTime(DateTime.now().toIso8601String()) ?? '12:00';
        rxTimeline.insert(0, {
          'time': nowFormatted,
          'title': 'Visitor Blacklisted',
          'desc': 'Reason: $actualReason',
          'status': 'block',
        });
      }

      final visitorName = (visitor?['name'] ?? visitor?['visitor_name'] ?? '')
          .toString()
          .trim();
      final displayName = visitorName.isNotEmpty && visitorName != '-'
          ? visitorName
          : 'Visitor';

      AppSnackbar.success(
        title: 'Visitor Blacklisted',
        message: '$displayName has been blacklisted successfully.',
      );

      // Auto-refresh feeds in background so all counts and lists reflect the blacklist status
      fetchLiveVisitors();
      fetchUpcomingPurpose(filter: 'Today');

      return true;
    }
    return false;
  }

  // --- Registered Sites (/api/operator-invitation/registered-site) ---
  Future<void> fetchRegisteredSites() async {
    final result = await _dashboardRepository.fetchRegisteredSites();
    if (result is Success<Map<String, dynamic>>) {
      final resData = result.data;
      final rawList = resData['collection'] ?? resData['data'];
      if (rawList is List) {
        rxRegisteredSites.assignAll(
          rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );
        if (rxRegisteredSites.isNotEmpty) {
          final match =
              rxRegisteredSites.firstWhereOrNull(
                (s) =>
                    (s['name'] ?? '').toString().toLowerCase() ==
                    rxSelectedSiteName.value.toLowerCase(),
              ) ??
              rxRegisteredSites.first;
          rxSelectedSiteId.value = (match['id'] ?? '').toString();
          if (rxSelectedSiteName.value.isEmpty) {
            rxSelectedSiteName.value = (match['name'] ?? 'SPU').toString();
          }
        }
      }
    }
  }

  // --- Available Cards (/api/operator-invitation/available-cards) ---
  Future<void> fetchAvailableCards() async {
    rxIsAvailableCardsLoading.value = true;
    final result = await _dashboardRepository.fetchAvailableCards();
    rxIsAvailableCardsLoading.value = false;

    if (result is Success<Map<String, dynamic>>) {
      final resData = result.data;
      final rawList = resData['collection'] ?? resData['data'];
      if (rawList is List) {
        rxAvailableCards.assignAll(
          rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );
      }
    }
  }

  // --- Return Access Card (/api/operator-invitation/return-access-card) ---
  Future<bool> returnAccessCard({
    required String cardNumber,
    String? targetTrxVisitorId,
    String? targetRegisteredSiteId,
    String? invitationCode,
  }) async {
    final visitor = rxSelectedVisitor.value;
    String trxId = targetTrxVisitorId ?? '';
    String invCode = invitationCode ?? '';
    String cardNum = cardNumber.trim();

    if (trxId.isEmpty && visitor != null) {
      trxId =
          (visitor['trx_id'] ??
                  visitor['id'] ??
                  visitor['transaction_visitor_id'] ??
                  visitor['raw']?['id'] ??
                  '')
              .toString()
              .trim();
    }

    if (invCode.isEmpty && visitor != null) {
      invCode = (visitor['invitation_code'] ?? '').toString().trim();
    }

    // If trxId is still empty, search via invitation code
    if ((trxId.isEmpty || trxId == '-' || trxId == 'null') &&
        invCode.isNotEmpty &&
        invCode != '-') {
      rxIsActionLoading.value = true;
      final searchResult = await _dashboardRepository.searchInvitation(invCode);
      if (searchResult is Success<Map<String, dynamic>>) {
        final searchData = searchResult.data;
        final coll = searchData['collection'] ?? searchData['data'];
        final list =
            (coll is Map ? coll['data'] : (coll is List ? coll : [])) as List?;
        if (list != null && list.isNotEmpty) {
          final firstItem = Map<String, dynamic>.from(list[0] as Map);
          trxId =
              (firstItem['id'] ??
                      firstItem['transaction_visitor_id'] ??
                      firstItem['trx_id'] ??
                      '')
                  .toString()
                  .trim();
        }
      }
    }

    if (trxId.isEmpty) {
      AppSnackbar.error(
        title: 'Validation Error',
        message: 'Could not determine transaction visitor ID for return card.',
      );
      return false;
    }

    if (cardNum.isEmpty) {
      AppSnackbar.warning(
        title: 'Card Number Required',
        message: 'Please enter a valid card number to return.',
      );
      return false;
    }

    // Resolve registered_site_id
    String siteId = targetRegisteredSiteId ?? '';
    if (siteId.isEmpty && visitor != null) {
      final cards =
          (visitor['cards'] as List?) ?? (visitor['card'] as List?) ?? [];
      if (cards.isNotEmpty) {
        final cMatch =
            cards.firstWhereOrNull(
              (c) =>
                  (c['card_number'] ?? c['card_barcode'] ?? '').toString() ==
                  cardNum,
            ) ??
            cards.first;
        siteId = (cMatch['registered_site_id'] ?? '').toString().trim();
      }
    }

    if (siteId.isEmpty && rxRegisteredSites.isNotEmpty) {
      final match =
          rxRegisteredSites.firstWhereOrNull(
            (s) =>
                (s['name'] ?? '').toString().toLowerCase() ==
                rxSelectedSiteName.value.toLowerCase(),
          ) ??
          rxRegisteredSites.first;
      siteId = (match['id'] ?? '').toString().trim();
    }

    if (siteId.isEmpty) {
      siteId = rxSelectedSiteId.value.isNotEmpty
          ? rxSelectedSiteId.value
          : '1D6C9704-F6AB-47BD-A6B0-3E1FB3D6FAEA';
    }

    rxIsActionLoading.value = true;
    final result = await _dashboardRepository.returnAccessCard(
      trxVisitorId: trxId,
      cardNumber: cardNum,
      registeredSiteId: siteId,
    );
    rxIsActionLoading.value = false;

    if (result is Success<Map<String, dynamic>>) {
      // Update in-memory card list
      if (visitor != null) {
        final updated = Map<String, dynamic>.from(visitor);
        final rawCards =
            (updated['card'] as List?) ?? (updated['cards'] as List?) ?? [];
        final newCards = <Map<String, dynamic>>[];
        for (final c in rawCards) {
          final cardMap = Map<String, dynamic>.from(c as Map);
          if ((cardMap['card_number'] ?? cardMap['card_barcode'] ?? '')
                  .toString() ==
              cardNum) {
            cardMap['card_status'] = 'Revoked';
            cardMap['current_used'] = false;
          }
          newCards.add(cardMap);
        }
        updated['card'] = newCards;
        updated['cards'] = newCards;
        rxSelectedVisitor.value = updated;

        // Insert Timeline Entry
        final nowFormatted =
            formatApiTime(DateTime.now().toIso8601String()) ?? '12:00';
        rxTimeline.insert(0, {
          'time': nowFormatted,
          'title': 'Card Returned',
          'desc': 'Card Number: $cardNum returned to site',
          'status': 'return',
        });
      }

      AppSnackbar.success(
        title: 'Card Returned',
        message: 'Card $cardNum has been returned successfully.',
      );

      syncCurrentInvitationState();
      fetchLiveVisitors();
      fetchAvailableCards();
      return true;
    } else if (result is Failure) {
      final err = (result as Failure).exception.message;
      AppSnackbar.error(
        title: 'Return Card Failed',
        message: err.isNotEmpty ? err : 'Failed to return access card',
      );
      return false;
    }
    return false;
  }

  // --- Grant Access Card (/api/operator-invitation/grant-access-card) ---
  Future<bool> grantAccessCard({
    required String cardNumber,
    Map<String, dynamic>? selectedCard,
    String? targetTrxVisitorId,
    bool isSwapCard = false,
    String swapType = 'Other',
    String? customSwapCardFrom,
    String? customDescription,
  }) async {
    final visitor = rxSelectedVisitor.value;
    String trxId = targetTrxVisitorId ?? '';
    String invCode = (visitor?['invitation_code'] ?? '').toString().trim();
    String cardNum = cardNumber.trim();

    if (trxId.isEmpty && visitor != null) {
      trxId =
          (visitor['trx_id'] ??
                  visitor['id'] ??
                  visitor['transaction_visitor_id'] ??
                  visitor['raw']?['id'] ??
                  '')
              .toString()
              .trim();
    }

    if ((trxId.isEmpty || trxId == '-' || trxId == 'null') &&
        invCode.isNotEmpty &&
        invCode != '-') {
      rxIsActionLoading.value = true;
      final searchResult = await _dashboardRepository.searchInvitation(invCode);
      if (searchResult is Success<Map<String, dynamic>>) {
        final searchData = searchResult.data;
        final coll = searchData['collection'] ?? searchData['data'];
        final list =
            (coll is Map ? coll['data'] : (coll is List ? coll : [])) as List?;
        if (list != null && list.isNotEmpty) {
          final firstItem = Map<String, dynamic>.from(list[0] as Map);
          trxId =
              (firstItem['id'] ??
                      firstItem['transaction_visitor_id'] ??
                      firstItem['trx_id'] ??
                      '')
                  .toString()
                  .trim();
        }
      }
    }

    if (trxId.isEmpty) {
      AppSnackbar.error(
        title: 'Validation Error',
        message:
            'Could not determine transaction visitor ID for granting card.',
      );
      return false;
    }

    // Resolve registered_site_id
    String siteId = rxSelectedSiteId.value.trim();
    if (siteId.isEmpty && rxRegisteredSites.isNotEmpty) {
      siteId = (rxRegisteredSites.first['id'] ?? '').toString().trim();
    }
    if (siteId.isEmpty) {
      await fetchRegisteredSites();
      if (rxRegisteredSites.isNotEmpty) {
        siteId = (rxRegisteredSites.first['id'] ?? '').toString().trim();
      }
    }

    // Resolve current card from visitor for swap_card_from_card and swap_card_from_card_id
    String currentCardNum =
        (customSwapCardFrom != null && customSwapCardFrom.isNotEmpty)
        ? customSwapCardFrom.trim()
        : '';
    String currentCardId = '';
    final visitorCards =
        (visitor?['card'] as List?) ?? (visitor?['cards'] as List?) ?? [];
    if (visitorCards.isNotEmpty) {
      final activeCard =
          visitorCards.firstWhereOrNull((c) => c['current_used'] == true) ??
          Map<String, dynamic>.from(visitorCards.first as Map);
      if (currentCardNum.isEmpty) {
        currentCardNum =
            (activeCard['card_number'] ?? activeCard['card_barcode'] ?? '')
                .toString()
                .trim();
      }
      currentCardId = (activeCard['id'] ?? '').toString().trim();
    }

    if (currentCardNum.isEmpty) {
      currentCardNum =
          (visitor?['visitor_card'] ??
                  visitor?['visitor_code'] ??
                  visitor?['visitor_ble_card'] ??
                  visitor?['identity_id'] ??
                  '')
              .toString()
              .trim();
    }
    if (currentCardId.isEmpty && visitor != null) {
      currentCardId = (visitor['id'] ?? visitor['visitor_id'] ?? '')
          .toString()
          .trim();
    }

    final desc =
        customDescription ??
        (isSwapCard
            ? 'Swap card number $cardNum from $siteId'
            : 'Give card number $cardNum from $siteId');

    rxIsActionLoading.value = true;
    final result = await _dashboardRepository.grantAccessCard(
      cardNumber: cardNum,
      trxVisitorId: trxId,
      description: desc,
      swapCardFromCard: currentCardNum,
      swapCardFromCardId: currentCardId,
      swapCardFromSiteId: siteId,
      isSwapCard: isSwapCard,
      swapType: swapType.trim(),
      registeredSiteId: siteId,
    );
    rxIsActionLoading.value = false;

    if (result is Success<Map<String, dynamic>>) {
      final nowFormatted =
          formatApiTime(DateTime.now().toIso8601String()) ?? '12:00';
      final actionTitle = isSwapCard ? 'Card Swapped' : 'Card Granted';
      final actionDesc = isSwapCard
          ? 'Card Number: $cardNum swapped ($swapType)'
          : 'Card Number: $cardNum given to visitor';

      rxTimeline.insert(0, {
        'time': nowFormatted,
        'title': actionTitle,
        'desc': actionDesc,
        'status': 'issued',
      });

      AppSnackbar.success(
        title: actionTitle,
        message: isSwapCard
            ? 'Card $cardNum has been swapped successfully.'
            : 'Card $cardNum has been given successfully.',
      );

      syncCurrentInvitationState();
      fetchLiveVisitors();
      fetchAvailableCards();
      return true;
    } else if (result is Failure) {
      final err = (result as Failure).exception.message;
      AppSnackbar.error(
        title: isSwapCard ? 'Swap Card Failed' : 'Grant Card Failed',
        message: err.isNotEmpty ? err : 'Failed to grant access card',
      );
      return false;
    }

    return false;
  }

  // --- Grant Access Card Multiple (/api/operator-invitation/grant-access-card-multiple) ---
  Future<bool> grantAccessCardMultiple({
    required List<Map<String, dynamic>> items,
    bool isSwapCard = false,
  }) async {
    if (items.isEmpty) {
      AppSnackbar.warning(
        title: 'Validation Error',
        message: 'No visitors selected for card issuance.',
      );
      return false;
    }

    // Resolve site ID
    String siteId = rxSelectedSiteId.value.trim();
    if (siteId.isEmpty && rxRegisteredSites.isNotEmpty) {
      siteId = (rxRegisteredSites.first['id'] ?? '').toString().trim();
    }
    if (siteId.isEmpty) {
      await fetchRegisteredSites();
      if (rxRegisteredSites.isNotEmpty) {
        siteId = (rxRegisteredSites.first['id'] ?? '').toString().trim();
      }
    }

    final dataList = <Map<String, dynamic>>[];

    for (final item in items) {
      final visitor = item['visitor'] as Map<String, dynamic>?;
      final cardNum = (item['card_number'] ?? '').toString().trim();
      String trxVisitorId =
          (item['trx_visitor_id'] ??
                  visitor?['id'] ??
                  visitor?['transaction_visitor_id'] ??
                  visitor?['trx_id'] ??
                  '')
              .toString()
              .trim();

      // Resolve trx_card_id from visitor's current card
      String trxCardId = (item['trx_card_id'] ?? '').toString().trim();
      String currentCardNum = (item['swap_card_from_card'] ?? '')
          .toString()
          .trim();
      String currentCardId = (item['swap_card_from_card_id'] ?? '')
          .toString()
          .trim();

      final visitorCards =
          (visitor?['card'] as List?) ?? (visitor?['cards'] as List?) ?? [];
      if (visitorCards.isNotEmpty) {
        final activeCard =
            visitorCards.firstWhereOrNull((c) => c['current_used'] == true) ??
            Map<String, dynamic>.from(visitorCards.first as Map);
        if (trxCardId.isEmpty) {
          trxCardId = (activeCard['id'] ?? '').toString().trim();
        }
        if (currentCardNum.isEmpty) {
          currentCardNum =
              (activeCard['card_number'] ?? activeCard['card_barcode'] ?? '')
                  .toString()
                  .trim();
        }
        if (currentCardId.isEmpty) {
          currentCardId = (activeCard['id'] ?? '').toString().trim();
        }
      }

      if (trxCardId.isEmpty && visitor != null) {
        trxCardId = (visitor['id'] ?? visitor['transaction_visitor_id'] ?? '')
            .toString()
            .trim();
      }
      if (currentCardNum.isEmpty && visitor != null) {
        currentCardNum =
            (visitor['visitor_card'] ??
                    visitor['visitor_code'] ??
                    visitor['visitor_ble_card'] ??
                    visitor['identity_id'] ??
                    '')
                .toString()
                .trim();
      }
      if (currentCardId.isEmpty && visitor != null) {
        currentCardId = (visitor['id'] ?? visitor['visitor_id'] ?? '')
            .toString()
            .trim();
      }

      String visitorSiteId = '';
      if (visitor != null) {
        final trackingBle = (visitor['tracking_ble'] as List?);
        if (trackingBle != null && trackingBle.isNotEmpty) {
          visitorSiteId = (trackingBle[0]['site_id'] ?? '').toString().trim();
        }
        if (visitorSiteId.isEmpty) {
          final trxSites = (visitor['trx_visitor_sites'] as List?);
          if (trxSites != null && trxSites.isNotEmpty) {
            visitorSiteId = (trxSites[0]['site_id'] ?? trxSites[0]['id'] ?? '')
                .toString()
                .trim();
          }
        }
        if (visitorSiteId.isEmpty) {
          visitorSiteId =
              (visitor['site_id'] ?? visitor['registered_site_id'] ?? '')
                  .toString()
                  .trim();
        }
      }
      if (visitorSiteId.isEmpty) {
        visitorSiteId = siteId;
      }

      final swapType =
          (item['swap_type'] ?? (isSwapCard ? 'CardAccess' : 'NIK'))
              .toString()
              .trim();
      final desc = (item['description'] ?? '').toString().trim().isNotEmpty
          ? item['description'].toString().trim()
          : (isSwapCard
                ? 'Swap card number $cardNum from $siteId'
                : 'Give card number $cardNum from $siteId');

      dataList.add({
        'card_number': cardNum,
        'trx_visitor_id': trxVisitorId,
        'description': desc,
        'trx_card_id': trxCardId,
        'swap_card_from_card': currentCardNum,
        'swap_card_from_card_id': currentCardId,
        'swap_card_from_site_id': siteId,
        'swap_type': swapType,
        'is_swapcard': isSwapCard,
        'registered_site_id': siteId,
      });
    }

    final payload = {'data': dataList};

    rxIsActionLoading.value = true;
    final result = await _dashboardRepository.grantAccessCardMultiple(payload);
    rxIsActionLoading.value = false;

    if (result is Success<Map<String, dynamic>>) {
      final count = dataList.length;
      final actionTitle = isSwapCard
          ? 'Multiple Cards Swapped'
          : 'Multiple Cards Granted';
      final actionMsg = isSwapCard
          ? '$count cards have been swapped successfully.'
          : '$count cards have been given successfully.';

      final nowFormatted =
          formatApiTime(DateTime.now().toIso8601String()) ?? '12:00';
      rxTimeline.insert(0, {
        'time': nowFormatted,
        'title': actionTitle,
        'desc': actionMsg,
        'status': 'issued',
      });

      AppSnackbar.success(title: actionTitle, message: actionMsg);

      // Unselect multiple after completion
      rxSelectMultiple.value = false;
      rxSelectedItems.clear();

      syncCurrentInvitationState();
      fetchLiveVisitors();
      fetchAvailableCards();
      return true;
    } else if (result is Failure) {
      final err = (result as Failure).exception.message;
      AppSnackbar.error(
        title: isSwapCard ? 'Multiple Swap Failed' : 'Multiple Grant Failed',
        message: err.isNotEmpty
            ? err
            : 'Failed to process multiple card issuance',
      );
      return false;
    }

    return false;
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

    final lowerAction = action.toLowerCase();

    // Direct Blacklist action to dedicated blacklist API endpoint (/api/operator-invitation/blacklist)
    if (lowerAction == 'blacklist') {
      return await blacklistVisitor(
        reason: reason ?? 'Blacklisted by operator',
      );
    }

    final rawStatus = (visitor['visitor_status'] ?? visitor['status'] ?? '')
        .toString()
        .toLowerCase();

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
      final isHost =
          visitor['is_host'] == true || visitor['raw']?['is_host'] == true;
      final isPraregisterDone =
          visitor['is_praregister_done'] == true ||
          visitor['raw']?['is_praregister_done'] == true ||
          visitor['is_complete_preregister'] == true ||
          visitor['raw']?['is_complete_preregister'] == true ||
          visitor['is_praregist_done'] == true ||
          visitor['is_filled'] == true;

      if (!isHost &&
          !isPraregisterDone &&
          (rawStatus.contains('preregis') || rawStatus.contains('praregis'))) {
        AppSnackbar.warning(
          title: 'Registration Form Required',
          message:
              'Please complete the registration form first. Visitor will be automatically checked in upon form completion.',
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
        final hasCheckinTime =
            (updated['checkin_at'] != null && updated['checkin_at'] != '-') ||
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
        final queryId =
            (rxAllRelatedVisitors.isNotEmpty
                    ? (rxAllRelatedVisitors.first['id'] ?? trxId)
                    : trxId)
                .toString();
        if (queryId.isNotEmpty) {
          final relatedResult = await _dashboardRepository
              .getInvitationRelatedVisitors(
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
              final vId = (vMap['id'] ?? vMap['transaction_visitor_id'] ?? '')
                  .toString();
              final apiStatus = (vMap['visitor_status'] ?? vMap['status'] ?? '')
                  .toString();
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
                (item) =>
                    (item['id'] ?? item['transaction_visitor_id']).toString() ==
                    vId,
              );
              if (matchIdx != -1) {
                final existing = Map<String, dynamic>.from(
                  rxAllRelatedVisitors[matchIdx],
                );
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

  Future<Map<String, dynamic>?> fetchVisitorAccessDetails(
    String visitorId,
  ) async {
    if (visitorId.isEmpty) return null;
    try {
      final res = await _dashboardRepository.getInvitationRelatedVisitors(
        visitorId,
        start: 0,
        length: 50,
        draw: 1,
      );
      if (res is Success<Map<String, dynamic>>) {
        final data = res.data;
        final rawList = (data['collection'] is List)
            ? data['collection'] as List
            : ((data['collection'] is Map && data['collection']['data'] is List)
                  ? data['collection']['data'] as List
                  : (data['data'] is List ? data['data'] as List : []));
        if (rawList.isNotEmpty) {
          final matched =
              rawList.firstWhereOrNull(
                (v) =>
                    (v['id'] ?? v['transaction_visitor_id'] ?? '').toString() ==
                    visitorId,
              ) ??
              rawList.first;
          return Map<String, dynamic>.from(matched as Map);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> extendVisitorPeriod({
    required int period,
    bool applyToAll = false,
    String? visitorId,
    List<String>? targetVisitorIds,
  }) async {
    final List<String> idsToExtend = [];

    if (targetVisitorIds != null && targetVisitorIds.isNotEmpty) {
      idsToExtend.addAll(targetVisitorIds);
    } else if (visitorId != null && visitorId.isNotEmpty) {
      idsToExtend.add(visitorId);
    } else if (rxSelectMultiple.value && rxSelectedItems.isNotEmpty) {
      final allPool = [
        ...rxAllRelatedVisitors,
        ...rxLiveVisitors,
        if (rxSelectedVisitor.value != null) rxSelectedVisitor.value!,
      ];

      for (final selKey in rxSelectedItems) {
        final found = allPool.firstWhereOrNull(
          (v) =>
              (v['id'] ?? '').toString() == selKey ||
              (v['trx_id'] ?? '').toString() == selKey ||
              (v['transaction_visitor_id'] ?? '').toString() == selKey ||
              (v['invitation_code'] ?? '').toString() == selKey ||
              (v['visitor_code'] ?? '').toString() == selKey ||
              (v['name'] ?? '').toString() == selKey,
        );
        final resolvedId =
            (found?['raw']?['id'] ??
                    found?['trx_id'] ??
                    found?['id'] ??
                    found?['transaction_visitor_id'] ??
                    selKey)
                .toString()
                .trim();
        if (resolvedId.isNotEmpty && !idsToExtend.contains(resolvedId)) {
          idsToExtend.add(resolvedId);
        }
      }
    } else {
      final v = rxSelectedVisitor.value;
      final targetId =
          (v?['raw']?['id'] ??
                  v?['trx_id'] ??
                  v?['id'] ??
                  v?['transaction_visitor_id'] ??
                  '')
              .toString()
              .trim();
      if (targetId.isNotEmpty) {
        idsToExtend.add(targetId);
      }
    }

    if (idsToExtend.isEmpty) {
      AppSnackbar.error(
        title: 'Validation Error',
        message: 'No visitor selected to extend period',
      );
      return false;
    }

    rxIsActionLoading.value = true;
    int successCount = 0;
    String lastErrorMsg = '';

    for (final targetId in idsToExtend) {
      final result = await _dashboardRepository.extendVisitorPeriod(
        id: targetId,
        period: period,
        applyToAll: applyToAll,
      );

      if (result is Success<Map<String, dynamic>>) {
        successCount++;
      } else if (result is Failure) {
        lastErrorMsg = (result as Failure).exception.message;
      }
    }
    rxIsActionLoading.value = false;

    if (successCount > 0) {
      // 1. Calculate and update visitor period end and extend_visitor_period dynamically for all related visitors
      for (int i = 0; i < rxAllRelatedVisitors.length; i++) {
        final item = Map<String, dynamic>.from(rxAllRelatedVisitors[i]);
        final itemId =
            (item['raw']?['id'] ??
                    item['trx_id'] ??
                    item['id'] ??
                    item['transaction_visitor_id'] ??
                    item['invitation_code'] ??
                    '')
                .toString();

        if (applyToAll || idsToExtend.contains(itemId)) {
          final currentEnd =
              item['visitor_period_end'] ??
              item['period_end'] ??
              item['raw']?['visitor_period_end'];
          DateTime currentEndDt =
              parseApiDateTime(currentEnd) ??
              parseApiDateTime(item['raw']?['visitor_period_end']) ??
              DateTime.now();
          final newEndDt = currentEndDt.add(Duration(minutes: period));
          final newFormattedEnd = formatLocalDateTime(newEndDt);
          final newIsoEnd = newEndDt.toUtc().toIso8601String();

          final currentExtend =
              int.tryParse((item['extend_visitor_period'] ?? 0).toString()) ??
              0;
          final newExtend = currentExtend + period;

          item['extend_visitor_period'] = newExtend;
          item['visitor_period_end'] = newFormattedEnd;
          item['period_end'] = newFormattedEnd;
          if (item['raw'] is Map) {
            final updatedRaw = Map<String, dynamic>.from(item['raw'] as Map);
            updatedRaw['extend_visitor_period'] = newExtend;
            updatedRaw['visitor_period_end'] = newIsoEnd;
            item['raw'] = updatedRaw;
          }
          rxAllRelatedVisitors[i] = item;
        }
      }

      // Also update selected visitor if affected
      if (rxSelectedVisitor.value != null) {
        final selectedId =
            (rxSelectedVisitor.value!['raw']?['id'] ??
                    rxSelectedVisitor.value!['trx_id'] ??
                    rxSelectedVisitor.value!['id'] ??
                    rxSelectedVisitor.value!['transaction_visitor_id'] ??
                    '')
                .toString();
        if (applyToAll || idsToExtend.contains(selectedId)) {
          final currentEnd =
              rxSelectedVisitor.value!['visitor_period_end'] ??
              rxSelectedVisitor.value!['period_end'] ??
              rxSelectedVisitor.value!['raw']?['visitor_period_end'];
          DateTime currentEndDt =
              parseApiDateTime(currentEnd) ??
              parseApiDateTime(
                rxSelectedVisitor.value!['raw']?['visitor_period_end'],
              ) ??
              DateTime.now();
          final newEndDt = currentEndDt.add(Duration(minutes: period));
          final newFormattedEnd = formatLocalDateTime(newEndDt);
          final newIsoEnd = newEndDt.toUtc().toIso8601String();

          final currentExtend =
              int.tryParse(
                (rxSelectedVisitor.value!['extend_visitor_period'] ?? 0)
                    .toString(),
              ) ??
              0;
          final newExtend = currentExtend + period;

          final updated = Map<String, dynamic>.from(rxSelectedVisitor.value!);
          updated['extend_visitor_period'] = newExtend;
          updated['visitor_period_end'] = newFormattedEnd;
          updated['period_end'] = newFormattedEnd;
          if (updated['raw'] is Map) {
            final updatedRaw = Map<String, dynamic>.from(updated['raw'] as Map);
            updatedRaw['extend_visitor_period'] = newExtend;
            updatedRaw['visitor_period_end'] = newIsoEnd;
            updated['raw'] = updatedRaw;
          }
          rxSelectedVisitor.value = updated;
        }
      }

      applyFiltersAndPagination();

      // 2. Add Timeline Entry
      final nowFormatted =
          formatApiTime(DateTime.now().toIso8601String()) ?? '12:00';
      rxTimeline.insert(0, {
        'time': nowFormatted,
        'title': 'Period Extended',
        'desc':
            'Extended by +$period min ($successCount visitor${successCount > 1 ? "s" : ""})',
        'status': 'extend',
      });

      AppSnackbar.success(
        title: 'Period Extended',
        message: 'Visit period extended by $period minutes successfully',
      );

      // Refresh live visitors in background
      fetchLiveVisitors();
      return true;
    } else {
      AppSnackbar.error(
        title: 'Extend Failed',
        message: lastErrorMsg.isNotEmpty
            ? lastErrorMsg
            : 'Failed to extend visitor period.',
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

    final cleanAction =
        (action == 'Check In' || action.toLowerCase() == 'checkin')
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

    if (action.toLowerCase() == 'blacklist') {
      rxIsActionLoading.value = true;
      int successCount = 0;
      for (final v in visitors) {
        final vId =
            (v['visitor_id'] ??
                    v['visitor']?['id'] ??
                    v['id'] ??
                    v['transaction_visitor_id'] ??
                    '')
                .toString()
                .trim();
        final inv = (v['invitation_code'] ?? '').toString().trim();
        final ok = await blacklistVisitor(
          reason: actualReason,
          targetVisitorId: vId,
          invitationCode: inv,
        );
        if (ok) successCount++;
      }
      rxIsActionLoading.value = false;
      if (successCount > 0) {
        AppSnackbar.success(
          title: 'Visitors Blacklisted',
          message:
              '$successCount visitor(s) have been blacklisted successfully.',
        );
        return true;
      }
      return false;
    }

    final payload = {
      'data': visitors.map((v) {
        final trxId =
            (v['trx_id'] ?? v['id'] ?? v['transaction_visitor_id'] ?? '')
                .toString();
        return {
          'trx_visitor_id': trxId,
          'action': cleanAction,
          'reason': actualReason,
        };
      }).toList(),
    };

    rxIsActionLoading.value = true;
    final result = await _dashboardRepository
        .performMultipleOperatorInvitationAction(payload);
    rxIsActionLoading.value = false;

    if (result is Success) {
      await syncCurrentInvitationState();

      AppSnackbar.success(
        title: 'Action Success',
        message:
            '$cleanAction successfully applied to ${visitors.length} visitors.',
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
    if (s == '-' || s == 'null') return null;

    // 1. Try ISO-8601 (Backend stores UTC timestamps e.g. 2026-08-18T01:00:00 -> convert to Local GMT+7)
    try {
      if (s.contains('T')) {
        if (!s.endsWith('Z') && !RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(s)) {
          return DateTime.parse('${s}Z').toLocal();
        }
        return DateTime.parse(s).toLocal();
      }
      return DateTime.parse(s).toLocal();
    } catch (_) {}

    // 2. Try Human formatted date: "18 August 2026, 19:00" or "04 Sep 2026, 07:17" (Already in Local GMT+7)
    try {
      const months = {
        'january': 1,
        'february': 2,
        'march': 3,
        'april': 4,
        'may': 5,
        'june': 6,
        'july': 7,
        'august': 8,
        'september': 9,
        'october': 10,
        'november': 11,
        'december': 12,
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'sept': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };
      final clean = s.replaceAll(',', '').trim();
      final parts = clean.split(RegExp(r'\s+'));
      if (parts.length >= 4) {
        final day = int.tryParse(parts[0]);
        final monthStr = parts[1].toLowerCase();
        final month = months[monthStr];
        final year = int.tryParse(parts[2]);
        final timeParts = parts[3].split(':');
        final hour = int.tryParse(timeParts[0]);
        final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) : 0;

        if (day != null && month != null && year != null && hour != null) {
          return DateTime(year, month, day, hour, minute ?? 0);
        }
      }
    } catch (_) {}

    return null;
  }

  String formatLocalDateTime(DateTime dt) {
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
    return formatLocalDateTime(dt);
  }

  Map<String, dynamic> mapApiVisitorToUi(Map<String, dynamic> item) {
    final hostsList = (item['hosts'] as List?) ?? [];
    Map<String, dynamic> primaryHost = {};
    if (hostsList.isNotEmpty) {
      primaryHost = Map<String, dynamic>.from(hostsList[0] as Map);
    } else {
      final hostId = (item['host'] ?? '').toString().trim();
      final itemHostName = (item['host_name'] ?? '').toString().trim();
      if (hostId.isNotEmpty &&
          hostId != '-' &&
          hostId != '00000000-0000-0000-0000-000000000000') {
        final match =
            rxPraRegHosts.firstWhereOrNull(
              (h) =>
                  (h['id'] ?? '').toString().trim().toLowerCase() ==
                  hostId.toLowerCase(),
            ) ??
            rxPraRegEmployees.firstWhereOrNull(
              (e) =>
                  (e['id'] ?? '').toString().trim().toLowerCase() ==
                  hostId.toLowerCase(),
            );
        if (match != null) primaryHost = match;
      }
      if (primaryHost.isEmpty &&
          itemHostName.isNotEmpty &&
          itemHostName != '-') {
        final match =
            rxPraRegHosts.firstWhereOrNull(
              (h) =>
                  (h['name'] ?? '').toString().trim().toLowerCase() ==
                  itemHostName.toLowerCase(),
            ) ??
            rxPraRegEmployees.firstWhereOrNull(
              (e) =>
                  (e['name'] ?? '').toString().trim().toLowerCase() ==
                  itemHostName.toLowerCase(),
            );
        if (match != null) primaryHost = match;
      }
    }

    final rawCards = (item['card'] as List?) ?? (item['cards'] as List?) ?? [];
    final parsedCards = rawCards
        .map((c) => Map<String, dynamic>.from(c as Map))
        .toList();

    final rawAccess = (item['access'] as List?) ?? [];
    final parsedAccess = rawAccess
        .map((a) => Map<String, dynamic>.from(a as Map))
        .toList();

    String sanitize(dynamic val, {String fallback = '-'}) {
      if (val == null) return fallback;
      final s = val.toString().trim();
      if (s.isEmpty || s == 'null') return fallback;
      return s;
    }

    final qPages =
        (item['question_page'] as List?) ??
        (item['visitor_question_page'] as List?) ??
        (item['visitor']?['question_page'] as List?) ??
        (item['data_visitor'] is List &&
                (item['data_visitor'] as List).isNotEmpty &&
                (item['data_visitor'] as List)[0] is Map
            ? ((item['data_visitor'] as List)[0]['question_page'] as List?)
            : null) ??
        [];
    String? qName, qEmail, qPhone, qOrg, qIdentity;
    if (qPages.isNotEmpty) {
      for (final p in qPages) {
        if (p is! Map) continue;
        final forms = (p['form'] as List?) ?? [];
        for (final f in forms) {
          if (f is! Map) continue;
          final r = (f['remarks'] ?? '').toString().toLowerCase().trim();
          final ans = (f['answer_text'] ?? '').toString().trim();
          if (ans.isNotEmpty && ans != 'null' && ans != '-') {
            if (r == 'name' || r == 'full_name' || r == 'fullname') qName = ans;
            if (r == 'email') qEmail = ans;
            if (r == 'phone') qPhone = ans;
            if (r == 'organization' || r == 'company') qOrg = ans;
            if (r == 'identity_id' || r == 'indentity_id') qIdentity = ans;
          }
        }
      }
    }

    final visitorName = sanitize(
      qName ??
          item['visitor_name'] ??
          item['visitor']?['name'] ??
          item['visitor']?['employee']?['name'] ??
          item['filled_by_name'] ??
          item['name'],
      fallback: 'Visitor',
    );
    final visitorOrg = sanitize(
      qOrg ??
          item['visitor_organization_name'] ??
          item['visitor']?['organization'] ??
          item['visitor']?['organization_name'] ??
          item['visitor']?['company'] ??
          item['organization'] ??
          item['company'] ??
          item['host_organization_name'],
    );
    final visitorEmail = sanitize(
      qEmail ??
          item['visitor_email'] ??
          item['visitor']?['email'] ??
          item['visitor_email_address'] ??
          item['filled_by_email'] ??
          item['email'],
    );
    final visitorPhone = sanitize(
      qPhone ??
          item['visitor_phone'] ??
          item['visitor']?['phone'] ??
          item['visitor_phone_number'] ??
          item['filled_by_phone'] ??
          item['phone'],
    );
    final visitorIdentityId = sanitize(
      qIdentity ??
          item['visitor_identity_id'] ??
          item['visitor']?['employee']?['identity_id'] ??
          item['visitor']?['identity_id'] ??
          item['id_number'] ??
          item['visitor_number'] ??
          item['identity_id'],
    );
    final visitorGender = sanitize(
      item['visitor_gender'] ??
          item['visitor']?['employee']?['gender'] ??
          item['gender'],
    );
    final vMap = item['visitor'] is Map ? (item['visitor'] as Map) : null;
    final vTypeMap = item['visitor_type'] is Map
        ? (item['visitor_type'] as Map)
        : null;
    final nestedVTypeMap = vMap != null && vMap['visitor_type'] is Map
        ? (vMap['visitor_type'] as Map)
        : null;

    String? resolvedTypeName =
        item['visitor_type_name']?.toString() ??
        vTypeMap?['name']?.toString() ??
        vMap?['visitor_type_name']?.toString() ??
        nestedVTypeMap?['name']?.toString() ??
        item['occupancy']?.toString() ??
        item['category']?.toString();

    if (resolvedTypeName == null ||
        resolvedTypeName.isEmpty ||
        resolvedTypeName == '-' ||
        resolvedTypeName == 'null') {
      final vTypeId =
          (item['visitor_type'] ??
                  item['visitor_type_id'] ??
                  vMap?['visitor_type'] ??
                  '')
              .toString()
              .trim();
      if (vTypeId.isNotEmpty && vTypeId != '-' && vTypeId != 'null') {
        final match = rxPraRegVisitorTypes.firstWhereOrNull(
          (t) =>
              (t['id'] ?? '').toString().trim().toLowerCase() ==
              vTypeId.toLowerCase(),
        );
        if (match != null) {
          resolvedTypeName = (match['name'] ?? match['visitor_type_name'] ?? '')
              .toString()
              .trim();
        }
      }
    }

    final visitorRole = sanitize(item['visitor_role'], fallback: '-');
    final visitorTypeName = sanitize(resolvedTypeName, fallback: '-');
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
          item['plate_number'] ??
          item['parking_slot'],
    );
    final vehiclePlate = rawPlate;
    final rawVehicleType =
        item['vehicle_type'] ??
        item['vehicle_type_name'] ??
        item['vehicle_name'] ??
        item['vehicle'] ??
        item['type_vehicle'] ??
        item['vehicle_mode'] ??
        item['transportation_type'] ??
        item['transportation'] ??
        item['visitor_vehicle_type'] ??
        item['visitor_vehicle'] ??
        item['vehicle']?['vehicle_type'] ??
        item['vehicle']?['name'] ??
        item['vehicle']?['type'] ??
        item['visitor']?['vehicle_type'] ??
        item['visitor']?['vehicle'];
    final vehicleType = sanitize(rawVehicleType);
    final invitedBy = sanitize(item['invited_by_name'] ?? item['host_name']);
    final agenda = sanitize(
      item['agenda'] ?? item['remarks'],
      fallback: 'Meeting',
    );
    String rawSiteName = sanitize(
      item['site_place_name'] ?? item['site'],
      fallback: 'Gedung SINERGI',
    );
    if (rxPraRegSites.isNotEmpty) {
      final matchedSite = rxPraRegSites.firstWhereOrNull(
        (s) =>
            (s['name'] ?? '').toString().trim().toLowerCase() ==
                rawSiteName.toLowerCase() ||
            (s['id'] ?? '').toString().trim().toLowerCase() ==
                rawSiteName.toLowerCase(),
      );
      if (matchedSite != null) {
        rawSiteName = (matchedSite['name'] ?? rawSiteName).toString();
      } else if (rawSiteName.contains(',')) {
        // If an invitation had "Child, Parent" or "Parent, Child", display just the child site name
        final parts = rawSiteName.split(',').map((e) => e.trim()).toList();
        final childMatch = rxPraRegSites.firstWhereOrNull(
          (s) =>
              (s['is_child'] == true || s['is_child'] == 1) &&
              parts.any((p) =>
                  p.toLowerCase() ==
                  (s['name'] ?? '').toString().trim().toLowerCase()),
        );
        if (childMatch != null) {
          rawSiteName = (childMatch['name'] ?? parts.first).toString();
        } else {
          rawSiteName = parts.first;
        }
      }
    }
    final siteName = rawSiteName;
    final extendMinutes =
        int.tryParse(
          (item['extend_visitor_period'] ?? item['extend_period'] ?? 0)
              .toString(),
        ) ??
        0;
    final rawPeriodStart = item['visitor_period_start'] ?? item['period_start'];
    final rawPeriodEnd = item['visitor_period_end'] ?? item['period_end'];

    final periodStart = formatApiDate(rawPeriodStart);

    DateTime? endDt = parseApiDateTime(rawPeriodEnd);
    if (endDt != null && extendMinutes > 0) {
      endDt = endDt.add(Duration(minutes: extendMinutes));
    }
    final periodEnd = endDt != null
        ? formatLocalDateTime(endDt)
        : formatApiDate(rawPeriodEnd);

    final checkinAt = formatApiDate(item['checkin_at'] ?? item['check_in']);
    final isGroup = item['is_group'] == true || (groupName != '-');

    final photo =
        (item['selfie_image'] ??
                item['face_image'] ??
                item['visitor_face'] ??
                item['faceimage'] ??
                item['visitor']?['faceimage'] ??
                item['visitor']?['face_image'] ??
                item['avatar'] ??
                item['photo'] ??
                '')
            .toString()
            .trim();

    String identityImage =
        (item['identity_image'] ??
                item['indentity_image'] ??
                item['identity_file'] ??
                item['ktp_image'] ??
                item['ktp_file'] ??
                item['id_card_image'] ??
                item['identity_url'] ??
                item['visitor']?['indentity_image'] ??
                item['visitor']?['identity_image'] ??
                item['visitor']?['ktp_image'] ??
                item['visitor']?['id_card_image'] ??
                item['document_image'] ??
                item['file_identity'] ??
                item['identity_doc'] ??
                '')
            .toString()
            .trim();

    if (identityImage.isEmpty || identityImage == '-' || identityImage == 'null') {
      final docList = (item['documents'] as List?) ??
          (item['visitor_documents'] as List?) ??
          (item['visitor']?['documents'] as List?) ??
          (item['visitor']?['visitor_documents'] as List?);
      if (docList != null && docList.isNotEmpty) {
        for (final doc in docList) {
          if (doc is Map) {
            final f = doc['file'] ??
                doc['path'] ??
                doc['url'] ??
                doc['file_url'] ??
                doc['document_url'];
            if (f != null && f.toString().isNotEmpty && f.toString() != 'null') {
              identityImage = f.toString().trim();
              break;
            }
          }
        }
      }
    }

    final hostName = sanitize(primaryHost['name'] ?? item['host_name']);
    final hostOrg = sanitize(
      item['host_organization_name'] ?? primaryHost['organization'],
      fallback: 'Organization SPU',
    );
    final hostPhone = sanitize(primaryHost['phone'] ?? item['host_phone']);
    final hostEmail = sanitize(primaryHost['email'] ?? item['host_email']);
    final hostFaceImage = sanitize(
      primaryHost['faceimage'] ??
          primaryHost['photo'] ??
          primaryHost['avatar'] ??
          item['host_faceimage'] ??
          item['host_photo'],
      fallback: '',
    );

    final rawVisitorId =
        (item['visitor_id'] ??
                item['visitor']?['id'] ??
                item['visitor']?['visitor_id'] ??
                '')
            .toString()
            .trim();
    final isBlacklistedInSet =
        rawVisitorId.isNotEmpty &&
        rxBlacklistedVisitorIds.contains(rawVisitorId);
    final isBlocked =
        isBlacklistedInSet ||
        item['is_block'] == true ||
        visitorStatus.toLowerCase() == 'blacklist' ||
        visitorStatus.toLowerCase() == 'block' ||
        item['last_activity'] == 'Block' ||
        item['last_activity'] == 'Blacklist';

    if (isBlocked && rawVisitorId.isNotEmpty) {
      rxBlacklistedVisitorIds.add(rawVisitorId);
    }

    final effectiveStatus = isBlocked ? 'Blacklist' : visitorStatus;

    return {
      'id':
          item['id'] ??
          item['transaction_visitor_id'] ??
          item['visitor_id'] ??
          'v_${DateTime.now().millisecondsSinceEpoch}',
      'trx_id': item['id'] ?? item['transaction_visitor_id'] ?? '',
      'visitor_id': rawVisitorId,
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
      'status': effectiveStatus,
      'visitor_status': effectiveStatus,
      'occupancy': visitorRole,
      'visitor_role': visitorRole,
      'visitor_type_name': visitorTypeName,
      'vip': item['vip'] == true,
      'frequent': false,
      'is_block': isBlocked,
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
      'identity_image': identityImage,
      'ktp_image': identityImage,
      'id_card_image': identityImage,
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
      'extend_visitor_period': extendMinutes,
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
      'access': parsedAccess,
      'hosts': hostsList,
      'raw': item,
    };
  }

  void syncHostForVisitor(Map<String, dynamic>? visitor) {
    if (visitor == null) return;

    final hostName =
        (visitor['host_name'] ??
                visitor['host'] ??
                visitor['pic_host'] ??
                visitor['invited_by_name'] ??
                '')
            .toString()
            .trim();

    String hostOrg =
        (visitor['host_organization_name'] ??
                visitor['host_organization'] ??
                visitor['host_dept'] ??
                '')
            .toString()
            .trim();

    String hostPhone = (visitor['host_phone'] ?? '').toString().trim();
    String hostEmail = (visitor['host_email'] ?? '').toString().trim();
    String hostFaceImage =
        (visitor['host_faceimage'] ?? visitor['host_photo'] ?? '')
            .toString()
            .trim();

    // 1. Check if visitor item has hosts array
    final rawHosts = (visitor['hosts'] as List?) ?? [];
    if (rawHosts.isNotEmpty) {
      final h = Map<String, dynamic>.from(rawHosts.first as Map);
      if (hostPhone.isEmpty || hostPhone == '-') {
        hostPhone = (h['phone'] ?? h['host_phone'] ?? '').toString().trim();
      }
      if (hostEmail.isEmpty || hostEmail == '-') {
        hostEmail = (h['email'] ?? h['host_email'] ?? '').toString().trim();
      }
      if (hostFaceImage.isEmpty || hostFaceImage == '-') {
        hostFaceImage = (h['faceimage'] ?? h['avatar'] ?? h['photo'] ?? '')
            .toString()
            .trim();
      }
    }

    // 2. Search across rxPraRegHosts, rxPraRegEmployees, and visitors for someone matching host ID or hostName
    final hostId = (visitor['host'] ?? visitor['raw']?['host'] ?? '')
        .toString()
        .trim();

    Map<String, dynamic>? matchingHost;
    if (hostId.isNotEmpty &&
        hostId != '-' &&
        hostId != '00000000-0000-0000-0000-000000000000') {
      matchingHost =
          rxPraRegHosts.firstWhereOrNull(
            (h) =>
                (h['id'] ?? '').toString().trim().toLowerCase() ==
                hostId.toLowerCase(),
          ) ??
          rxPraRegEmployees.firstWhereOrNull(
            (e) =>
                (e['id'] ?? '').toString().trim().toLowerCase() ==
                hostId.toLowerCase(),
          );
    }

    if (matchingHost == null && hostName.isNotEmpty && hostName != '-') {
      matchingHost =
          rxPraRegHosts.firstWhereOrNull(
            (h) =>
                (h['name'] ?? '').toString().trim().toLowerCase() ==
                hostName.toLowerCase(),
          ) ??
          rxPraRegEmployees.firstWhereOrNull(
            (e) =>
                (e['name'] ?? '').toString().trim().toLowerCase() ==
                hostName.toLowerCase(),
          ) ??
          rxAllRelatedVisitors.firstWhereOrNull(
            (v) =>
                (v['name'] ?? v['visitor_name'] ?? '')
                    .toString()
                    .trim()
                    .toLowerCase() ==
                hostName.toLowerCase(),
          ) ??
          rxAllLiveVisitors.firstWhereOrNull(
            (v) =>
                (v['name'] ?? v['visitor_name'] ?? '')
                    .toString()
                    .trim()
                    .toLowerCase() ==
                hostName.toLowerCase(),
          );
    }

    if (matchingHost != null) {
      if (hostPhone.isEmpty || hostPhone == '-') {
        hostPhone =
            (matchingHost['phone'] ?? matchingHost['visitor_phone'] ?? '')
                .toString()
                .trim();
      }
      if (hostEmail.isEmpty || hostEmail == '-') {
        hostEmail =
            (matchingHost['email'] ?? matchingHost['visitor_email'] ?? '')
                .toString()
                .trim();
      }
      if (hostFaceImage.isEmpty || hostFaceImage == '-') {
        hostFaceImage =
            (matchingHost['faceimage'] ??
                    matchingHost['photo'] ??
                    matchingHost['avatar'] ??
                    matchingHost['selfie_image'] ??
                    '')
                .toString()
                .trim();
      }
      if (hostOrg.isEmpty || hostOrg == '-') {
        final rawOrg =
            matchingHost['Organization'] ?? matchingHost['organization'];
        if (rawOrg is Map) {
          hostOrg = (rawOrg['name'] ?? rawOrg['code'] ?? '').toString().trim();
        } else if (rawOrg is String && rawOrg.isNotEmpty) {
          hostOrg = rawOrg.trim();
        }
      }
    }

    // 3. Fallback from existing rxPrimaryHost if it had valid phone/email/avatar
    final prev = rxPrimaryHost.value;
    if (prev != null) {
      final prevName = (prev['name'] ?? '').toString().trim();
      if (prevName.isEmpty ||
          prevName.toLowerCase() == hostName.toLowerCase() ||
          hostName.isEmpty ||
          hostName == '-') {
        if ((hostPhone.isEmpty || hostPhone == '-') &&
            prev['phone'] != null &&
            prev['phone'] != '-') {
          hostPhone = prev['phone'].toString().trim();
        }
        if ((hostEmail.isEmpty || hostEmail == '-') &&
            prev['email'] != null &&
            prev['email'] != '-') {
          hostEmail = prev['email'].toString().trim();
        }
        if ((hostFaceImage.isEmpty || hostFaceImage == '-') &&
            prev['faceimage'] != null &&
            prev['faceimage'] != '') {
          hostFaceImage = prev['faceimage'].toString().trim();
        }
      }
    }

    final finalName = hostName.isNotEmpty && hostName != '-'
        ? hostName
        : (prev?['name'] ?? 'Host');
    final finalOrg = hostOrg.isNotEmpty && hostOrg != '-'
        ? hostOrg
        : (prev?['organization'] ?? 'Organization SPU');

    rxPrimaryHost.value = {
      'name': finalName,
      'organization': finalOrg,
      'phone': hostPhone.isNotEmpty ? hostPhone : '-',
      'email': hostEmail.isNotEmpty ? hostEmail : '-',
      'faceimage': hostFaceImage,
      'status': 'Available',
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

        final currentSelected = rxSelectedVisitor.value;
        if (currentSelected != null) {
          final curIdentity = currentSelected['identity_image'] ?? currentSelected['ktp_image'];
          if (curIdentity != null &&
              curIdentity.toString().isNotEmpty &&
              curIdentity.toString() != '-' &&
              (uiVisitor['identity_image'] == null ||
                  uiVisitor['identity_image'].toString().isEmpty ||
                  uiVisitor['identity_image'].toString() == '-')) {
            uiVisitor['identity_image'] = curIdentity;
            uiVisitor['ktp_image'] = curIdentity;
            uiVisitor['id_card_image'] = curIdentity;
          }
        }

        rxSelectedVisitor.value = uiVisitor;

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
              final vId = mapped['id'].toString();
              final existing = rxAllRelatedVisitors.firstWhereOrNull(
                (e) => e['id'].toString() == vId,
              ) ?? (rxSelectedVisitor.value?['id'].toString() == vId ? rxSelectedVisitor.value : null);

              if (existing != null) {
                final exIdentity = existing['identity_image'] ?? existing['ktp_image'];
                if (exIdentity != null &&
                    exIdentity.toString().isNotEmpty &&
                    exIdentity.toString() != '-' &&
                    (mapped['identity_image'] == null ||
                        mapped['identity_image'].toString().isEmpty ||
                        mapped['identity_image'].toString() == '-')) {
                  mapped['identity_image'] = exIdentity;
                  mapped['ktp_image'] = exIdentity;
                  mapped['id_card_image'] = exIdentity;
                }
              }
              newRelated.add(mapped);
            }
          }
        }

        // Fallback: If related visitors endpoint returned empty, ensure at least uiVisitor is present
        if (newRelated.isEmpty) {
          newRelated.add(uiVisitor);
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
        rxFeedTabIndex.value =
            1; // Direct automatically to Related Visitors tab
        applyFiltersAndPagination();
        syncHostForVisitor(matchedSelected);

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
