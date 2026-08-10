import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/mqtt_service.dart';
import '../../../core/shared/widgets/app_snackbar.dart';

class CardTapView extends StatefulWidget {
  const CardTapView({super.key});

  @override
  State<CardTapView> createState() => _CardTapViewState();
}

class _CardTapViewState extends State<CardTapView> {
  // Timer for live real-time header clock
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  // MQTT Service Instance
  final MqttService _mqttService = MqttService();

  // Pagination Controller
  late PageController _pageController;
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

  // Search & Filter Controllers
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All Status';
  DateTime? _selectedDate;
  bool _autoRefresh = true;
  bool _isGridView = true;

  // Dynamic Metric Counters
  int _totalToday = 128;
  int _passedToday = 98;
  int _rejectedToday = 18;
  int _blacklistedToday = 12;
  int _totalMonth = 1248;

  // Design Tokens (from AGENTS.md)
  static const Color _blue = Color(0xFF1976D2);
  static const Color _blueDark = Color(0xFF0E5DB5);
  static const Color _bgSlate = Color(0xFFF8FAFC);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _greenPassed = Color(0xFF10B981);
  static const Color _orangeBlacklist = Color(0xFFF59E0B);
  static const Color _redRejected = Color(0xFFEF4444);

  // Live Visitors Data Feed
  final List<Map<String, dynamic>> _allVisitors = [
    {
      'id': 'V001',
      'name': 'Endru Wijaya',
      'status': 'Passed',
      'scan': 'No',
      'tapIn': '08:40:11',
      'tapOut': '16:40:11',
      'image':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=400&h=400',
    },
    {
      'id': 'V002',
      'name': 'Budi Santoso',
      'status': 'Blacklisted',
      'scan': 'No',
      'tapIn': '08:42:30',
      'tapOut': '16:40:11',
      'image':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?fit=crop&w=400&h=400',
    },
    {
      'id': 'V003',
      'name': 'Reza Pratama',
      'status': 'Rejected',
      'scan': 'No',
      'tapIn': '08:45:15',
      'tapOut': '16:40:11',
      'image':
          'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?fit=crop&w=400&h=400',
    },
    {
      'id': 'V004',
      'name': 'Dimas Anggara',
      'status': 'Passed',
      'scan': 'No',
      'tapIn': '08:48:50',
      'tapOut': '16:40:11',
      'image':
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?fit=crop&w=400&h=400',
    },
    {
      'id': 'V005',
      'name': 'Hendrik Gunawan',
      'status': 'Blacklisted',
      'scan': 'No',
      'tapIn': '08:50:05',
      'tapOut': '16:40:11',
      'image':
          'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?fit=crop&w=400&h=400',
    },
    {
      'id': 'V006',
      'name': 'Arif Setiawan',
      'status': 'Rejected',
      'scan': 'No',
      'tapIn': '08:52:44',
      'tapOut': '16:40:11',
      'image':
          'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?fit=crop&w=400&h=400',
    },
    {
      'id': 'V007',
      'name': 'Fajar Hidayat',
      'status': 'Passed',
      'scan': 'No',
      'tapIn': '08:55:18',
      'tapOut': '16:40:11',
      'image':
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?fit=crop&w=400&h=400',
    },
    {
      'id': 'V008',
      'name': 'Bayu Nugroho',
      'status': 'Blacklisted',
      'scan': 'No',
      'tapIn': '08:58:22',
      'tapOut': '16:40:11',
      'image':
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?fit=crop&w=400&h=400',
    },
    {
      'id': 'V009',
      'name': 'Rian Saputra',
      'status': 'Rejected',
      'scan': 'No',
      'tapIn': '09:02:11',
      'tapOut': '16:40:11',
      'image':
          'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?fit=crop&w=400&h=400',
    },
    {
      'id': 'V010',
      'name': 'Agus Firmansyah',
      'status': 'Passed',
      'scan': 'No',
      'tapIn': '09:05:40',
      'tapOut': '16:40:11',
      'image':
          'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?fit=crop&w=400&h=400',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // 1. Live clock ticker
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    // 2. Initialize Real-Time MQTT Stream
    _initMqttStream();
  }

  void _initMqttStream() {
    _mqttService.onVisitorArrived = (raw) {
      if (!mounted) return;
      _handleIncomingMqttPayload(raw);
    };

    // Connect to Broker: 103.193.15.67:1883 & Subscribe Topic: notification/dashboard/viewer/arrived
    _mqttService.initializeAndConnect();
  }

  void _handleIncomingMqttPayload(Map<String, dynamic> raw) {
    debugPrint('MQTT RECEIVED ON TOPIC: $raw');

    List<dynamic> visitorList = [];

    if (raw['payload'] != null && raw['payload'] is Map) {
      final payloadMap = raw['payload'] as Map<String, dynamic>;
      if (payloadMap['data'] is List) {
        visitorList = payloadMap['data'] as List;
      } else if (payloadMap['data'] is Map) {
        visitorList = [payloadMap['data']];
      }
    } else if (raw['data'] is List) {
      visitorList = raw['data'] as List;
    } else if (raw['data'] is Map) {
      visitorList = [raw['data']];
    } else {
      visitorList = [raw];
    }

    final options = (raw['payload'] is Map ? raw['payload']['Option'] : null) ??
        raw['Option'] ??
        {};
    final String arrivalMethod =
        (options['arrival_tap_in'] ?? 'CardTap').toString();

    for (final dynamic item in visitorList) {
      if (item is! Map<String, dynamic>) continue;

      final String name =
          (item['visitor_name'] ?? item['name'] ?? 'Visitor').toString();

      // Determine status: Passed / Blacklisted / Rejected
      String status = 'Passed';
      if (item['is_blacklisted'] == true) {
        status = 'Blacklisted';
      } else if (item['is_rejected'] == true || item['is_blocked'] == true) {
        status = 'Rejected';
      } else if (item['approval_status'] == 'Approved' ||
          item['visitor_status'] == 'Checkin' ||
          item['is_checked_in'] == true ||
          item['is_arrived'] == true) {
        status = 'Passed';
      }

      // Determine Scan status
      final bool currentTap = item['current_tap_in'] == true;
      final String scan = currentTap ? 'Yes' : 'No';

      // Parse Arrival Time cleanly
      String tapInTime = '';
      final String? arrivalAtStr =
          (item['arrival_at'] ?? raw['created_at'])?.toString();
      if (arrivalAtStr != null &&
          arrivalAtStr.isNotEmpty &&
          arrivalAtStr != 'null') {
        try {
          final parsed = DateTime.parse(arrivalAtStr);
          final local = parsed.isUtc ? parsed.toLocal() : parsed;
          final h = local.hour.toString().padLeft(2, '0');
          final m = local.minute.toString().padLeft(2, '0');
          final s = local.second.toString().padLeft(2, '0');
          tapInTime = '$h:$m:$s';
        } catch (_) {
          tapInTime = arrivalAtStr;
        }
      }
      if (tapInTime.isEmpty) {
        final now = DateTime.now();
        final h = now.hour.toString().padLeft(2, '0');
        final m = now.minute.toString().padLeft(2, '0');
        final s = now.second.toString().padLeft(2, '0');
        tapInTime = '$h:$m:$s';
      }

      // Determine Image
      String image = (item['selfie_image'] ??
              item['image'] ??
              item['photo'] ??
              item['avatar'] ??
              '')
          .toString();
      if (image.isEmpty || image == 'null') {
        final avatarList = [
          'assets/images/ava_person1.png',
          'assets/images/ava_person2.png',
          'assets/images/ava_person3.png',
          'assets/images/ava_person4.png',
        ];
        image = avatarList[_allVisitors.length % avatarList.length];
      }

      final newVisitorCard = {
        'id': 'V00${_allVisitors.length + 1}',
        'name': name,
        'status': status,
        'scan': scan,
        'tapIn': tapInTime,
        'tapOut': '16:40:11',
        'image': image,
        'method': arrivalMethod,
        'org': (item['visitor_organization_name'] ?? 'Instansi').toString(),
      };

      setState(() {
        _allVisitors.insert(0, newVisitorCard);

        _totalToday++;
        _totalMonth++;
        if (status == 'Passed') {
          _passedToday++;
        } else if (status == 'Blacklisted') {
          _blacklistedToday++;
        } else {
          _rejectedToday++;
        }
      });

      // Jump/Animate to first page on new arrival
      if (_currentPage != 0 && _pageController.hasClients) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      if (status == 'Passed') {
        AppSnackbar.success(
          title: 'Success',
          message: '$name ($arrivalMethod) tapped in at $tapInTime',
        );
      } else if (status == 'Blacklisted') {
        AppSnackbar.warning(
          title: 'Blacklisted',
          message: '$name ($arrivalMethod) flagged at $tapInTime',
        );
      } else {
        AppSnackbar.error(
          title: 'Rejected',
          message: '$name ($arrivalMethod) rejected at $tapInTime',
        );
      }
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _pageController.dispose();
    _searchController.dispose();
    _mqttService.disconnect();
    super.dispose();
  }

  String _formatLiveClock(DateTime time) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
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
      'December'
    ];

    final dayName = days[time.weekday - 1];
    final monthName = months[time.month - 1];
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');

    return '$dayName, ${time.day} $monthName ${time.year} at $h:$m:$s';
  }

