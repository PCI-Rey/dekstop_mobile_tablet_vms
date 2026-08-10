import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../controller/dashboard_controller.dart';
import '../widgets/operator_tour_overlay.dart';
import 'desktop_overview_analytics.dart';
import '../../../core/shared/routes/app_pages.dart';
import '../../../core/shared/widgets/app_snackbar.dart';

class DesktopDashboard extends StatefulWidget {
  const DesktopDashboard({super.key});

  @override
  State<DesktopDashboard> createState() => _DesktopDashboardState();
}

class _DesktopDashboardState extends State<DesktopDashboard> {
  final DashboardController controller = Get.find<DashboardController>();

  // Live real-time header clock
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  // Fullscreen state
  bool _isFullScreen = false;

  // Active Top Navigation Tab (0: Dashboard Overview Analytics, 1: Operator View)
  int _selectedTopNavTab = 1;

  // Guided Tour Walkthrough state (10 Steps)
  bool _isTourActive = false;
  int _tourStep = 0;

  // Visitor Site Dropdown Overlay
  OverlayEntry? _visitorSiteOverlay;
  final LayerLink _visitorSiteLayerLink = LayerLink();
  bool _isVisitorSiteMenuOpen = false;
  String _selectedVisitorSiteMenu = 'List Visitor';

  // Site Dropdown Overlay (SPU, Gedung SINERGI, Resident)
  OverlayEntry? _siteOverlay;
  final LayerLink _siteLayerLink = LayerLink();
  bool _isSiteMenuOpen = false;

  // Bulk Action Dropdown Overlay (Fill Form, Checkin, Checkout, Print Badge)
  OverlayEntry? _bulkActionOverlay;
  final LayerLink _bulkActionLayerLink = LayerLink();
  bool _isBulkActionMenuOpen = false;

  // GlobalKeys for Interactive 10-Step Operator Guided Tour
  final GlobalKey _keySearchClear = GlobalKey();
  final GlobalKey _keyVisitorProfile = GlobalKey();
  final GlobalKey _keyVisitorTabs = GlobalKey();
  final GlobalKey _keyActionGrid = GlobalKey();
  final GlobalKey _keyVisitorsFeed = GlobalKey();
  final GlobalKey _keySelectMultiple = GlobalKey();
  final GlobalKey _keyHostInfo = GlobalKey();
  final GlobalKey _keyLiveOccupancy = GlobalKey();
  final GlobalKey _keyIdentityImage = GlobalKey();
  final GlobalKey _keyAlerts = GlobalKey();

  // Selected Tabs
  int _selectedVisitorInfoTab = 0; // 0: Visit Information, 1: Purpose Visit, 2: Card, 3: History
  int _selectedVisitorListTab = 0; // 0: Live Visitors, 1: Related Visitors

  // Filter controllers
  final TextEditingController _visitorSearchController = TextEditingController();
  final TextEditingController _topSearchController = TextEditingController();
  String _selectedSite = 'SPU';
  String _selectedBulkAction = 'Fill Form';
  String _occupancyFilter = 'Today';

  // Design Tokens (from AGENTS.md)
  static const Color _bgSlate = Color(0xFFF4F7FB);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _greenSuccess = Color(0xFF10B981);
  static const Color _redDanger = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _closeBulkActionMenu();
    _closeSiteMenu();
    _closeVisitorSiteMenu();
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _clockTimer.cancel();
    _visitorSearchController.dispose();
    _topSearchController.dispose();
    super.dispose();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      AppSnackbar.info(
        title: 'Fullscreen Mode',
        message: 'Fullscreen active',
      );
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      AppSnackbar.info(
        title: 'Normal Mode',
        message: 'Normal view active',
      );
    }
  }

  List<TourStep> _buildTourSteps() {
    return [
      // Step 1 of 10: Top Search & Clear
      TourStep(
        targetKey: _keySearchClear,
        description:
            'Use Search to find visitors by invitation code or keywords. Click Clear to reset the results to their initial state.',
        arrowOnTop: true,
        bubbleWidth: 320,
      ),
      // Step 2 of 10: Visitor Profile Card
      TourStep(
        targetKey: _keyVisitorProfile,
        description:
            "Displays the visitor's main information, such as name, company, visit details, and more.",
        arrowOnTop: true,
        bubbleWidth: 320,
      ),
      // Step 3 of 10: Visitor Detail Tabs & QR Code
      TourStep(
        targetKey: _keyVisitorTabs,
        description:
            'Displays detailed visitor information, including additional data and visit-related history.',
        arrowOnTop: false,
        bubbleWidth: 320,
      ),
      // Step 4 of 10: Action Buttons Grid
      TourStep(
        targetKey: _keyActionGrid,
        description: 'All available operator actions can be accessed here.',
        arrowOnTop: true,
        bubbleWidth: 320,
      ),
      // Step 5 of 10: Visitors Management Feed
      TourStep(
        targetKey: _keyVisitorsFeed,
        description:
            'Displays the list of Related Visitors associated with the entered Invitation Code. Unlike Live Visitor, which displays all visitors who are expected to arrive or are currently on-site.',
        arrowOnTop: false,
        bubbleWidth: 330,
      ),
      // Step 6 of 10: Select Multiple & Pagination Controls
      TourStep(
        targetKey: _keySelectMultiple,
        description:
            'Enable Multiple Selection mode to select more than one visitor.',
        arrowOnTop: true,
        bubbleWidth: 320,
      ),
      // Step 7 of 10: Host Information Card
      TourStep(
        targetKey: _keyHostInfo,
        description:
            'Displays information about the host or PIC receiving the visitor.',
        arrowOnTop: true,
        bubbleWidth: 320,
      ),
      // Step 8 of 10: Live Occupancy Card
      TourStep(
        targetKey: _keyLiveOccupancy,
        description:
            'Displays the available visit types. Click a visit type to view its detailed information.',
        arrowOnTop: true,
        bubbleWidth: 320,
      ),
      // Step 9 of 10: Identity Image Card
      TourStep(
        targetKey: _keyIdentityImage,
        description:
            'Displays the identity photo or document uploaded by the visitor.',
        arrowOnTop: true,
        bubbleWidth: 320,
      ),
      // Step 10 of 10: Alerts Card
      TourStep(
        targetKey: _keyAlerts,
        description:
            'Displays important information or alerts that require attention regarding the visitor.',
        arrowOnTop: false,
        bubbleWidth: 320,
      ),
    ];
  }

  String _formatHeaderClock(DateTime time) {
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

    return '$dayName, $monthName ${time.day}, ${time.year} $h:$m GMT+7';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSlate,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // ── 1. Top Navigation Bar (Hidden when _isFullScreen) ─────────
                if (!_isFullScreen) _buildTopNavBar(),

                // ── 2. View Switcher (Dashboard Overview Analytics vs Operator View) ──
                if (_selectedTopNavTab == 0)
                  Expanded(
                    child: DesktopOverviewAnalytics(
                      onAddVisitor: () {
                        setState(() {
                          _selectedTopNavTab = 1;
                        });
                      },
                    ),
                  )
                else ...[
                  // ── 2. Secondary Action Toolbar (Search, Clear, Site, Fullscreen) ──
                  _buildSecondaryToolbar(),

                  const SizedBox(height: 5),

                  // ── 3. Main 3-Column Dashboard Body (Zero Scroll Fit) ─────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Left Column (~30% width) ──────────────────────────
                          Expanded(
                            flex: 30,
                            child: _buildLeftColumn(),
                          ),

                          const SizedBox(width: 8),

                          // ── Center Column (~41% width) ────────────────────────
                          Expanded(
                            flex: 41,
                            child: _buildCenterColumn(),
                          ),

                          const SizedBox(width: 8),

                          // ── Right Column (~29% width) ─────────────────────────
                          Expanded(
                            flex: 29,
                            child: _buildRightColumn(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── 4. Bottom Copyright Footer ────────────────────────────────
                  _buildFooter(),
                ],
              ],
            ),
          ),

          // ── 5. Interactive Operator Guided Tour Overlay (10 Steps) ───────────
          if (_isTourActive && _selectedTopNavTab == 1)
            OperatorTourOverlay(
              steps: _buildTourSteps(),
              initialStep: _tourStep,
              onFinish: () {
                setState(() {
                  _isTourActive = false;
                });
                AppSnackbar.success(
                  title: 'Tour Completed',
                  message: 'You have completed the Operator Guided Tour!',
                );
              },
              onSkip: () {
                setState(() {
                  _isTourActive = false;
                });
              },
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. Top Navigation Bar
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTopNavBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bank Indonesia Logo (Left side)
          Image.asset(
            'assets/images/VMS.png',
            height: 28,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/logo.png',
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.account_balance_rounded,
                size: 24,
                color: Color(0xFF003082),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Navigation Tab 1: Dashboard
          if (_selectedTopNavTab == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF003082),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.home_outlined, size: 14, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    'Dashboard',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedTopNavTab = 0;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.home_outlined,
                          size: 14, color: _textMuted),
                      const SizedBox(width: 5),
                      Text(
                        'Dashboard',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(width: 6),

          // Navigation Tab 2: Operator View
          if (_selectedTopNavTab == 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF003082),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.visibility_outlined,
                      size: 13, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    'Operator View',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedTopNavTab = 1;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility_outlined,
                          size: 14, color: _textMuted),
                      const SizedBox(width: 5),
                      Text(
                        'Operator View',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const Spacer(),

          // Date & Time Live Clock
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: _textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                _formatHeaderClock(_currentTime),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Notification Bell with Red Indicator Dot
          Stack(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  size: 19,
                  color: _textDark,
                ),
                onPressed: () {
                  AppSnackbar.info(
                    title: 'Notifications',
                    message: 'No new unread notifications.',
                  );
                },
              ),
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: _redDanger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 6),

          // Language Flag (UK Flag Icon Container)
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                '🇬🇧',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // User Profile Avatar with Green Online Status Dot
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.profile),
            child: Stack(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFF003082),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.person, size: 16, color: Colors.white),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _greenSuccess,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Secondary Action Toolbar (Search, Clear, SPU Dropdown, Visitor Site)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSecondaryToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
      color: _bgSlate,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Search Bar + Clear Button (Keyed for Tour Step 1)
          Expanded(
            child: Row(
              key: _keySearchClear,
              children: [
                Expanded(
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_rounded, size: 15, color: _textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _topSearchController,
                            textAlignVertical: TextAlignVertical.center,
                            style: GoogleFonts.inter(fontSize: 11.5, color: _textDark, height: 1.2),
                            decoration: InputDecoration(
                              hintText: 'Search Visitor',
                              hintStyle: GoogleFonts.inter(fontSize: 11.5, color: _textMuted, height: 1.2),
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
                // Clear Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _topSearchController.clear();
                      setState(() {});
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _redDanger.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.close_rounded, size: 13, color: _redDanger),
                          const SizedBox(width: 4),
                          Text(
                            'Clear',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _redDanger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 3. SPU Site Dropdown Button
          CompositedTransformTarget(
            link: _siteLayerLink,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleSiteMenu,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isSiteMenuOpen
                          ? const Color(0xFF003082)
                          : const Color(0xFFE2E8F0),
                      width: _isSiteMenuOpen ? 1.2 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _selectedSite,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _isSiteMenuOpen
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        size: 16,
                        color: _isSiteMenuOpen
                            ? const Color(0xFF003082)
                            : _textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // 4. Visitor Site Action Dropdown Button (Blue)
          CompositedTransformTarget(
            link: _visitorSiteLayerLink,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleVisitorSiteMenu,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003082),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        'Visitor Site',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isVisitorSiteMenuOpen
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // 5. Info Icon Button (Triggers Guided Tour)
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF003082),
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Operator Guided Tour',
              icon: const Icon(Icons.info_outline_rounded,
                  size: 15, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isTourActive = true;
                  _tourStep = 0;
                });
              },
            ),
          ),

          const SizedBox(width: 6),

          // 6. Fullscreen Icon Button (Toggles Fullscreen & hides/shows top navigation)
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF003082),
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: _isFullScreen ? 'Exit Fullscreen' : 'Enter Fullscreen',
              icon: Icon(
                _isFullScreen
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
                size: 19,
                color: Colors.white,
              ),
              onPressed: _toggleFullScreen,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LEFT COLUMN (~30% width)
  // 1. Visitor Profile Card (Enhanced typography & styling matching screenshot)
  // 2. Tabs: Visit Information / Purpose Visit / Card / History
  // 3. Visitor QR Code Card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLeftColumn() {
    final visitor = controller.rxSelectedVisitor.value;

    return Column(
      children: [
        // ── 1. Top Visitor Profile Card (Keyed for Tour Step 2) ───────────
        Expanded(
          flex: 8,
          child: _buildCardContainer(
            key: _keyVisitorProfile,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Visitor Photo with Rounded Frame & Face Detection Reticle
                Expanded(
                  flex: 4,
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            visitor?['photo'] ??
                                visitor?['image'] ??
                                'assets/images/ava_person1.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFE2E8F0),
                              child: const Icon(Icons.person,
                                  size: 44, color: _textMuted),
                            ),
                          ),
                          // Green Face Detection Target Overlay
                          Center(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _greenSuccess,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Visitor Details Table (Clean Typography with Tight Divider)
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        visitor?['name'] ?? 'Name',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F2B48),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Divider(height: 5, thickness: 1, color: Color(0xFFE2E8F0)),
                      _buildDetailRow(Icons.apartment_rounded, 'Organization',
                          visitor?['company'] ?? visitor?['org'] ?? '-'),
                      _buildDetailRow(Icons.email_outlined, 'Email',
                          visitor?['email'] ?? '-'),
                      _buildDetailRow(Icons.phone_outlined, 'Phone',
                          visitor?['phone'] ?? '-'),
                      _buildDetailRow(Icons.credit_card_outlined, 'Identity ID',
                          visitor?['id_card_no'] ?? visitor?['id'] ?? '-'),
                      _buildDetailRow(Icons.transgender_outlined, 'Gender',
                          visitor?['gender'] ?? '-'),
                      _buildDetailRow(Icons.person_outline_rounded, 'Occupancy',
                          visitor?['occupancy'] ?? '-'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 5),

        // ── 2 & 3. Middle Tabs & QR Code (Grouped & Keyed for Tour Step 3) ─
        Expanded(
          flex: 21,
          child: Container(
            key: _keyVisitorTabs,
            child: Column(
              children: [
                Expanded(
                  flex: 12,
                  child: _buildCardContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tabs Navigation Row (Even spacing & clean indicators)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTabHeader(0, 'Visit Information'),
                            _buildTabHeader(1, 'Purpose Visit'),
                            _buildTabHeader(2, 'Card'),
                            _buildTabHeader(3, 'History'),
                          ],
                        ),
                        const Divider(height: 10, thickness: 1, color: Color(0xFFF1F5F9)),

                        // Tab Content with Middle Vertical Divider
                        Expanded(
                          child: _selectedVisitorInfoTab == 0
                              ? _buildVisitInformationTab(visitor)
                              : _selectedVisitorInfoTab == 1
                                  ? _buildPurposeVisitTab(visitor)
                                  : _selectedVisitorInfoTab == 2
                                      ? _buildCardTab(visitor)
                                      : _buildHistoryTab(visitor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Expanded(
                  flex: 9,
                  child: _buildCardContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visitor QR Code',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F2B48),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // QR Code Icon / Box
                              Expanded(
                                flex: 5,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (visitor?['qr_code_data'] != null)
                                      SizedBox(
                                        width: 52,
                                        height: 52,
                                        child: QrImageView(
                                          data: visitor!['qr_code_data'].toString(),
                                          version: QrVersions.auto,
                                          size: 52.0,
                                        ),
                                      )
                                    else ...[
                                      const Icon(
                                        Icons.filter_none_rounded,
                                        size: 30,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'No QR/Card Available',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'Scan a visitor to show QR code',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Invitation / Check In / Out Time (Scaled gracefully)
                              Expanded(
                                flex: 5,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildQrDetailField(
                                        'Invitation Code',
                                        visitor?['invitation_code'] ?? '-',
                                      ),
                                      const SizedBox(height: 4),
                                      _buildQrDetailField(
                                        'Check In Time',
                                        visitor?['check_in'] ?? '-',
                                      ),
                                      const SizedBox(height: 4),
                                      _buildQrDetailField(
                                        'Check Out Time',
                                        visitor?['check_out'] ?? '-',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF334155)),
          const SizedBox(width: 8),
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          Text(
            ' :  ',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E293B),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitInformationTab(Map<String, dynamic>? visitor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetadataField(
                Icons.groups_outlined,
                'Visitor Code',
                visitor?['visitor_code'] ?? '-',
              ),
              _buildMetadataField(
                Icons.person_outline_rounded,
                'Group Name',
                visitor?['group_name'] ?? '-',
              ),
              _buildMetadataField(
                Icons.format_list_numbered_rounded,
                'Visitor Number',
                visitor?['ticket_no'] ?? '-',
              ),
              _buildMetadataField(
                Icons.directions_car_outlined,
                'Vehicle Type',
                visitor?['vehicle_type'] ?? '-',
              ),
            ],
          ),
        ),

        // Vertical divider in the middle
        Container(
          width: 1,
          height: double.infinity,
          color: const Color(0xFFF1F5F9),
          margin: const EdgeInsets.symmetric(horizontal: 10),
        ),

        // Right Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetadataField(
                Icons.badge_outlined,
                'Invited By',
                visitor?['host_name'] ?? '-',
              ),
              _buildMetadataField(
                Icons.person_outline_rounded,
                'Group',
                visitor?['is_group'] == true ? 'Yes' : 'No',
              ),
              _buildMetadataField(
                Icons.assignment_outlined,
                'Visitor Status',
                visitor?['status'] ?? '-',
              ),
              _buildMetadataField(
                Icons.receipt_long_outlined,
                'Vehicle Plate No.',
                visitor?['vehicle_plate'] ?? '-',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPurposeVisitTab(Map<String, dynamic>? visitor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetadataField(
                Icons.calendar_today_outlined,
                'Agenda',
                visitor?['purpose'] ?? visitor?['agenda'] ?? '-',
              ),
              _buildMetadataField(
                Icons.more_time_rounded,
                'Visit Period Start',
                visitor?['period_start'] ?? visitor?['start_time'] ?? '-',
              ),
              _buildMetadataField(
                Icons.location_on_outlined,
                'Site',
                visitor?['site'] ?? _selectedSite,
              ),
            ],
          ),
        ),

        // Vertical divider in the middle
        Container(
          width: 1,
          height: double.infinity,
          color: const Color(0xFFF1F5F9),
          margin: const EdgeInsets.symmetric(horizontal: 10),
        ),

        // Right Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetadataField(
                Icons.person_pin_circle_outlined,
                'PIC Host',
                visitor?['host_name'] ?? '-',
              ),
              _buildMetadataField(
                Icons.event_available_outlined,
                'Visit Period End',
                visitor?['period_end'] ?? visitor?['end_time'] ?? '-',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardTab(Map<String, dynamic>? visitor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetadataField(
                Icons.credit_card_outlined,
                'Card Number',
                visitor?['card_no'] ?? '-',
              ),
              _buildMetadataField(
                Icons.nfc_outlined,
                'Card UID',
                visitor?['card_uid'] ?? '-',
              ),
              _buildMetadataField(
                Icons.verified_user_outlined,
                'Card Status',
                visitor?['card_status'] ?? 'Active',
              ),
            ],
          ),
        ),
        Container(
          width: 1,
          height: double.infinity,
          color: const Color(0xFFF1F5F9),
          margin: const EdgeInsets.symmetric(horizontal: 10),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetadataField(
                Icons.vpn_key_outlined,
                'Access Level',
                visitor?['access_level'] ?? 'Standard Gate',
              ),
              _buildMetadataField(
                Icons.access_time_outlined,
                'Issued At',
                visitor?['issued_at'] ?? '-',
              ),
              _buildMetadataField(
                Icons.keyboard_return_outlined,
                'Return At',
                visitor?['return_at'] ?? '-',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab(Map<String, dynamic>? visitor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetadataField(
                Icons.history_rounded,
                'Previous Visits',
                '1 Visit',
              ),
              _buildMetadataField(
                Icons.business_center_outlined,
                'Last Host',
                visitor?['host_name'] ?? '-',
              ),
            ],
          ),
        ),
        Container(
          width: 1,
          height: double.infinity,
          color: const Color(0xFFF1F5F9),
          margin: const EdgeInsets.symmetric(horizontal: 10),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetadataField(
                Icons.login_rounded,
                'Last Check In',
                visitor?['check_in'] ?? '-',
              ),
              _buildMetadataField(
                Icons.logout_rounded,
                'Last Check Out',
                visitor?['check_out'] ?? '-',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabHeader(int index, String title) {
    final isSelected = _selectedVisitorInfoTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedVisitorInfoTab = index),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF003082) : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              height: 2.5,
              width: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF003082),
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 2.5),
        ],
      ),
    );
  }

  Widget _buildMetadataField(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1E293B)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1.5),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQrDetailField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 1.5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CENTER COLUMN (~41% width)
  // 1. Color-coded Action Buttons Grid (Keeps Printer!)
  // 2. Visitors Management Feed Table
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCenterColumn() {
    return Column(
      children: [
        // ── 1. Color-coded Quick Action Buttons Grid (Keyed for Tour Step 4) ──
        _buildCardContainer(
          key: _keyActionGrid,
          padding: const EdgeInsets.all(6.0),
          child: Column(
            children: [
              // Row 1: Scan QR (Wide), Parking, Open
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildActionButton(
                      label: 'Scan QR',
                      icon: Icons.qr_code_scanner_rounded,
                      bgColor: const Color(0xFF004385),
                      onTap: () => _handleAction('Scan QR'),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: _buildActionButton(
                      label: 'Parking',
                      icon: Icons.local_parking_rounded,
                      bgColor: const Color(0xFF00ACC1),
                      onTap: () => _handleAction('Parking'),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: _buildActionButton(
                      label: 'Open',
                      icon: Icons.door_sliding_outlined,
                      bgColor: const Color(0xFFB71C1C),
                      onTap: () => _handleAction('Open Door'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Row 2: Pra Register, Walk In, Extend, Arrival
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: 'Pra Register',
                      icon: Icons.person_add_alt_1_outlined,
                      bgColor: const Color(0xFF004385),
                      onTap: () => _handleAction('Pra Register'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildActionButton(
                      label: 'Walk In',
                      icon: Icons.directions_walk_rounded,
                      bgColor: const Color(0xFF1565C0),
                      onTap: () => _handleAction('Walk In'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildActionButton(
                      label: 'Extend',
                      icon: Icons.access_time_rounded,
                      bgColor: const Color(0xFFFBC02D),
                      onTap: () => _handleAction('Extend'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildActionButton(
                      label: 'Arrival',
                      icon: Icons.alternate_email_rounded,
                      bgColor: const Color(0xFF00897B),
                      onTap: () => _handleAction('Arrival'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Row 3: Checkin, Checkout, Print (KEPT!), Blacklist
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: 'Checkin',
                      icon: Icons.login_rounded,
                      bgColor: const Color(0xFF2E7D32),
                      onTap: () => _handleAction('Check In'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildActionButton(
                      label: 'Checkout',
                      icon: Icons.logout_rounded,
                      bgColor: const Color(0xFFD32F2F),
                      onTap: () => _handleAction('Check Out'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Printer Action Button (Strictly Preserved)
                  Expanded(
                    child: _buildActionButton(
                      label: 'Print',
                      icon: Icons.print_rounded,
                      bgColor: const Color(0xFF455A64),
                      onTap: () => _handlePrintAction(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildActionButton(
                      label: 'Blacklist',
                      icon: Icons.block_rounded,
                      bgColor: const Color(0xFF212121),
                      onTap: () => _handleAction('Blacklist'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Row 4: Card Issuance, Card Return, Enable Edit, Edit Form
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: 'Card Issuance',
                      icon: Icons.credit_card_rounded,
                      bgColor: const Color(0xFF7B1FA2),
                      onTap: () => _handleAction('Card Issuance'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildActionButton(
                      label: 'Card Return',
                      icon: Icons.keyboard_return_rounded,
                      bgColor: const Color(0xFF1E88E5),
                      onTap: () => _handleAction('Card Return'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildActionButton(
                      label: 'Enable Edit',
                      icon: Icons.edit_note_rounded,
                      bgColor: const Color(0xFF0D47A1),
                      onTap: () => _handleAction('Enable Edit'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildActionButton(
                      label: 'Edit Form',
                      icon: Icons.edit_rounded,
                      bgColor: const Color(0xFF1976D2),
                      onTap: () => _handleAction('Edit Form'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Row 5: Access Issuance
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: 'Access Issuance',
                      icon: Icons.vpn_key_rounded,
                      bgColor: const Color(0xFFFB8C00),
                      onTap: () => _handleAction('Access Issuance'),
                    ),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 5),

        // ── 2. Visitors Management Feed Table (Keyed for Tour Step 5) ─────
        Expanded(
          child: _buildCardContainer(
            key: _keyVisitorsFeed,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tabs: Live Visitors (0) | Related Visitors (0)
                Row(
                  children: [
                    _buildVisitorListTab(0, 'Live Visitors (${controller.rxRelatedVisitors.length})'),
                    const SizedBox(width: 24),
                    _buildVisitorListTab(1, 'Related Visitors (${controller.rxAllRelatedVisitors.length})'),
                  ],
                ),
                const SizedBox(height: 8),

                // Search & Filter Toolbar Row (Crisp & aligned)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Search Bar
                    Expanded(
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_rounded,
                                size: 17, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _visitorSearchController,
                                textAlignVertical: TextAlignVertical.center,
                                style: GoogleFonts.inter(
                                    fontSize: 12.5, color: _textDark, height: 1.2),
                                decoration: InputDecoration(
                                  hintText: 'Search Visitor',
                                  hintStyle: GoogleFonts.inter(
                                      fontSize: 12.5, color: const Color(0xFF94A3B8), height: 1.2),
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

                    const SizedBox(width: 8),

                    // Filter Funnel Button
                    Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.filter_alt_outlined,
                            size: 18, color: Color(0xFF003082)),
                        onPressed: () {},
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Select Multiple & Pagination Row (Keyed for Tour Step 6)
                    Row(
                      key: _keySelectMultiple,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Select Multiple Checkbox
                        Transform.scale(
                          scale: 0.85,
                          child: Checkbox(
                            value: controller.rxSelectMultiple.value,
                            activeColor: const Color(0xFF003082),
                            onChanged: (val) {
                              controller.rxSelectMultiple.value = val ?? false;
                            },
                          ),
                        ),
                        Text(
                          'Select Multiple',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Pagination Indicator (< 0/0 >)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 22, minHeight: 22),
                          icon: const Icon(Icons.chevron_left_rounded,
                              size: 20, color: Color(0xFF64748B)),
                          onPressed: () {},
                        ),
                        Obx(() {
                          final current = controller.rxCurrentPage.value;
                          final total = controller.rxTotalPages.value;
                          return Text(
                            '$current/$total',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: _textDark,
                            ),
                          );
                        }),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 22, minHeight: 22),
                          icon: const Icon(Icons.chevron_right_rounded,
                              size: 20, color: Color(0xFF64748B)),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),

                const Divider(height: 14, thickness: 1, color: Color(0xFFF1F5F9)),

                // Visitor List / Feed Content Area
                Expanded(
                  child: Obx(() {
                    final list = controller.rxRelatedVisitors;
                    if (list.isEmpty) {
                      return const SizedBox.expand();
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 6,
                        thickness: 1,
                        color: Color(0xFFF1F5F9),
                      ),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        final isSelected =
                            controller.rxSelectedVisitor.value?['id'] ==
                                item['id'];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              controller.rxSelectedVisitor.value = item;
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFEBF3FC)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundImage: AssetImage(
                                      item['photo'] ??
                                          item['image'] ??
                                          'assets/images/ava_person1.png',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] ?? 'Visitor',
                                          style: GoogleFonts.inter(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: _textDark,
                                          ),
                                        ),
                                        Text(
                                          item['company'] ??
                                              item['invitation_code'] ??
                                              '-',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: _textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      item['status'] ?? 'Expected',
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF15803D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),

                // Bottom Bulk Action Toolbar (Fill Form dropdown & Apply)
                Row(
                  children: [
                    CompositedTransformTarget(
                      link: _bulkActionLayerLink,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _toggleBulkActionMenu,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _isBulkActionMenuOpen
                                    ? const Color(0xFF003082)
                                    : const Color(0xFFCBD5E1),
                                width: _isBulkActionMenuOpen ? 1.2 : 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  _selectedBulkAction,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _textDark,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  _isBulkActionMenuOpen
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                  size: 18,
                                  color: _isBulkActionMenuOpen
                                      ? const Color(0xFF003082)
                                      : const Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          AppSnackbar.info(
                            title: 'Action Applied',
                            message: 'Action $_selectedBulkAction applied.',
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              'Apply',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: bgColor.withValues(alpha: 0.2),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: Colors.white),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisitorListTab(int index, String title) {
    final isSelected = _selectedVisitorListTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedVisitorListTab = index),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF003082) : _textMuted,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              height: 2.5,
              width: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF003082),
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 2.5),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RIGHT COLUMN (~29% width)
  // 1. Host Information Card (Tight, refined & matching screenshot without dead space)
  // 2. Live Occupancy Card
  // 3. Identity Image Card
  // 4. Alerts Card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRightColumn() {
    final visitor = controller.rxSelectedVisitor.value;

    return Column(
      children: [
        // ── 1. Host Information Card (Keyed for Tour Step 7) ──────────────
        Expanded(
          flex: 9,
          child: _buildCardContainer(
            key: _keyHostInfo,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Host Information',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),

                // Avatar + Detailed Host info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Circular Avatar (blue-grey)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Color(0xFF78909C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            visitor?['host_name'] ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            visitor?['host_dept'] ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: _textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined,
                                  size: 12, color: _textDark),
                              const SizedBox(width: 4),
                              Text(
                                ' :  ${visitor?['host_phone'] ?? "-"}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              Icon(Icons.email_outlined,
                                  size: 12, color: _textDark),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  ' :  ${visitor?['host_email'] ?? "-"}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 6, color: Color(0xFFECEFF1)),

                // 3 Large Action Buttons: Call, Chat, Email (Pastel Fills)
                Row(
                  children: [
                    Expanded(
                      child: _buildHostActionButton(
                        label: 'Call',
                        icon: Icons.phone_outlined,
                        bgColor: const Color(0xFF789EC6), // Pastel steel blue
                        onTap: () => _handleContactAction('Calling host...'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildHostActionButton(
                        label: 'Chat',
                        icon: Icons.chat_bubble_outline_rounded,
                        bgColor: const Color(0xFF79E7C4), // Pastel mint green
                        onTap: () =>
                            _handleContactAction('Opening WhatsApp Chat...'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildHostActionButton(
                        label: 'Email',
                        icon: Icons.email_outlined,
                        bgColor: const Color(0xFF9AE6FF), // Pastel soft sky blue
                        onTap: () =>
                            _handleContactAction('Composing email to host...'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 5),

        // ── 2. Live Occupancy Card (Keyed for Tour Step 8) ─────────────────
        Expanded(
          flex: 7,
          child: _buildCardContainer(
            key: _keyLiveOccupancy,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Live Occupancy',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F2B48),
                      ),
                    ),
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _occupancyFilter,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1E293B),
                          ),
                          items: ['Today', 'This Week', 'This Month']
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(f),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _occupancyFilter = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBFDFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'No visiting purpose available.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 5),

        // ── 3. Identity Image Card (Keyed for Tour Step 9) ─────────────────
        Expanded(
          flex: 7,
          child: _buildCardContainer(
            key: _keyIdentityImage,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identity Image',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F2B48),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'No Identity Image',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 5),

        // ── 4. Alerts Card (Keyed for Tour Step 10) ────────────────────────
        Expanded(
          flex: 6,
          child: _buildCardContainer(
            key: _keyAlerts,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerts',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F2B48),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 32,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No alerts available',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHostActionButton({
    required String label,
    required IconData icon,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: bgColor.withValues(alpha: 0.25),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Card Container Utility with Soft Shadow & Border
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCardContainer({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(6.0),
  }) {
    return Container(
      key: key,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom Copyright Footer
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Copyright © 2026 ',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _textMuted,
            ),
          ),
          Image.asset(
            'assets/images/logoOnlyBio.png',
            height: 14,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Text(
              'Bio Experience',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
          ),
          Text(
            ' . All Rights Reserved.',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Quick Actions Handlers
  // ─────────────────────────────────────────────────────────────────────────
  void _handleAction(String actionName) {
    AppSnackbar.info(
      title: actionName,
      message: 'Processing $actionName for operator terminal...',
    );
  }

  void _handlePrintAction() {
    AppSnackbar.success(
      title: 'Print Badge',
      message: 'Sending visitor pass badge to connected thermal printer...',
    );
  }

  void _handleContactAction(String message) {
    AppSnackbar.info(
      title: 'Host Contact',
      message: message,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Custom Floating Visitor Site Dropdown Menu
  // ─────────────────────────────────────────────────────────────────────────
  void _toggleVisitorSiteMenu() {
    if (_visitorSiteOverlay != null) {
      _closeVisitorSiteMenu();
      return;
    }

    setState(() {
      _isVisitorSiteMenuOpen = true;
    });

    final overlay = Overlay.of(context);
    _visitorSiteOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss on tap outside
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeVisitorSiteMenu,
            ),
          ),
          // Sleek Floating dropdown menu
          Positioned(
            width: 145,
            child: CompositedTransformFollower(
              link: _visitorSiteLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 33),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildVisitorSiteMenuItem(
                        title: 'List Visitor',
                        isSelected: _selectedVisitorSiteMenu == 'List Visitor',
                        onTap: () {
                          setState(() {
                            _selectedVisitorSiteMenu = 'List Visitor';
                          });
                          _closeVisitorSiteMenu();
                        },
                      ),
                      const SizedBox(height: 2),
                      _buildVisitorSiteMenuItem(
                        title: 'Blacklist Visitor',
                        isSelected: _selectedVisitorSiteMenu == 'Blacklist Visitor',
                        onTap: () {
                          setState(() {
                            _selectedVisitorSiteMenu = 'Blacklist Visitor';
                          });
                          _closeVisitorSiteMenu();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_visitorSiteOverlay!);
  }

  void _closeVisitorSiteMenu() {
    if (_visitorSiteOverlay != null) {
      _visitorSiteOverlay?.remove();
      _visitorSiteOverlay = null;
      if (mounted) {
        setState(() {
          _isVisitorSiteMenuOpen = false;
        });
      }
    }
  }

  Widget _buildVisitorSiteMenuItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        hoverColor: const Color(0xFFF1F5F9),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFEBF3FC)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF003082)
                  : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Custom Floating Site Selector Dropdown Menu (SPU, Gedung SINERGI, Resident)
  // ─────────────────────────────────────────────────────────────────────────
  void _toggleSiteMenu() {
    if (_siteOverlay != null) {
      _closeSiteMenu();
      return;
    }

    setState(() {
      _isSiteMenuOpen = true;
    });

    final overlay = Overlay.of(context);
    _siteOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss on tap outside
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeSiteMenu,
            ),
          ),
          // Sleek Floating dropdown menu
          Positioned(
            width: 140,
            child: CompositedTransformFollower(
              link: _siteLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 33),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header: Select Site
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Text(
                          'Select Site',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      // Options: SPU, Gedung SINERGI, Resident
                      ...['SPU', 'Gedung SINERGI', 'Resident'].map((site) {
                        final isSelected = _selectedSite == site;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedSite = site;
                              });
                              _closeSiteMenu();
                            },
                            hoverColor: const Color(0xFFF1F5F9),
                            child: Container(
                              color: isSelected
                                  ? const Color(0xFFEBF3FC)
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Text(
                                site,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF003082)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_siteOverlay!);
  }

  void _closeSiteMenu() {
    if (_siteOverlay != null) {
      _siteOverlay?.remove();
      _siteOverlay = null;
      if (mounted) {
        setState(() {
          _isSiteMenuOpen = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Custom Floating Bulk Action Dropdown Menu (Fill Form, Checkin, Checkout, Print Badge)
  // ─────────────────────────────────────────────────────────────────────────
  void _toggleBulkActionMenu() {
    if (_bulkActionOverlay != null) {
      _closeBulkActionMenu();
      return;
    }

    setState(() {
      _isBulkActionMenuOpen = true;
    });

    final overlay = Overlay.of(context);
    _bulkActionOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss on tap outside
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeBulkActionMenu,
            ),
          ),
          // Sleek Floating dropdown menu opening cleanly upward above the toolbar
          Positioned(
            width: 150,
            child: CompositedTransformFollower(
              link: _bulkActionLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, -146),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...['Fill Form', 'Checkin', 'Checkout', 'Print Badge'].map((action) {
                        final isSelected = _selectedBulkAction == action;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedBulkAction = action;
                              });
                              _closeBulkActionMenu();
                            },
                            borderRadius: BorderRadius.circular(6),
                            hoverColor: const Color(0xFFF1F5F9),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFEBF3FC)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              child: Text(
                                action,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF003082)
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_bulkActionOverlay!);
  }

  void _closeBulkActionMenu() {
    if (_bulkActionOverlay != null) {
      _bulkActionOverlay?.remove();
      _bulkActionOverlay = null;
      if (mounted) {
        setState(() {
          _isBulkActionMenuOpen = false;
        });
      }
    }
  }
}