  List<Map<String, dynamic>> get _filteredVisitors {
    final q = _searchController.text.trim().toLowerCase();
    return _allVisitors.where((v) {
      final name = (v['name'] as String).toLowerCase();
      final id = (v['id'] as String).toLowerCase();
      final status = v['status'] as String;

      final matchQuery = q.isEmpty || name.contains(q) || id.contains(q);
      final matchStatus =
          _selectedStatus == 'All Status' || status == _selectedStatus;

      return matchQuery && matchStatus;
    }).toList();
  }

  int get _totalPages {
    final count = _filteredVisitors.length;
    if (count == 0) return 1;
    return ((count - 1) / _itemsPerPage).floor() + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSlate,
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Top Header Bar (Ultra Compact) ─────────────────────────
            _buildTopHeaderBar(),

            const SizedBox(height: 6),

            // ── 2. Top Summary Metric Cards Row (Compact 58px) ────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSummaryMetricsRow(),
            ),

            const SizedBox(height: 6),

            // ── 3. Search, Filter & Action Toolbar + Page Controls ────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildActionToolbar(),
            ),

            const SizedBox(height: 6),

            // ── 4. Main Visitor 10-Item Paginated Slide Grid (100% Zero Scroll)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _isGridView
                    ? _buildPaginatedVisitorGrid()
                    : _buildVisitorListView(),
              ),
            ),

            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Header: Back Button + Live Clock + MQTT Status + Bank Indonesia Logo
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTopHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          // 1. Back Button (Left Side)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 15,
                  color: _textDark,
                ),
              ),
            ),
          ),

          const Spacer(),

          // 2. Clock Icon + Live Real-Time Date & Clock
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 15,
                color: _textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                _formatLiveClock(_currentTime),
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // 4. Bank Indonesia Logo (Right Side)
          Image.asset(
            'assets/images/VMS.png',
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'assets/images/logo.png',
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF003082),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'BI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5 Top Summary Metric Cards Row (Compact 58px)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSummaryMetricsRow() {
    return Row(
      children: [
        _buildMetricCard(
          title: 'Total Visitor Today',
          value: '$_totalToday',
          icon: Icons.person_rounded,
        ),
        const SizedBox(width: 8),
        _buildMetricCard(
          title: 'Passed Today',
          value: '$_passedToday',
          icon: Icons.check_circle_outline_rounded,
        ),
        const SizedBox(width: 8),
        _buildMetricCard(
          title: 'Rejected Today',
          value: '$_rejectedToday',
          icon: Icons.block_flipped,
        ),
        const SizedBox(width: 8),
        _buildMetricCard(
          title: 'Blacklisted Today',
          value: '$_blacklistedToday',
          icon: Icons.warning_amber_rounded,
        ),
        const SizedBox(width: 8),
        _buildMetricCard(
          title: 'Total This Month',
          value: '$_totalMonth',
          icon: Icons.show_chart_rounded,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _blue.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _blue.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular Blue Icon Badge
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: _blue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 17,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _textMuted,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Search, Filter Dropdown, Date Picker, Scan, Clear, Pagination & View Mode
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildActionToolbar() {
    final totalPages = _totalPages;

    return Row(
      children: [
        // 1. Search Bar (Perfect Vertical Alignment)
        Expanded(
          flex: 3,
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: _textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) {
                      setState(() {
                        _currentPage = 0;
                      });
                      if (_pageController.hasClients) {
                        _pageController.jumpToPage(0);
                      }
                    },
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textDark,
                      height: 1.2,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search Visitor...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: _textMuted,
                        height: 1.2,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 6),

        // 2. Status Dropdown
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: _textMuted,
              ),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
              items: ['All Status', 'Passed', 'Rejected', 'Blacklisted']
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedStatus = val;
                    _currentPage = 0;
                  });
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(0);
                  }
                }
              },
            ),
          ),
        ),

        const SizedBox(width: 6),

        // 3. Date Picker Box
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Text(
                  _selectedDate == null
                      ? 'mm/dd/yyyy'
                      : '${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: _selectedDate == null ? _textMuted : _textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: _textMuted,
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // 4. Scan Button (Dark Blue Gradient)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openQuickScanDialog(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_blue, _blueDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _blue.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.document_scanner_outlined,
                    color: Colors.white,
                    size: 15,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Scan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 6),

        // 5. Clear Button (Red outline & text)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _searchController.clear();
                _selectedStatus = 'All Status';
                _selectedDate = null;
                _currentPage = 0;
              });
              if (_pageController.hasClients) {
                _pageController.jumpToPage(0);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.close_rounded,
                    color: Color(0xFFEF4444),
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Clear',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // 6. Pagination Navigation Buttons (< Page X of Y >)
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Previous Page Button
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                icon: Icon(
                  Icons.chevron_left_rounded,
                  size: 20,
                  color: _currentPage > 0 ? _blue : Colors.grey.shade300,
                ),
                onPressed: _currentPage > 0
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                tooltip: 'Previous Page',
              ),

              // Page Counter Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '${_currentPage + 1} / $totalPages',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ),

              // Next Page Button
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                icon: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: _currentPage < totalPages - 1
                      ? _blue
                      : Colors.grey.shade300,
                ),
                onPressed: _currentPage < totalPages - 1
                    ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                tooltip: 'Next Page',
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // 7. Auto Refresh Switch
        Row(
          children: [
            const Icon(
              Icons.refresh_rounded,
              size: 15,
              color: _textMuted,
            ),
            const SizedBox(width: 3),
            const Text(
              'Auto',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            Transform.scale(
              scale: 0.65,
              child: Switch(
                value: _autoRefresh,
                activeTrackColor: _blue,
                onChanged: (val) {
                  setState(() {
                    _autoRefresh = val;
                  });
                },
              ),
            ),
          ],
        ),

        // 8. Grid / List View Toggle Icons
        Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: Icon(
                Icons.grid_view_rounded,
                size: 18,
                color: _isGridView ? _blue : Colors.grey.shade400,
              ),
              onPressed: () => setState(() => _isGridView = true),
              tooltip: 'Grid View',
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: Icon(
                Icons.view_list_rounded,
                size: 20,
                color: !_isGridView ? _blue : Colors.grey.shade400,
              ),
              onPressed: () => setState(() => _isGridView = false),
              tooltip: 'List View',
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Paginated 10-Item Slide Grid (Zero Scroll, PageView with Horizontal Slide)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPaginatedVisitorGrid() {
    final visitors = _filteredVisitors;
    final totalPages = _totalPages;

    if (visitors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            const Text(
              'No visitor records match the current filter',
              style: TextStyle(fontSize: 12, color: _textMuted),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // Exactly 5 columns x 2 rows = 10 items
        // Spacing: 10px between columns (4 gaps) and 8px between rows (1 gap)
        const double hSpacing = 10.0;
        const double vSpacing = 8.0;

        final double itemWidth = (availableWidth - (4 * hSpacing)) / 5;
        final double itemHeight = (availableHeight - (1 * vSpacing)) / 2;

        // Exact dynamic aspect ratio guaranteeing ZERO overflow on Samsung Tab / any tablet!
        final double dynamicAspectRatio = itemWidth / itemHeight;

        return PageView.builder(
          controller: _pageController,
          itemCount: totalPages,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (page) {
            setState(() {
              _currentPage = page;
            });
          },
          itemBuilder: (context, pageIndex) {
            final startIndex = pageIndex * _itemsPerPage;
            final endIndex =
                (startIndex + _itemsPerPage).clamp(0, visitors.length);
            final pageVisitors = visitors.sublist(startIndex, endIndex);

            return GridView.builder(
              physics:
                  const NeverScrollableScrollPhysics(), // 100% No vertical scroll!
              itemCount: pageVisitors.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: dynamicAspectRatio,
                crossAxisSpacing: hSpacing,
                mainAxisSpacing: vSpacing,
              ),
              itemBuilder: (context, index) {
                final visitor = pageVisitors[index];
                return _buildVisitorCard(visitor);
              },
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Visitor Card with Responsive Heights & Prominent Name & Clean Time
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildVisitorCard(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'Passed').toString();
    final name = (item['name'] ?? 'Visitor').toString();

    Color statusBgColor;
    if (status == 'Passed') {
      statusBgColor = _greenPassed;
    } else if (status == 'Blacklisted') {
      statusBgColor = _orangeBlacklist;
    } else {
      statusBgColor = _redRejected;
    }

    final imageSrc = (item['image'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Upper Photo Section with Face Target Box & Status Overlay ───
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Visitor Photo
                  _buildVisitorImage(imageSrc),

                  // Face Detection Green Targeting Reticle Overlay
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF10B981),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Stack(
                          children: [
                            // 4 Corner Brackets
                            _buildCornerBracket(Alignment.topLeft),
                            _buildCornerBracket(Alignment.topRight),
                            _buildCornerBracket(Alignment.bottomLeft),
                            _buildCornerBracket(Alignment.bottomRight),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Status Badge (Passed / Blacklisted / Rejected)
                  Positioned(
                    bottom: 4,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: statusBgColor.withValues(alpha: 0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        status,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Lower Metadata Details Table (Ultra Compact & Never Cut Off) ─
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prominent Visitor Name Header
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 11,
                      color: _blue,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                _buildMetadataRow('Scan', item['scan'] ?? 'No'),
                _buildMetadataRow('Tap In', item['tapIn'] ?? '-'),
                _buildMetadataRow('Tap Out', item['tapOut'] ?? '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorImage(String imageSrc) {
    if (imageSrc.startsWith('assets/')) {
      return Image.asset(
        imageSrc,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackAvatar(),
      );
    } else if (imageSrc.startsWith('http://') ||
        imageSrc.startsWith('https://')) {
      return Image.network(
        imageSrc,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackAvatar(),
      );
    } else {
      // Relative path or local file
      return Image.asset(
        'assets/images/ava_person1.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackAvatar(),
      );
    }
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          size: 44,
          color: _textMuted,
        ),
      ),
    );
  }

  Widget _buildCornerBracket(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.5),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: _textMuted,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: _textMuted,
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: _textDark,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Alternative List View Mode
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildVisitorListView() {
    final visitors = _filteredVisitors;
    return ListView.separated(
      itemCount: visitors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = visitors[index];
        final status = (item['status'] ?? 'Passed').toString();

        Color statusBgColor = _greenPassed;
        if (status == 'Blacklisted') statusBgColor = _orangeBlacklist;
        if (status == 'Rejected') statusBgColor = _redRejected;

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: _buildVisitorImage((item['image'] ?? '').toString()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? 'Visitor',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    Text(
                      'ID: ${item['id']}  |  Org: ${item['org'] ?? "Instansi"}',
                      style: const TextStyle(fontSize: 10.5, color: _textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                'Tap In: ${item['tapIn']}  |  Tap Out: ${item['tapOut']}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                  color: _textDark,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Quick Scan Action Dialog
  // ─────────────────────────────────────────────────────────────────────────
  void _openQuickScanDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.document_scanner_outlined,
                  size: 40,
                  color: _blue,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Live QR & Card Scanner',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Point camera at visitor QR code or place card near RFID reader.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: _textMuted),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text('Close Scanner'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
