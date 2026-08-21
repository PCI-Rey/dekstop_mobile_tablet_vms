import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../controller/dashboard_controller.dart';
import '../widgets/operator_tour_overlay.dart';
import '../widgets/add_pra_registration_modal.dart';
import 'desktop_overview_analytics.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/config/constants.dart';
import '../../../core/shared/routes/app_pages.dart';
import '../../../core/shared/widgets/app_snackbar.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

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
  int _selectedVisitorInfoTab =
      0; // 0: Visit Information, 1: Purpose Visit, 2: Card, 3: History

  // Filter controllers
  final TextEditingController _visitorSearchController =
      TextEditingController();
  final TextEditingController _topSearchController = TextEditingController();
  final PageController _livePageController = PageController();
  final PageController _relatedPageController = PageController();
  String _selectedSite = 'SPU';
  String? _selectedBulkAction;

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
    _livePageController.dispose();
    _relatedPageController.dispose();
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
      AppSnackbar.info(title: 'Fullscreen Mode', message: 'Fullscreen active');
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      AppSnackbar.info(title: 'Normal Mode', message: 'Normal view active');
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
      'Sunday',
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
      'December',
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
      resizeToAvoidBottomInset: false,
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
                          Expanded(flex: 30, child: _buildLeftColumn()),

                          const SizedBox(width: 8),

                          // ── Center Column (~41% width) ────────────────────────
                          Expanded(flex: 41, child: _buildCenterColumn()),

                          const SizedBox(width: 8),

                          // ── Right Column (~29% width) ─────────────────────────
                          Expanded(flex: 29, child: _buildRightColumn()),
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
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
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
                  const Icon(
                    Icons.home_outlined,
                    size: 14,
                    color: Colors.white,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.home_outlined,
                        size: 14,
                        color: _textMuted,
                      ),
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
                  const Icon(
                    Icons.visibility_outlined,
                    size: 13,
                    color: Colors.white,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: _textMuted,
                      ),
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: TextField(
                        controller: _topSearchController,
                        textAlignVertical: TextAlignVertical.center,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          UpperCaseTextFormatter(),
                        ],
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: _textDark,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Search Visitor / Code (e.g. 15Y1H5-QR5FHL)',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: _textMuted,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 15,
                            color: _textMuted,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 30,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.only(right: 8),
                          suffixIcon: _topSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 14,
                                    color: _textMuted,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 26,
                                    minHeight: 30,
                                  ),
                                  onPressed: () {
                                    _topSearchController.clear();
                                    controller.resetDashboardToInitialState();
                                    setState(() {});
                                  },
                                )
                              : null,
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 26,
                            minHeight: 30,
                          ),
                        ),
                        onChanged: (val) => setState(() {}),
                        onSubmitted: (val) async {
                          final query = val.trim().toUpperCase();
                          if (query.isNotEmpty) {
                            final success = await controller
                                .searchInvitationCode(query);
                            if (success) {
                              AppSnackbar.success(
                                title: 'Success',
                                message: 'Data retrieved successfully',
                              );
                            } else {
                              AppSnackbar.error(
                                title: 'Search Failed',
                                message:
                                    'No visitor data found for: $query',
                              );
                            }
                          }
                        },
                      ),
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
                      controller.resetDashboardToInitialState();
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
                          const Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: _redDanger,
                          ),
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
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
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
              icon: const Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: Colors.white,
              ),
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
    return Obx(() {
      final visitor = controller.rxSelectedVisitor.value;

      return Column(
        children: [
          // ── 1. Top Visitor Profile Card (Keyed for Tour Step 2) ───────────
          Expanded(
            flex: 10,
            child: _buildCardContainer(
              key: _keyVisitorProfile,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                // Visitor Photo with Rounded Frame & Face Detection Reticle
                Expanded(
                  flex: 3,
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Builder(
                            builder: (context) {
                              final photoUrl = (visitor?['photo'] ??
                                      visitor?['avatar'] ??
                                      visitor?['faceimage'] ??
                                      '')
                                  .toString();
                              if (photoUrl.startsWith('/') ||
                                  photoUrl.startsWith('http')) {
                                return Image.network(
                                  AppConstants.getCdnImageUrl(photoUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFE2E8F0),
                                    child: const Icon(
                                      Icons.person,
                                      size: 44,
                                      color: _textMuted,
                                    ),
                                  ),
                                );
                              }
                              return Image.asset(
                                photoUrl.isNotEmpty && photoUrl != 'assets/images/ava_person1.png'
                                    ? photoUrl
                                    : 'assets/images/ava_person2.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFE2E8F0),
                                  child: const Icon(
                                    Icons.person,
                                    size: 44,
                                    color: _textMuted,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Green Face Detection Target Overlay (Only when visitor != null)
                          if (visitor != null)
                            Center(
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF00E676),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Visitor Details Table (Clean Typography with Tight Divider & ScaleDown)
                Expanded(
                  flex: 7,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        height: constraints.maxHeight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: constraints.maxWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (visitor != null) ...[
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          visitor['name'] ?? 'Visitor Name',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1E293B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 15,
                                        color: Color(0xFF00D696),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  Text(
                                    'Name',
                                    style: GoogleFonts.inter(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const Divider(
                                  height: 8,
                                  thickness: 1,
                                  color: Color(0xFFECEFF1),
                                ),
                                _buildDetailRow(
                                  Icons.apartment_rounded,
                                  'Organization',
                                  visitor?['company'] ?? visitor?['org'] ?? '-',
                                ),
                                _buildDetailRow(
                                  Icons.email_outlined,
                                  'Email',
                                  visitor?['email'] ?? '-',
                                ),
                                _buildDetailRow(
                                  Icons.phone_outlined,
                                  'Phone',
                                  visitor?['phone'] ?? '-',
                                ),
                                _buildDetailRow(
                                  Icons.credit_card_outlined,
                                  'Identity ID',
                                  visitor?['id_card_no'] ?? visitor?['id'] ?? '-',
                                ),
                                _buildDetailRow(
                                  Icons.transgender_rounded,
                                  'Gender',
                                  visitor?['gender'] ?? '-',
                                ),
                                _buildDetailRow(
                                  Icons.person_outline_rounded,
                                  'Occupancy',
                                  visitor?['occupancy'] ?? '-',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 5),

        // ── 2 & 3. Middle Tabs & QR Code (Grouped & Keyed for Tour Step 3) ─
        Expanded(
          flex: 20,
          child: Container(
            key: _keyVisitorTabs,
            child: Column(
              children: [
                Expanded(
                  flex: 11,
                  child: _buildCardContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
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
                        const Divider(
                          height: 8,
                          thickness: 1,
                          color: Color(0xFFF1F5F9),
                        ),

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                              // Left: Prominent QR Code container with Tap Modal
                              Builder(
                                builder: (context) {
                                  final qrData = (visitor?['invitation_code'] != null &&
                                          visitor!['invitation_code'].toString() != '-' &&
                                          visitor['invitation_code'].toString().isNotEmpty)
                                      ? visitor['invitation_code'].toString()
                                      : (visitor?['qr_code_data'] != null &&
                                              visitor!['qr_code_data'].toString() != '-' &&
                                              visitor['qr_code_data'].toString().isNotEmpty
                                          ? visitor['qr_code_data'].toString()
                                          : (visitor?['visitor_code'] != null &&
                                                  visitor!['visitor_code'].toString() != '-' &&
                                                  visitor['visitor_code'].toString().isNotEmpty
                                              ? visitor['visitor_code'].toString()
                                              : null));

                                  if (qrData != null && qrData.isNotEmpty) {
                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _showVisitorQrModal(
                                          context,
                                          visitor,
                                          qrData,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Tooltip(
                                          message: 'Click to enlarge QR Code',
                                          child: Container(
                                            width: 94,
                                            height: 94,
                                            padding: const EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: const Color(0xFFE2E8F0),
                                                width: 1.2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.04),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: QrImageView(
                                              data: qrData,
                                              version: QrVersions.auto,
                                              padding: EdgeInsets.zero,
                                              size: 84.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  return Container(
                                    width: 94,
                                    height: 94,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.qr_code_2_rounded,
                                          size: 34,
                                          color: Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'No QR',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(width: 16),

                              // Right: Invitation / Check In / Out Time Fields
                              Expanded(
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
                                        isCopyable: true,
                                      ),
                                      const SizedBox(height: 3),
                                      _buildQrDetailField(
                                        'Check In Time',
                                        visitor?['check_in'] ?? '-',
                                      ),
                                      const SizedBox(height: 3),
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
  });
}

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    final displayValue = (value == null || value.trim().isEmpty || value.trim() == 'null')
        ? '-'
        : value.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Icon(icon, size: 13.5, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(width: 5),
          SizedBox(
            width: 82,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          Text(
            ' :  ',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E293B),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              maxLines: 2,
              softWrap: true,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitInformationTab(Map<String, dynamic>? visitor) {
    final bool isHost = visitor?['is_host'] == true || visitor?['raw']?['is_host'] == true;

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMetadataField(
                      Icons.qr_code_scanner_rounded,
                      'Visitor Code',
                      visitor?['visitor_code'] ?? visitor?['ticket_no'] ?? '-',
                    ),
                    _buildMetadataField(
                      Icons.groups_outlined,
                      'Group Name',
                      visitor?['group_name'] ?? '-',
                    ),
                    _buildMetadataField(
                      Icons.format_list_numbered_rounded,
                      'Visitor Number',
                      visitor?['visitor_number'] ??
                          visitor?['ticket_no'] ??
                          '-',
                    ),
                    if (!isHost)
                      _buildMetadataField(
                        Icons.commute_outlined,
                        'Vehicle Type',
                        visitor?['vehicle_type'] ?? '-',
                      ),
                  ],
                ),
              ),

              // Vertical divider in the middle
              Container(
                width: 1,
                color: const Color(0xFFF1F5F9),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                      visitor?['invited_by_name'] ??
                          visitor?['host_name'] ??
                          '-',
                    ),
                    _buildMetadataField(
                      Icons.person_outline_rounded,
                      'Group',
                      (visitor != null && visitor['is_group'] != null)
                          ? (visitor['is_group'] == true ? 'Yes' : 'No')
                          : '-',
                    ),
                    (visitor != null &&
                            (visitor['visitor_status'] != null ||
                                visitor['status'] != null))
                        ? _buildStatusMetadataField(
                            Icons.assignment_outlined,
                            'Visitor Status',
                            visitor['visitor_status'] ??
                                visitor['status'] ??
                                '-',
                          )
                        : _buildMetadataField(
                            Icons.assignment_outlined,
                            'Visitor Status',
                            '-',
                          ),
                    if (!isHost)
                      _buildMetadataField(
                        Icons.receipt_long_outlined,
                        'Vehicle Plate No.',
                        visitor?['vehicle_plate_number'] ??
                            visitor?['vehicle_plate'] ??
                            '-',
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (visitor != null) ...[
          const SizedBox(height: 4),
          Builder(
            builder: (context) {
              final rawStatus = (visitor['visitor_status'] ?? visitor['status'] ?? '').toString().toLowerCase();
              final isBlocked = visitor['is_block'] == true ||
                  rawStatus == 'block' ||
                  rawStatus == 'blacklist';
              final bool isHost = visitor['is_host'] == true || visitor['raw']?['is_host'] == true;

              // 1. If visitor is blocked / blacklisted (is_block == true): show Unblock button
              if (isBlocked) {
                return Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: 26,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004385),
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 0,
                        ),
                      ),
                      onPressed: () => _handleAction('Unblock'),
                      icon: const Icon(Icons.lock_open_rounded, size: 14, color: Colors.white),
                      label: Text(
                        'Unblock',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }
              // 2. If is_block == false and visitor is Checkin: show BOTH Check Out + Block buttons
              else if (rawStatus.contains('checkin') || rawStatus == 'in') {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 26,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE50000),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 0,
                          ),
                        ),
                        onPressed: () => _handleAction('Check Out'),
                        icon: const Icon(Icons.logout_rounded, size: 14, color: Colors.white),
                        label: Text(
                          'Check Out',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 26,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 0,
                          ),
                        ),
                        onPressed: () => _handleAction('Block'),
                        icon: const Icon(Icons.block_rounded, size: 14, color: Colors.white),
                        label: Text(
                          'Block',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              // 3. If visitor is Checkout: show ONLY the Block button
              else if (rawStatus.contains('checkout') || rawStatus == 'out') {
                return Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: 26,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 0,
                        ),
                      ),
                      onPressed: () => _handleAction('Block'),
                      icon: const Icon(Icons.block_rounded, size: 14, color: Colors.white),
                      label: Text(
                        'Block',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }
              // 4. If Host (is_host == true) OR visitor is Available / Waiting: show Check In + Block buttons
              else if (isHost || rawStatus.contains('available') || rawStatus.contains('waiting')) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 26,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 0,
                          ),
                        ),
                        onPressed: () => _handleAction('Check In'),
                        icon: const Icon(Icons.login_rounded, size: 14, color: Colors.white),
                        label: Text(
                          'Check In',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 26,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 0,
                          ),
                        ),
                        onPressed: () => _handleAction('Block'),
                        icon: const Icon(Icons.block_rounded, size: 14, color: Colors.white),
                        label: Text(
                          'Block',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              // 5. Regular visitor with Preregis / Praregis or default: show ONLY the Fill Form button
              else {
                return Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: 26,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004385),
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 0,
                        ),
                      ),
                      onPressed: () => _handleAction('Fill Form'),
                      child: Text(
                        'Fill Form',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPurposeVisitTab(Map<String, dynamic>? visitor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                visitor?['agenda'] ?? visitor?['purpose'] ?? '-',
              ),
              _buildMetadataField(
                Icons.more_time_rounded,
                'Visit Period Start',
                visitor?['visitor_period_start'] ??
                    visitor?['period_start'] ??
                    '-',
              ),
              _buildMetadataField(
                Icons.location_on_outlined,
                'Site',
                visitor?['site_place_name'] ?? visitor?['site'] ?? '-',
              ),
            ],
          ),
        ),

        // Vertical divider in the middle
        Container(
          width: 1,
          color: const Color(0xFFF1F5F9),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                visitor?['visitor_period_end'] ?? visitor?['period_end'] ?? '-',
              ),
              _buildMetadataField(
                Icons.domain_rounded,
                'Host Organization',
                visitor?['host_organization_name'] ??
                    visitor?['organization'] ??
                    '-',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardTab(Map<String, dynamic>? visitor) {
    final cardsList =
        (visitor?['cards'] as List?) ?? (visitor?['card'] as List?) ?? [];
    if (cardsList.isEmpty) {
      return Center(
        child: Text(
          'No card available',
          style: GoogleFonts.inter(fontSize: 12, color: _textMuted),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: cardsList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final card = Map<String, dynamic>.from(cardsList[index] as Map);
          final cardNum = (card['card_number'] ?? card['card_barcode'] ?? '-')
              .toString();
          final cardType = (card['card_type'] ?? 'Barcode').toString();
          final cardStatus = (card['card_status'] ?? 'Available').toString();
          final isCurrent = card['current_used'] == true;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00ACC1), width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 22,
                  color: Color(0xFF004385),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              cardNum,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (cardNum.isNotEmpty && cardNum != '-')
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: cardNum));
                                  AppSnackbar.success(
                                    title: 'Card Copied',
                                    message: 'Card number $cardNum copied to clipboard.',
                                  );
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Tooltip(
                                  message: 'Copy card number',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF004385).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.copy_rounded,
                                          size: 11,
                                          color: Color(0xFF004385),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Copy',
                                          style: GoogleFonts.inter(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF004385),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 6),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00ACC1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Current Card',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cardType,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Status',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        cardStatus,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusMetadataField(IconData icon, String label, String? value) {
    final displayValue = (value == null || value.trim().isEmpty || value.trim() == 'null')
        ? '-'
        : value.trim();

    Color badgeColor;
    final lower = displayValue.toLowerCase().replaceAll(' ', '').replaceAll('-', '').replaceAll('_', '');
    if (lower.contains('checkin') || lower == 'in') {
      badgeColor = Colors.green; // Sesuai warna popup notif success
    } else if (lower.contains('available') || lower.contains('approved')) {
      badgeColor = const Color(0xFF10B981); // Emerald Green
    } else if (lower.contains('waiting') || lower.contains('pending')) {
      badgeColor = const Color(0xFFF59E0B); // Amber Orange
    } else if (lower.contains('checkout') || lower == 'out') {
      badgeColor = Colors.red; // Sesuai warna popup notif gagal/error
    } else if (lower.contains('block') || lower.contains('blacklist')) {
      badgeColor = const Color(0xFF1E293B); // Hitam
    } else {
      badgeColor = const Color(0xFF94A3B8); // Abu-abu (Praregis / Default)
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF1E293B)),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1.5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  displayValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab(Map<String, dynamic>? visitor) {
    // History data is empty (API not yet available) matching screenshot
    return const SizedBox.shrink();
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
              color: isSelected
                  ? const Color(0xFF003082)
                  : const Color(0xFF1E293B),
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

  Widget _buildMetadataField(IconData icon, String label, String? value) {
    final displayValue = (value == null || value.trim().isEmpty || value.trim() == 'null')
        ? '-'
        : value.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF1E293B)),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                displayValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
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

  Widget _buildQrDetailField(String label, String? value, {bool isCopyable = false}) {
    final displayValue = (value == null || value.trim().isEmpty || value.trim() == 'null')
        ? '-'
        : value.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              displayValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
              ),
            ),
            if (isCopyable && displayValue != '-') ...[
              const SizedBox(width: 4),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: displayValue));
                    AppSnackbar.success(
                      title: 'Copied',
                      message: 'Invitation code copied to clipboard',
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 13,
                      color: Color(0xFF003082),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showVisitorQrModal(
    BuildContext context,
    Map<String, dynamic>? visitor,
    String qrData,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) {
        final invitationCode = (visitor?['invitation_code'] ?? qrData).toString();
        final visitorName = (visitor?['name'] ?? visitor?['visitor_name'] ?? 'Visitor').toString();

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            width: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with Centered Title and 'X' close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                  child: Row(
                    children: [
                      const SizedBox(width: 32),
                      Expanded(
                        child: Text(
                          'Scan Visitor QR Code',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: Color(0xFF64748B),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                // Body content: Large QR Code and details
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 230,
                        height: 230,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          padding: EdgeInsets.zero,
                          size: 206.0,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            invitationCode,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF003082),
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (invitationCode.isNotEmpty && invitationCode != '-') ...[
                            const SizedBox(width: 6),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(4),
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: invitationCode));
                                  AppSnackbar.success(
                                    title: 'Copied',
                                    message: 'Invitation code copied to clipboard',
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.copy_rounded,
                                    size: 16,
                                    color: Color(0xFF003082),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        visitorName,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Point scanner at this QR code to scan',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

              // Row 5: Access Issuance (Double width matching Scan QR)
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildActionButton(
                      label: 'Access Issuance',
                      icon: Icons.vpn_key_rounded,
                      bgColor: const Color(0xFFF57C00),
                      onTap: () => _handleAction('Access Issuance'),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Spacer(flex: 2),
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
                // Tabs: Live Visitors (0) | Related Visitors (2)
                Obx(() {
                  final liveCount = controller.rxLiveVisitors.length;
                  final relatedCount = controller.rxAllRelatedVisitors.length;
                  final activeTab = controller.rxFeedTabIndex.value;

                  return Row(
                    children: [
                      _buildVisitorListTab(
                        0,
                        'Live Visitors ($liveCount)',
                        isSelected: activeTab == 0,
                        onTap: () {
                          controller.rxFeedTabIndex.value = 0;
                          _visitorSearchController.text = controller.rxLiveSearchQuery.value;
                          setState(() {});
                        },
                      ),
                      const SizedBox(width: 24),
                      _buildVisitorListTab(
                        1,
                        'Related Visitors ($relatedCount)',
                        isSelected: activeTab == 1,
                        onTap: () {
                          controller.rxFeedTabIndex.value = 1;
                          _visitorSearchController.text = controller.rxRelatedSearchQuery.value;
                          setState(() {});
                        },
                      ),
                      const Spacer(),
                      // Refresh Button Box on the far right of the tab bar
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            await controller.refreshDashboardAllStatus();
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF1976D2).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.refresh_rounded,
                                  size: 14,
                                  color: Color(0xFF003082),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Refresh',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF003082),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 8),

                // Search & Filter Toolbar Row (Crisp & aligned)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Search Bar (Strictly searches by Visitor Name only)
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Center(
                          child: TextField(
                            controller: _visitorSearchController,
                            textAlignVertical: TextAlignVertical.center,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: _textDark,
                            ),
                            onChanged: (query) {
                              controller.filterVisitors(query);
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              hintText: 'Search Visitor',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: const Color(0xFF94A3B8),
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 17,
                                color: Color(0xFF94A3B8),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              suffixIcon: _visitorSearchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.cancel_rounded,
                                        size: 16,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 36),
                                      onPressed: () {
                                        _visitorSearchController.clear();
                                        controller.filterVisitors('');
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.only(right: 10),
                            ),
                          ),
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
                        icon: const Icon(
                          Icons.filter_alt_outlined,
                          size: 18,
                          color: Color(0xFF003082),
                        ),
                        onPressed: () {},
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Select Multiple & Pagination Row (Keyed for Tour Step 6)
                    Row(
                      key: _keySelectMultiple,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Reactive Instant Select Multiple Custom Checkbox & Label
                        Obx(() {
                          final isMultiple = controller.rxSelectMultiple.value;

                          void toggleMultiple() {
                            final nextVal = !isMultiple;
                            controller.rxSelectMultiple.value = nextVal;
                            controller.rxSelectedItems.clear();
                            setState(() {
                              _selectedBulkAction = null;
                            });
                            if (nextVal &&
                                controller.rxFeedTabIndex.value == 0 &&
                                controller.rxRelatedVisitors.isNotEmpty) {
                              controller.rxFeedTabIndex.value = 1;
                            }
                          }

                          return InkWell(
                            onTap: toggleMultiple,
                            borderRadius: BorderRadius.circular(6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 17,
                                  height: 17,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: isMultiple
                                        ? const Color(0xFF003082)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isMultiple
                                          ? const Color(0xFF003082)
                                          : const Color(0xFFCBD5E1),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isMultiple
                                      ? const Center(
                                          child: Icon(
                                            Icons.check_rounded,
                                            size: 13,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                                Text(
                                  'Select Multiple',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: _textDark,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(width: 12),
                        // Dedicated Pagination Indicator (< current/total >) with Button Controls
                        Obx(() {
                          final activeTab = controller.rxFeedTabIndex.value;
                          final list = activeTab == 0
                              ? controller.rxLiveVisitors
                              : controller.rxRelatedVisitors;
                          final total = list.isNotEmpty ? (list.length / 10).ceil() : 1;
                          final current = activeTab == 0
                              ? controller.rxLiveCurrentPage.value
                              : controller.rxRelatedCurrentPage.value;
                          final safeCurrent = current > total ? total : (current < 1 ? 1 : current);
                          final hasPrev = safeCurrent > 1;
                          final hasNext = safeCurrent < total;

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 22,
                                  minHeight: 22,
                                ),
                                icon: Icon(
                                  Icons.chevron_left_rounded,
                                  size: 20,
                                  color: hasPrev
                                      ? const Color(0xFF003082)
                                      : const Color(0xFFCBD5E1),
                                ),
                                onPressed: hasPrev
                                    ? () {
                                        final targetIndex = safeCurrent - 2;
                                        if (activeTab == 0) {
                                          if (_livePageController.hasClients) {
                                            _livePageController.animateToPage(
                                              targetIndex,
                                              duration: const Duration(milliseconds: 250),
                                              curve: Curves.easeInOut,
                                            );
                                          }
                                          controller.rxLiveCurrentPage.value = targetIndex + 1;
                                        } else {
                                          if (_relatedPageController.hasClients) {
                                            _relatedPageController.animateToPage(
                                              targetIndex,
                                              duration: const Duration(milliseconds: 250),
                                              curve: Curves.easeInOut,
                                            );
                                          }
                                          controller.rxRelatedCurrentPage.value = targetIndex + 1;
                                        }
                                      }
                                    : null,
                              ),
                              Text(
                                '$safeCurrent/$total',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _textDark,
                                ),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 22,
                                  minHeight: 22,
                                ),
                                icon: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: hasNext
                                      ? const Color(0xFF003082)
                                      : const Color(0xFFCBD5E1),
                                ),
                                onPressed: hasNext
                                    ? () {
                                        final targetIndex = safeCurrent;
                                        if (activeTab == 0) {
                                          if (_livePageController.hasClients) {
                                            _livePageController.animateToPage(
                                              targetIndex,
                                              duration: const Duration(milliseconds: 250),
                                              curve: Curves.easeInOut,
                                            );
                                          }
                                          controller.rxLiveCurrentPage.value = targetIndex + 1;
                                        } else {
                                          if (_relatedPageController.hasClients) {
                                            _relatedPageController.animateToPage(
                                              targetIndex,
                                              duration: const Duration(milliseconds: 250),
                                              curve: Curves.easeInOut,
                                            );
                                          }
                                          controller.rxRelatedCurrentPage.value = targetIndex + 1;
                                        }
                                      }
                                    : null,
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),

                const Divider(
                  height: 14,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                ),

                // Visitor List / Feed Content Area (2 Rows x 5 Cards = 10 Cards per Page with Swipe)
                Expanded(
                  child: Obx(() {
                    final activeTab = controller.rxFeedTabIndex.value;
                    final list = activeTab == 0
                        ? controller.rxLiveVisitors
                        : controller.rxRelatedVisitors;
                    final totalPages = list.isNotEmpty ? (list.length / 10).ceil() : 1;
                    final pageController = activeTab == 0
                        ? _livePageController
                        : _relatedPageController;

                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          activeTab == 0
                              ? 'No live visitors available'
                              : 'No related visitors available',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }

                    return ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.stylus,
                          PointerDeviceKind.trackpad,
                        },
                      ),
                      child: PageView.builder(
                        controller: pageController,
                        physics: const ClampingScrollPhysics(),
                        itemCount: totalPages > 0 ? totalPages : 1,
                        onPageChanged: (idx) {
                          if (activeTab == 0) {
                            controller.rxLiveCurrentPage.value = idx + 1;
                          } else {
                            controller.rxRelatedCurrentPage.value = idx + 1;
                          }
                        },
                        itemBuilder: (context, pageIndex) {
                          final startIndex = pageIndex * 10;
                          final pageItems = list.skip(startIndex).take(10).toList();
                          final row1Items = pageItems.take(5).toList();
                          final row2Items = pageItems.skip(5).take(5).toList();

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                            child: Column(
                              children: [
                                // Row 1 (Expanded, fills top half)
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      for (int i = 0; i < 5; i++) ...[
                                        if (i < row1Items.length)
                                          Expanded(
                                            child: _buildFeedVisitorCard(row1Items[i]),
                                          )
                                        else
                                          const Expanded(child: SizedBox()),
                                        if (i < 4) const SizedBox(width: 6),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Row 2 (Expanded, fills bottom half)
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      for (int i = 0; i < 5; i++) ...[
                                        if (i < row2Items.length)
                                          Expanded(
                                            child: _buildFeedVisitorCard(row2Items[i]),
                                          )
                                        else
                                          const Expanded(child: SizedBox()),
                                        if (i < 4) const SizedBox(width: 6),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ),

                // Bottom Bulk Action Toolbar (Only for Related Visitors; Hidden on Live Visitors)
                Obx(() {
                  final activeTab = controller.rxFeedTabIndex.value;
                  if (activeTab == 0) {
                    // Live Visitors tab is purely for displaying data, no bottom action bar
                    return const SizedBox.shrink();
                  }

                  return Row(
                    children: [
                      CompositedTransformTarget(
                        link: _bulkActionLayerLink,
                        child: Material(
                          color: Colors.transparent,
                          child: Obx(() {
                            final isMultipleActive = controller.rxSelectMultiple.value;
                            final hasItems = controller.rxSelectedItems.isNotEmpty;
                            final actions = _getAvailableBulkActions();
                            final isDropdownEnabled = isMultipleActive && hasItems && actions.isNotEmpty;
                            final hasActionSelected = isDropdownEnabled &&
                                _selectedBulkAction != null &&
                                actions.contains(_selectedBulkAction);

                            final displayAction = hasActionSelected
                                ? _selectedBulkAction!
                                : (isDropdownEnabled ? 'Select Action' : 'Action');

                            return InkWell(
                              onTap: isDropdownEnabled ? _toggleBulkActionMenu : null,
                              borderRadius: BorderRadius.circular(6),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                height: 32,
                                constraints: const BoxConstraints(minWidth: 128),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: isDropdownEnabled ? Colors.white : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (_isBulkActionMenuOpen && isDropdownEnabled)
                                        ? const Color(0xFF003082)
                                        : (isDropdownEnabled ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
                                    width: (_isBulkActionMenuOpen && isDropdownEnabled) ? 1.5 : 1,
                                  ),
                                  boxShadow: (_isBulkActionMenuOpen && isDropdownEnabled)
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF003082).withValues(alpha: 0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (hasActionSelected) ...[
                                      Icon(
                                        _getActionIcon(displayAction),
                                        size: 15,
                                        color: _getActionColor(displayAction),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      displayAction,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: hasActionSelected ? FontWeight.w600 : FontWeight.w500,
                                        color: hasActionSelected ? _textDark : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      (_isBulkActionMenuOpen && isDropdownEnabled)
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 17,
                                      color: isDropdownEnabled
                                          ? const Color(0xFF003082)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Obx(() {
                        final isMultipleActive = controller.rxSelectMultiple.value;
                        final hasItems = controller.rxSelectedItems.isNotEmpty;
                        final actions = _getAvailableBulkActions();
                        final isEnabled = isMultipleActive &&
                            hasItems &&
                            actions.isNotEmpty &&
                            _selectedBulkAction != null &&
                            actions.contains(_selectedBulkAction);

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isEnabled ? _applyBulkAction : null,
                            borderRadius: BorderRadius.circular(6),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: isEnabled
                                    ? const Color(0xFF004385)
                                    : const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  'Apply',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isEnabled
                                        ? Colors.white
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const Spacer(),
                      // Right Action Pills: Extend, Card Issuance, Print (Hidden on initial/empty state)
                      Obx(() {
                        final hasData = controller.rxSelectedVisitor.value != null ||
                            controller.rxAllRelatedVisitors.isNotEmpty;
                        if (!hasData) return const SizedBox.shrink();

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildFeedPillButton(
                              'Extend',
                              Icons.access_time_rounded,
                              const Color(0xFFFBBF24),
                              Colors.white,
                              () => _handleAction('Extend'),
                            ),
                            const SizedBox(width: 6),
                            _buildFeedPillButton(
                              'Card Issuance',
                              Icons.credit_card_rounded,
                              const Color(0xFF7B1FA2),
                              Colors.white,
                              () => _handleAction('Card Issuance'),
                            ),
                            const SizedBox(width: 6),
                            _buildFeedPillButton(
                              'Print',
                              Icons.print_rounded,
                              const Color(0xFF64748B),
                              Colors.white,
                              () => _handlePrintAction(),
                            ),
                          ],
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedPillButton(
    String label,
    IconData icon,
    Color bgColor,
    Color textColor,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: textColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildVisitorListTab(
    int index,
    String title, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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

  Widget _buildFeedVisitorCard(Map<String, dynamic> item) {
    return Obx(() {
      final selectedVisitor = controller.rxSelectedVisitor.value;
      final selectedId = (selectedVisitor?['invitation_code'] ??
              selectedVisitor?['visitor_code'] ??
              selectedVisitor?['id'] ??
              selectedVisitor?['transaction_visitor_id'] ??
              '')
          .toString();
      final currentActiveTab = controller.rxFeedTabIndex.value;
      final isMultipleMode = controller.rxSelectMultiple.value && currentActiveTab == 1;
      final selectedSet = controller.rxSelectedItems.toSet();

      final keys = [
        item['id'],
        item['trx_id'],
        item['transaction_visitor_id'],
        item['visitor_id'],
        item['invitation_code'],
        item['visitor_code'],
        item['visitor_number'],
        item['name'],
        item['visitor_name'],
      ].where((k) => k != null && k.toString().trim().isNotEmpty).map((k) => k.toString().trim()).toList();

      final itemId = (item['id'] ??
              item['transaction_visitor_id'] ??
              item['visitor_id'] ??
              item['invitation_code'] ??
              item['visitor_code'] ??
              '')
          .toString();
      final isSelected = isMultipleMode
          ? keys.any((k) => selectedSet.contains(k))
          : (selectedId.isNotEmpty && keys.contains(selectedId));
      final faceImg = (item['faceimage'] ??
              item['photo'] ??
              item['avatar'] ??
              item['host_faceimage'] ??
              '')
          .toString();

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (currentActiveTab == 0) {
              // 1. Tapping Live Visitor card (even if Select Multiple is active)
              // directly searches its invitation code & loads Related Visitors tab!
              final invCode = (item['invitation_code'] ??
                      item['visitor_code'] ??
                      item['initial_trx_code'] ??
                      '')
                  .toString()
                  .trim();

              if (controller.rxSelectMultiple.value) {
                controller.rxSelectedItems.clear();
                controller.rxSelectedItems.add(itemId);
              }

              if (invCode.isNotEmpty && invCode != '-') {
                await controller.searchInvitationCode(invCode);
              } else {
                controller.rxSelectedVisitor.value = item;
                controller.rxFeedTabIndex.value = 1;
              }
            } else {
              // 2. In Related Visitors tab:
              if (controller.rxSelectMultiple.value) {
                final isAlreadySelected = keys.any((k) => controller.rxSelectedItems.contains(k));
                if (isAlreadySelected) {
                  controller.rxSelectedItems.removeWhere((k) => keys.contains(k));
                } else {
                  controller.rxSelectedItems.add(itemId);
                }
                final actions = _getAvailableBulkActions();
                if (_selectedBulkAction != null &&
                    !actions.contains(_selectedBulkAction)) {
                  setState(() {
                    _selectedBulkAction = null;
                  });
                }
              } else {
                // Tapping Related Visitor card selects that specific visitor & syncs complete host info
                controller.rxSelectedVisitor.value = item;
                controller.syncHostForVisitor(item);
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF003082)
                    : const Color(0xFFE2E8F0),
                width: isSelected ? 1.8 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFF003082).withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: isSelected ? 6 : 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with circle frame
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFDBEAFE),
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (faceImg.isNotEmpty &&
                          faceImg != '-' &&
                          faceImg != 'null' &&
                          !faceImg.startsWith('assets/'))
                      ? Image.network(
                          AppConstants.getCdnImageUrl(faceImg),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.person,
                              size: 26,
                              color: Color(0xFF003082),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.person,
                            size: 26,
                            color: Color(0xFF003082),
                          ),
                        ),
                ),
                Builder(
                  builder: (context) {
                    final visitorName = (item['name'] ?? 'Visitor').toString();
                    final isLong = visitorName.length > 12;
                    final fontSize = isLong ? 10.0 : 11.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            visitorName,
                            style: GoogleFonts.inter(
                              fontSize: fontSize,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['organization'] ?? item['company'] ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              height: 1.1,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Checkbox Indicator
                Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF003082) : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF003082)
                          : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RIGHT COLUMN (~29% width)
  // 1. Host Information Card (Tight, refined & matching screenshot without dead space)
  // 2. Live Occupancy Card
  // 3. Identity Image Card
  // 4. Alerts Card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRightColumn() {
    return Obx(() {
      final visitor = controller.rxSelectedVisitor.value;
      final host = controller.rxPrimaryHost.value ??
          (visitor?['host_name'] != null ? visitor : null);

      return Column(
        children: [
          // ── 1. Host Information Card (Keyed for Tour Step 7) ──────────────
          Expanded(
            flex: 9,
            child: _buildCardContainer(
              key: _keyHostInfo,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Host Information',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F2B48),
                  ),
                ),

                // Avatar + Detailed Host info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Circular Avatar with CDN Face Image
                    Builder(
                      builder: (context) {
                        final hostFace = (host?['faceimage'] ??
                                host?['host_faceimage'] ??
                                host?['avatar'] ??
                                host?['photo'] ??
                                '')
                            .toString()
                            .trim();

                        return Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: (hostFace.isNotEmpty &&
                                  hostFace != '-' &&
                                  hostFace != 'null' &&
                                  !hostFace.startsWith('assets/'))
                              ? Image.network(
                                  AppConstants.getCdnImageUrl(hostFace),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.person,
                                      size: 34,
                                      color: Color(0xFF003082),
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 34,
                                    color: Color(0xFF003082),
                                  ),
                                ),
                        );
                      },
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (host != null &&
                              (host['name'] != null || host['host_name'] != null)) ...[
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    host['name'] ?? host['host_name'] ?? 'Host Name',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00D696),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    host['status'] ?? host['host_status'] ?? 'Available',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              host['organization'] ??
                                  host['host_organization_name'] ??
                                  host['host_dept'] ??
                                  'Organization SPU',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ] else ...[
                            Text(
                              '-',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_rounded,
                                size: 13.5,
                                color: Color(0xFF1E293B),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                ' :  ${host?['phone'] ?? host?['host_phone'] ?? "-"}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.mail_rounded,
                                size: 13.5,
                                color: Color(0xFF1E293B),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  ' :  ${host?['email'] ?? host?['host_email'] ?? "-"}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
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

                const Divider(height: 8, thickness: 1, color: Color(0xFFECEFF1)),

                // 3 Action Buttons: Call (Dark Blue), Chat (Mint Emerald), Email (Sky Blue)
                Row(
                  children: [
                    Expanded(
                      child: _buildHostActionButton(
                        label: 'Call',
                        icon: Icons.phone_rounded,
                        bgColor: const Color(0xFF00529C),
                        onTap: () => _handleContactAction(
                          'Calling host ${host?['name'] ?? host?['host_name'] ?? ""}...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildHostActionButton(
                        label: 'Chat',
                        icon: Icons.chat_bubble_outline_rounded,
                        bgColor: const Color(0xFF00D696),
                        onTap: () => _handleContactAction(
                          'Opening WhatsApp chat with host...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildHostActionButton(
                        label: 'Email',
                        icon: Icons.mail_rounded,
                        bgColor: const Color(0xFF38B6FF),
                        onTap: () => _handleContactAction(
                          'Composing email to ${visitor?['host_email'] ?? ""}...',
                        ),
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F2B48),
                      ),
                    ),
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF00529C), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Today',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Obx(() {
                      if (controller.rxIsOccupancyLoading.value && controller.rxUpcomingPurpose.isEmpty) {
                        return const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF003082),
                            ),
                          ),
                        );
                      }

                      final items = controller.rxUpcomingPurpose;
                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            'No live occupancy data available.',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }

                      final bgColors = [
                        const Color(0xFF99D636), // Vibrant Lime Green (exact match from screenshot)
                        const Color(0xFF38B6FF), // Sky Blue
                        const Color(0xFFFFA726), // Warm Amber Orange
                        const Color(0xFFAB47BC), // Purple
                        const Color(0xFF10B981), // Emerald Green
                      ];

                      return ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.stylus,
                            PointerDeviceKind.trackpad,
                          },
                        ),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final label = (item['name'] ?? item['purpose'] ?? 'Purpose').toString();
                            final count = (item['count'] ?? item['total'] ?? 0).toString();
                            final bgColor = bgColors[index % bgColors.length];

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  final categoryId = (item['id'] ?? item['visitor_type_id'] ?? '').toString();
                                  final categoryName = (item['name'] ?? item['purpose'] ?? 'Visitors').toString();
                                  final initialCount = int.tryParse((item['count'] ?? item['total'] ?? 0).toString());
                                  _showUpcomingVisitorsDialog(
                                    context,
                                    categoryName: categoryName,
                                    categoryId: categoryId,
                                    initialCount: initialCount,
                                  );
                                },
                                child: Container(
                                  width: 135,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: bgColor.withValues(alpha: 0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        label,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        count,
                                        style: GoogleFonts.inter(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
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
  });
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
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
  // Quick Actions Handlers & Modal Dialogs (Matching Screenshots)
  // ─────────────────────────────────────────────────────────────────────────
  void _handleAction(String actionName) {
    final visitor = controller.rxSelectedVisitor.value;
    final rawStatus = (visitor?['visitor_status'] ?? visitor?['status'] ?? '').toString().toLowerCase();
    final isBlocked = visitor?['is_block'] == true ||
        rawStatus == 'block' ||
        rawStatus == 'blacklist';

    if (actionName == 'Scan QR') {
      _showScanQrDialog();
      return;
    }
    if (actionName == 'Extend' || actionName == 'Extend Visit') {
      final isMultiple = controller.rxSelectMultiple.value;
      final hasSelected = isMultiple
          ? controller.rxSelectedItems.isNotEmpty
          : visitor != null;
      if (!hasSelected) {
        AppSnackbar.warning(
          title: 'Warning',
          message: 'Please select a visitor first to extend visit period.',
        );
        return;
      }
      _showExtendVisitDialog(context);
      return;
    }
    if (actionName == 'Check In') {
      if (visitor == null) {
        AppSnackbar.warning(title: 'Warning', message: 'Please select a visitor first.');
        return;
      }
      final isPraregisterDone = visitor['is_praregister_done'] == true;
      final approvalStatus = (visitor['approval_status'] ?? '').toString().toLowerCase();
      final isAvailable = rawStatus.contains('available') || approvalStatus == 'approved';

      // Rule 1: Blocked visitor
      if (isBlocked) {
        _showWarningNoticeDialog(
          context,
          title: 'Action Denied',
          message: 'Cannot check in a blocked visitor. Please unblock first.',
        );
        return;
      }

      final bool isHost = visitor['is_host'] == true || visitor['raw']?['is_host'] == true;

      // Rule 2: Preregis / Form incomplete (only if not Available / Approved and not Host)
      if (!isHost && !isAvailable && (rawStatus.contains('preregis') || rawStatus.contains('praregis') || !isPraregisterDone)) {
        _showWarningNoticeDialog(
          context,
          title: 'Registration Form Required',
          message: 'Please complete the visitor registration form first. The visitor will be automatically checked in upon form completion.',
        );
        return;
      }

      // Rule 3: Waiting / Pending host approval (only if still pending/waiting and not Host)
      if (!isHost && !isAvailable && (rawStatus.contains('waiting') || approvalStatus.contains('pending') || approvalStatus.contains('wait'))) {
        _showWarningNoticeDialog(
          context,
          title: 'Awaiting Host Approval',
          message: 'This visitor is currently awaiting confirmation from the host. Please wait for host approval before checking in.',
        );
        return;
      }

      // Rule 4: Already checked in
      if (rawStatus.contains('checkin') || rawStatus == 'in') {
        _showWarningNoticeDialog(
          context,
          title: 'Already Checked In',
          message: 'Visitor ${visitor['name'] ?? ''} has already completed check in.',
        );
        return;
      }

      _showConfirmationActionDialog(context, action: 'Checkin', question: 'Do you want to check in?');
      return;
    }
    if (actionName == 'Check Out') {
      if (visitor == null) {
        AppSnackbar.warning(title: 'Warning', message: 'Please select a visitor first.');
        return;
      }
      if (isBlocked) {
        _showWarningNoticeDialog(
          context,
          title: 'Action Denied',
          message: 'Cannot check out a blocked visitor. Please unblock first.',
        );
        return;
      }
      if (rawStatus.contains('waiting')) {
        _showWarningNoticeDialog(
          context,
          title: 'Action Denied',
          message: 'Visitor is currently awaiting host confirmation and has not checked in yet. Please wait for approval and check in first.',
        );
        return;
      }
      if (rawStatus.contains('available')) {
        _showWarningNoticeDialog(
          context,
          title: 'Check In Required',
          message: 'Visitor has not checked in yet. Please check in the visitor first before checking out.',
        );
        return;
      }
      if (rawStatus.contains('preregis') || rawStatus.contains('praregis')) {
        _showWarningNoticeDialog(
          context,
          title: 'Check In Required',
          message: 'Visitor has not completed registration or checked in. Please complete registration and check in first.',
        );
        return;
      }
      if (rawStatus.contains('checkout') || rawStatus == 'out') {
        _showWarningNoticeDialog(
          context,
          title: 'Already Checked Out',
          message: 'Visitor ${visitor['name'] ?? ''} has already checked out.',
        );
        return;
      }
      if (!rawStatus.contains('checkin') && !rawStatus.contains('in')) {
        _showWarningNoticeDialog(
          context,
          title: 'Check In Required',
          message: 'Please check in the visitor first before checking out.',
        );
        return;
      }
      _showConfirmationActionDialog(context, action: 'Checkout', question: 'Do you want to check out?');
      return;
    }
    if (actionName == 'Blacklist') {
      if (visitor == null) {
        AppSnackbar.warning(title: 'Warning', message: 'Please select a visitor first.');
        return;
      }
      final rawStatus = (visitor['visitor_status'] ?? visitor['status'] ?? '').toString().toLowerCase();
      if (visitor['is_blacklist'] == true || rawStatus == 'blacklist') {
        _showWarningNoticeDialog(
          context,
          title: 'Already Blacklisted',
          message: 'Visitor ${visitor['name'] ?? ''} is already blacklisted.',
        );
        return;
      }
      _showReasonActionDialog(context, action: 'Blacklist');
      return;
    }
    if (actionName == 'Block') {
      if (visitor == null) {
        AppSnackbar.warning(title: 'Warning', message: 'Please select a visitor first.');
        return;
      }
      if (isBlocked) {
        _showWarningNoticeDialog(
          context,
          title: 'Already Blocked',
          message: 'Visitor ${visitor['name'] ?? ''} is already blocked.',
        );
        return;
      }
      _showReasonActionDialog(context, action: 'Block');
      return;
    }
    if (actionName == 'Card Return' || actionName == 'Return Card') {
      if (visitor == null) {
        AppSnackbar.warning(title: 'Warning', message: 'Please select a visitor first.');
        return;
      }
      _showReturnCardDialog(context, visitor);
      return;
    }
    if (actionName == 'Card Issuance' || actionName == 'Choose Card') {
      if (visitor == null) {
        _showChangeCardDialog(context);
        return;
      }
      _showChooseCardDialog(context);
      return;
    }
    if (actionName == 'Whitelist' || actionName == 'Unblock') {
      if (visitor == null) {
        AppSnackbar.warning(title: 'Warning', message: 'Please select a visitor first.');
        return;
      }
      _showConfirmationActionDialog(context, action: 'Unblock', question: 'Do you want to unblock this visitor?');
      return;
    }
    if (actionName == 'Access Issuance') {
      if (visitor == null) {
        _showScanQrDialog(
          onVisitorLoaded: (loadedVisitor) {
            _showAccessIssuanceDialog(context, loadedVisitor);
          },
        );
        return;
      }
      _showAccessIssuanceDialog(context, visitor);
      return;
    }
    if (actionName == 'Pra Register' ||
        actionName == 'Pra-Register' ||
        actionName == 'Pre Register' ||
        actionName == 'Fill Form') {
      AddPraRegistrationModal.show(context);
      return;
    }
    AppSnackbar.info(
      title: actionName,
      message: 'Processing $actionName for operator terminal...',
    );
  }

  void _showChangeCardDialog(BuildContext context) {
    final oldCardController = TextEditingController();
    final newCardController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasOldCard = oldCardController.text.trim().isNotEmpty;
            final hasNewCard = newCardController.text.trim().isNotEmpty;
            final isReady = hasOldCard || hasNewCard;

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 680,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modal Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Change Card Dialog',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.of(dialogContext).pop(),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                    // Content Body (Two Card Containers with Arrow in center)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. Old Card Box
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Card Illustration / Tap Area
                                  Container(
                                    height: 180,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.contactless_outlined,
                                          size: 54,
                                          color: hasOldCard
                                              ? const Color(0xFF004385)
                                              : const Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Old Card',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Input Field
                                  Container(
                                    height: 42,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: hasOldCard
                                            ? const Color(0xFF005696)
                                            : const Color(0xFFCBD5E1),
                                        width: hasOldCard ? 1.4 : 1.0,
                                      ),
                                    ),
                                    child: Center(
                                      child: TextField(
                                        controller: oldCardController,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1E293B),
                                        ),
                                        textAlignVertical: TextAlignVertical.center,
                                        onChanged: (_) => setDialogState(() {}),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: 'Enter your card',
                                          hintStyle: GoogleFonts.inter(
                                            fontSize: 12.5,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          suffixIcon: Icon(
                                            Icons.check_rounded,
                                            size: 18,
                                            color: hasOldCard
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFCBD5E1),
                                          ),
                                          suffixIconConstraints: const BoxConstraints(
                                            minWidth: 24,
                                            minHeight: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Center Arrow
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 22,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),

                          // 2. New Card Box
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Card Illustration / Tap Area
                                  Container(
                                    height: 180,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.contactless_outlined,
                                          size: 54,
                                          color: hasNewCard
                                              ? const Color(0xFF004385)
                                              : const Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'New Card',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Input Field
                                  Container(
                                    height: 42,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: hasNewCard
                                            ? const Color(0xFF005696)
                                            : const Color(0xFFCBD5E1),
                                        width: hasNewCard ? 1.4 : 1.0,
                                      ),
                                    ),
                                    child: Center(
                                      child: TextField(
                                        controller: newCardController,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1E293B),
                                        ),
                                        textAlignVertical: TextAlignVertical.center,
                                        onChanged: (_) => setDialogState(() {}),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: 'Enter new card number',
                                          hintStyle: GoogleFonts.inter(
                                            fontSize: 12.5,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          suffixIcon: Icon(
                                            Icons.check_rounded,
                                            size: 18,
                                            color: hasNewCard
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFCBD5E1),
                                          ),
                                          suffixIconConstraints: const BoxConstraints(
                                            minWidth: 24,
                                            minHeight: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Action Buttons (Swipe & Give)
                    Padding(
                      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
                      child: Row(
                        children: [
                          // Swipe Button
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isReady
                                      ? const Color(0xFFFFA000)
                                      : const Color(0xFFE2E8F0),
                                  foregroundColor: isReady
                                      ? Colors.white
                                      : const Color(0xFF94A3B8),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: isReady
                                    ? () {
                                        final oldCard = oldCardController.text.trim();
                                        final newCard = newCardController.text.trim();
                                        AppSnackbar.info(
                                          title: 'Card Reader (Swipe)',
                                          message: 'Ready for API reader integration (Old: $oldCard, New: $newCard)',
                                        );
                                      }
                                    : null,
                                child: Text(
                                  'Swipe',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isReady
                                        ? Colors.white
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Give Button
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isReady
                                      ? const Color(0xFF004385)
                                      : const Color(0xFFE2E8F0),
                                  foregroundColor: isReady
                                      ? Colors.white
                                      : const Color(0xFF94A3B8),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: isReady
                                    ? () {
                                        final oldCard = oldCardController.text.trim();
                                        final newCard = newCardController.text.trim();
                                        AppSnackbar.info(
                                          title: 'Card Reader (Give)',
                                          message: 'Ready for API reader integration (Old: $oldCard, New: $newCard)',
                                        );
                                      }
                                    : null,
                                child: Text(
                                  'Give',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isReady
                                        ? Colors.white
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showChooseCardDialog(BuildContext context) {
    controller.fetchAvailableCards();
    final visitor = controller.rxSelectedVisitor.value;
    final visitorName = (visitor?['name'] ?? visitor?['visitor_name'] ?? 'Visitor').toString();

    // Determine if multiple visitors are selected
    final isMultiple = controller.rxSelectMultiple.value && controller.rxSelectedItems.isNotEmpty;
    final selectedSet = controller.rxSelectedItems.toSet();
    final targetVisitors = isMultiple
        ? controller.rxRelatedVisitors.where((r) {
            final keys = [
              r['id'],
              r['trx_id'],
              r['transaction_visitor_id'],
              r['visitor_id'],
              r['invitation_code'],
              r['visitor_code'],
              r['visitor_number'],
              r['name'],
              r['visitor_name'],
            ].where((k) => k != null && k.toString().trim().isNotEmpty).map((k) => k.toString().trim()).toList();
            return keys.any((k) => selectedSet.contains(k));
          }).toList()
        : (visitor != null ? [visitor] : <Map<String, dynamic>>[]);
    final int maxAllowedCards = targetVisitors.isNotEmpty
        ? targetVisitors.length
        : (isMultiple ? controller.rxSelectedItems.length : 1);

    // Resolve current cards for all targeted visitors (Single and Multiple)
    // Resolve current cards for all targeted visitors (Single and Multiple)
    final List<Map<String, dynamic>> targetVisitorCurrentCards = [];
    for (final v in targetVisitors) {
      final vName = (v['name'] ?? v['visitor_name'] ?? 'Visitor').toString();
      final vCards = (v['cards'] as List?) ?? (v['card'] as List?) ?? [];
      Map<String, dynamic>? activePhysicalCard;
      if (vCards.isNotEmpty) {
        activePhysicalCard = vCards.firstWhereOrNull((c) {
          final isCurrentUsed = (c['current_used'] == true);
          final cardType = (c['card_type'] ?? c['type'] ?? '').toString().toLowerCase();
          final isBarcode = cardType == 'barcode' || cardType == 'qrcode' || cardType == 'qr';
          final status = (c['card_status'] ?? '').toString().toLowerCase();
          final isReturned = status == 'returned' || status == 'inactive' || status == 'revoked';
          return isCurrentUsed && !isBarcode && !isReturned;
        });
      }
      targetVisitorCurrentCards.add({
        'visitor': v,
        'visitorName': vName,
        'card': activePhysicalCard,
      });
    }

    // Fallback if targetVisitorCurrentCards is empty and visitor is selected
    if (targetVisitorCurrentCards.isEmpty && visitor != null) {
      final visitorCards = (visitor['cards'] as List?) ?? (visitor['card'] as List?) ?? [];
      Map<String, dynamic>? activePhysicalCard;
      if (visitorCards.isNotEmpty) {
        activePhysicalCard = visitorCards.firstWhereOrNull((c) {
          final isCurrentUsed = (c['current_used'] == true);
          final cardType = (c['card_type'] ?? c['type'] ?? '').toString().toLowerCase();
          final isBarcode = cardType == 'barcode' || cardType == 'qrcode' || cardType == 'qr';
          final status = (c['card_status'] ?? '').toString().toLowerCase();
          final isReturned = status == 'returned' || status == 'inactive' || status == 'revoked';
          return isCurrentUsed && !isBarcode && !isReturned;
        });
      }
      targetVisitorCurrentCards.add({
        'visitor': visitor,
        'visitorName': visitorName,
        'card': activePhysicalCard,
      });
    }

    final searchController = TextEditingController();
    final cardScrollController = ScrollController();
    String searchQuery = '';
    final Set<String> selectedCardIds = <String>{};
    bool isSelectAll = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Container(
                width: 960,
                height: MediaQuery.of(context).size.height * 0.88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header (Title + Close Button)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Choose Card',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                tooltip: 'Refresh cards',
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 20,
                                  color: Color(0xFF003082),
                                ),
                                onPressed: () async {
                                  await controller.fetchAvailableCards();
                                  AppSnackbar.success(
                                    title: 'Cards Refreshed',
                                    message: 'Available card list is up to date.',
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: Color(0xFF64748B),
                                ),
                                onPressed: () => Navigator.of(dialogContext).pop(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                    // Search and Select All row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Box (Numeric only, with perfectly aligned icon & text)
                          Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Center(
                              child: TextField(
                                controller: searchController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF1E293B),
                                ),
                                textAlignVertical: TextAlignVertical.center,
                                onChanged: (val) {
                                  setDialogState(() {
                                    searchQuery = val.trim();
                                  });
                                },
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: 'Search card number (e.g. 133, 3232)...',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    size: 18,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 38,
                                    minHeight: 38,
                                  ),
                                  suffixIcon: searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.cancel_rounded,
                                            size: 16,
                                            color: Color(0xFF94A3B8),
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 38),
                                          onPressed: () {
                                            setDialogState(() {
                                              searchController.clear();
                                              searchQuery = '';
                                            });
                                          },
                                        )
                                      : null,
                                  suffixIconConstraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 38,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Select All Checkbox Row
                          InkWell(
                            onTap: () {
                              setDialogState(() {
                                isSelectAll = !isSelectAll;
                                if (isSelectAll) {
                                  final allCards = controller.rxAvailableCards;
                                  final filteredCards = allCards.where((c) {
                                    if (searchQuery.isEmpty) return true;
                                    final numStr = (c['card_number'] ?? '').toString().replaceAll(' ', '');
                                    final barcodeStr = (c['card_barcode'] ?? '').toString().replaceAll(' ', '');
                                    final macStr = (c['card_mac'] ?? '').toString().replaceAll(' ', '');
                                    final remarksStr = (c['remarks'] ?? '').toString().replaceAll(' ', '');
                                    return numStr.contains(searchQuery) ||
                                        barcodeStr.contains(searchQuery) ||
                                        macStr.contains(searchQuery) ||
                                        remarksStr.contains(searchQuery);
                                  }).toList();

                                  final unusedCards = filteredCards.where((c) => c['is_used'] != true).toList();
                                  selectedCardIds.clear();
                                  if (unusedCards.isNotEmpty) {
                                    final random = Random();
                                    final shuffled = List<Map<String, dynamic>>.from(unusedCards)..shuffle(random);
                                    final pickCount = shuffled.length < maxAllowedCards ? shuffled.length : maxAllowedCards;
                                    final pickedList = shuffled.take(pickCount).toList();

                                    for (final c in pickedList) {
                                      final cId = (c['id'] ?? c['card_number'] ?? '').toString();
                                      if (cId.isNotEmpty) selectedCardIds.add(cId);
                                    }

                                    // Smoothly drag / scroll down sequentially to each chosen card
                                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                                      final baseOffset = targetVisitorCurrentCards.isNotEmpty ? 260.0 : 0.0;
                                      const rowHeight = 220.0;

                                      for (int i = 0; i < pickedList.length; i++) {
                                        if (!cardScrollController.hasClients) break;
                                        final card = pickedList[i];
                                        final pickedIndex = filteredCards.indexOf(card);
                                        if (pickedIndex != -1) {
                                          final rowIndex = pickedIndex ~/ 4;
                                          final targetOffset = (baseOffset + (rowIndex * rowHeight) - 20.0).clamp(
                                            0.0,
                                            cardScrollController.position.maxScrollExtent,
                                          );
                                          await cardScrollController.animateTo(
                                            targetOffset,
                                            duration: const Duration(milliseconds: 600),
                                            curve: Curves.easeInOutCubic,
                                          );
                                          // If multiple cards, pause briefly so operator sees each highlighted card
                                          if (i < pickedList.length - 1) {
                                            await Future.delayed(const Duration(milliseconds: 650));
                                          }
                                        }
                                      }
                                    });
                                  } else {
                                    isSelectAll = false;
                                    AppSnackbar.info(
                                      title: 'Notice',
                                      message: 'No available unused cards to choose.',
                                    );
                                  }
                                } else {
                                  selectedCardIds.clear();
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (cardScrollController.hasClients) {
                                      cardScrollController.animateTo(
                                        0.0,
                                        duration: const Duration(milliseconds: 350),
                                        curve: Curves.easeOutCubic,
                                      );
                                    }
                                  });
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 17,
                                    height: 17,
                                    decoration: BoxDecoration(
                                      color: isSelectAll ? const Color(0xFF003082) : Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isSelectAll
                                            ? const Color(0xFF003082)
                                            : const Color(0xFF94A3B8),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelectAll
                                        ? const Center(
                                            child: Icon(
                                              Icons.check_rounded,
                                              size: 13,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Select All',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content Scroll Area
                    Expanded(
                      child: Obx(() {
                        if (controller.rxIsAvailableCardsLoading.value && controller.rxAvailableCards.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF003082),
                            ),
                          );
                        }

                        final allCards = controller.rxAvailableCards;
                        final filteredCards = allCards.where((c) {
                          if (searchQuery.isEmpty) return true;
                          final numStr = (c['card_number'] ?? '').toString().replaceAll(' ', '');
                          final barcodeStr = (c['card_barcode'] ?? '').toString().replaceAll(' ', '');
                          final macStr = (c['card_mac'] ?? '').toString().replaceAll(' ', '');
                          final remarksStr = (c['remarks'] ?? '').toString().replaceAll(' ', '');
                          return numStr.contains(searchQuery) ||
                              barcodeStr.contains(searchQuery) ||
                              macStr.contains(searchQuery) ||
                              remarksStr.contains(searchQuery);
                        }).toList();

                        return ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                              PointerDeviceKind.stylus,
                              PointerDeviceKind.trackpad,
                            },
                          ),
                          child: SingleChildScrollView(
                            controller: cardScrollController,
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── 1. Current Card Section (Single & Multiple) ─────────────────────────
                                if (targetVisitorCurrentCards.isNotEmpty) ...[
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    children: targetVisitorCurrentCards.map((item) {
                                      final vName = item['visitorName'] as String;
                                      final c = item['card'] as Map<String, dynamic>?;

                                      if (c == null) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Text(
                                            'Current Card – $vName',
                                            style: GoogleFonts.inter(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFFFA000),
                                            ),
                                          ),
                                        );
                                      }

                                      final cId = (c['id'] ?? c['card_number']).toString();
                                      final isSelected = selectedCardIds.contains(cId);

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Current Card – $vName',
                                            style: GoogleFonts.inter(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFFFA000),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          _buildCurrentCardWidget(
                                            currentCard: c,
                                            visitorName: vName,
                                            isSelected: isSelected,
                                            onTap: () {
                                              setDialogState(() {
                                                if (selectedCardIds.contains(cId)) {
                                                  selectedCardIds.remove(cId);
                                                  isSelectAll = false;
                                                } else {
                                                  if (maxAllowedCards == 1) {
                                                    selectedCardIds.clear();
                                                    selectedCardIds.add(cId);
                                                  } else {
                                                    if (selectedCardIds.length < maxAllowedCards) {
                                                      selectedCardIds.add(cId);
                                                    } else {
                                                      AppSnackbar.warning(
                                                        title: 'Limit Reached',
                                                        message: 'Maximum $maxAllowedCards cards allowed for the selected visitors.',
                                                      );
                                                    }
                                                  }
                                                  isSelectAll = selectedCardIds.length >= maxAllowedCards;
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                                  const SizedBox(height: 16),
                                ],

                                // ── 2. All Available Cards Grid ─────────────────────────
                                if (filteredCards.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 40),
                                      child: Text(
                                        searchQuery.isNotEmpty
                                            ? 'No card found matching "$searchQuery"'
                                            : 'No available cards',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      return GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: filteredCards.length,
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 4,
                                          crossAxisSpacing: 14,
                                          mainAxisSpacing: 14,
                                          childAspectRatio: 0.95,
                                        ),
                                        itemBuilder: (context, index) {
                                          final card = filteredCards[index];
                                          final cardId = (card['id'] ?? card['card_number'] ?? 'card_$index').toString();
                                          final isSelected = selectedCardIds.contains(cardId);

                                          return _buildAvailableCardItem(
                                            card: card,
                                            isSelected: isSelected,
                                            onTap: () {
                                              if (card['is_used'] == true) return;
                                              setDialogState(() {
                                                if (selectedCardIds.contains(cardId)) {
                                                  selectedCardIds.remove(cardId);
                                                  isSelectAll = false;
                                                } else {
                                                  if (maxAllowedCards == 1) {
                                                    selectedCardIds.clear();
                                                    selectedCardIds.add(cardId);
                                                  } else {
                                                    if (selectedCardIds.length < maxAllowedCards) {
                                                      selectedCardIds.add(cardId);
                                                    } else {
                                                      AppSnackbar.warning(
                                                        title: 'Limit Reached',
                                                        message: 'Maximum $maxAllowedCards cards allowed for the selected visitors.',
                                                      );
                                                    }
                                                  }
                                                  isSelectAll = selectedCardIds.length >= maxAllowedCards;
                                                }
                                              });
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),

                    // Cards chosen counter text
                    Obx(() {
                      final totalCards = controller.rxAvailableCards.length;
                      final chosenCount = selectedCardIds.length;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Text(
                          'Cards chosen: $chosenCount / $totalCards  Maximum cards allowed: $maxAllowedCards',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      );
                    }),

                    // Bottom Buttons Bar (Swipe & Give)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          // Swipe Button (Yellow/Amber)
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFA000),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: () async {
                                  if (selectedCardIds.isEmpty || selectedCardIds.length < maxAllowedCards) {
                                    AppSnackbar.warning(
                                      title: 'Card Required',
                                      message: maxAllowedCards > 1
                                          ? 'Please choose $maxAllowedCards cards for the $maxAllowedCards selected visitors.'
                                          : 'Please choose a card first.',
                                    );
                                    return;
                                  }

                                  final allCards = controller.rxAvailableCards;
                                  final pickedCardsList = allCards.where(
                                    (c) => selectedCardIds.contains((c['id'] ?? c['card_number']).toString()),
                                  ).toList();

                                  await _showSwipeCardModal(
                                    context: context,
                                    parentDialogContext: dialogContext,
                                    targetVisitors: targetVisitors,
                                    selectedCardsList: pickedCardsList,
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.credit_card_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Swipe',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Give Button (Brand Blue)
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF004385),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: () async {
                                  if (selectedCardIds.isEmpty || selectedCardIds.length < maxAllowedCards) {
                                    AppSnackbar.warning(
                                      title: 'Card Required',
                                      message: maxAllowedCards > 1
                                          ? 'Please choose $maxAllowedCards cards for the $maxAllowedCards selected visitors.'
                                          : 'Please choose a card first.',
                                    );
                                    return;
                                  }

                                  final allCards = controller.rxAvailableCards;
                                  final pickedCardsList = allCards.where(
                                    (c) => selectedCardIds.contains((c['id'] ?? c['card_number']).toString()),
                                  ).toList();

                                  if (maxAllowedCards > 1) {
                                    final items = <Map<String, dynamic>>[];
                                    for (int i = 0; i < targetVisitors.length; i++) {
                                      final v = targetVisitors[i];
                                      final c = (i < pickedCardsList.length) ? pickedCardsList[i] : pickedCardsList.first;
                                      final cardNum = (c['card_number'] ?? c['card_barcode'] ?? c['card_mac'] ?? '').toString().trim();
                                      items.add({
                                        'visitor': v,
                                        'card_number': cardNum,
                                        'trx_visitor_id': (v['id'] ?? v['transaction_visitor_id'] ?? '').toString().trim(),
                                      });
                                    }
                                    final success = await controller.grantAccessCardMultiple(
                                      items: items,
                                      isSwapCard: false,
                                    );
                                    if (success && dialogContext.mounted) {
                                      Navigator.of(dialogContext).pop();
                                    }
                                  } else {
                                    final pickedCard = pickedCardsList.isNotEmpty ? pickedCardsList.first : null;
                                    final cardNum = (pickedCard?['card_number'] ??
                                            pickedCard?['card_barcode'] ??
                                            pickedCard?['card_mac'] ??
                                            selectedCardIds.first)
                                        .toString()
                                        .trim();

                                    final success = await controller.grantAccessCard(
                                      cardNumber: cardNum,
                                      selectedCard: pickedCard,
                                    );

                                    if (success && dialogContext.mounted) {
                                      Navigator.of(dialogContext).pop();
                                    }
                                  }
                                },
                                child: Obx(() {
                                  final isLoading = controller.rxIsActionLoading.value;
                                  if (isLoading) {
                                    return const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    );
                                  }
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.style_outlined,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Give',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSwipeCardModal({
    required BuildContext context,
    required BuildContext parentDialogContext,
    required List<Map<String, dynamic>> targetVisitors,
    required List<Map<String, dynamic>> selectedCardsList,
  }) async {
    if (targetVisitors.isEmpty) return;

    int currentStep = 0;
    final totalSteps = targetVisitors.length;

    // Helper functions
    String mapSwapTypeToApi(String displayType) {
      switch (displayType) {
        case 'NIK':
          return 'NIK';
        case 'KTP':
          return 'KTP';
        case 'Driver License':
          return 'DriverLicense';
        case 'Passport':
          return 'Passport';
        case 'Card Access':
          return 'CardAccess';
        case 'Face ID':
          return 'Face';
        case 'NDA':
          return 'NDA';
        case 'Other':
        default:
          return 'Other';
      }
    }

    String getFieldLabel(String type) {
      switch (type) {
        case 'KTP':
          return 'No KTP';
        case 'NIK':
          return 'NIK';
        case 'Passport':
          return 'Passport';
        case 'Driver License':
          return 'Driver License';
        case 'Card Access':
          return 'Card Access';
        case 'Face ID':
          return 'Face ID';
        case 'NDA':
          return 'NDA';
        case 'Other':
        default:
          return 'Other';
      }
    }

    final typeOptions = [
      'NIK',
      'KTP',
      'Passport',
      'Driver License',
      'Card Access',
      'Face ID',
      'NDA',
      'Other',
    ];

    // Initialize state per visitor
    final List<Map<String, dynamic>> stepStates = targetVisitors.map((v) {
      final visitorCards = (v['card'] as List?) ?? (v['cards'] as List?) ?? [];

      Map<String, dynamic>? activeCard;
      if (visitorCards.isNotEmpty) {
        activeCard = visitorCards.firstWhereOrNull((c) {
          final isCurrentUsed = (c['current_used'] == true);
          final cardType = (c['card_type'] ?? c['type'] ?? '').toString().toLowerCase();
          final isBarcode = cardType == 'barcode' || cardType == 'qrcode' || cardType == 'qr';
          final status = (c['card_status'] ?? '').toString().toLowerCase();
          final isReturned = status == 'returned' || status == 'inactive' || status == 'revoked';
          return isCurrentUsed && !isBarcode && !isReturned;
        });
      }

      String defaultCardNum = '';
      if (activeCard != null) {
        defaultCardNum = (activeCard['card_number'] ?? activeCard['card_barcode'] ?? '').toString().trim();
      }
      if (defaultCardNum.isEmpty) {
        defaultCardNum = (v['visitor_card'] ??
                v['visitor_code'] ??
                v['visitor_ble_card'] ??
                v['identity_id'] ??
                '')
            .toString()
            .trim();
      }

      final identityId = (v['identity_id'] ??
              v['id_number'] ??
              v['visitor_identity_id'] ??
              '')
            .toString()
            .trim();

      final bool isTypeLocked = activeCard != null;
      String initialType = 'Card Access';
      if (activeCard != null) {
        final rawSwapType = (activeCard['swap_type'] ?? activeCard['type'] ?? activeCard['card_type'] ?? '').toString().trim();
        if (rawSwapType.isNotEmpty) {
          if (rawSwapType.toLowerCase().contains('ktp')) {
            initialType = 'KTP';
          } else if (rawSwapType.toLowerCase().contains('nik')) {
            initialType = 'NIK';
          } else if (rawSwapType.toLowerCase().contains('passport')) {
            initialType = 'Passport';
          } else if (rawSwapType.toLowerCase().contains('driver')) {
            initialType = 'Driver License';
          } else if (rawSwapType.toLowerCase().contains('face')) {
            initialType = 'Face ID';
          } else if (rawSwapType.toLowerCase().contains('nda')) {
            initialType = 'NDA';
          } else if (rawSwapType.toLowerCase().contains('card')) {
            initialType = 'Card Access';
          } else {
            initialType = 'Card Access';
          }
        }
      }

      return {
        'visitor': v,
        'selectedType': initialType,
        'controller': TextEditingController(text: defaultCardNum),
        'defaultCardNum': defaultCardNum,
        'identityId': identityId,
        'isTypeLocked': isTypeLocked,
      };
    }).toList();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (swipeDialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentItem = stepStates[currentStep];
            final currentVisitor = currentItem['visitor'] as Map<String, dynamic>;
            final currentVisitorName = (currentVisitor['visitor_name'] ?? currentVisitor['name'] ?? 'Visitor').toString();
            final isLastStep = currentStep == totalSteps - 1;
            final isTypeLocked = currentItem['isTypeLocked'] == true;
            final inputController = currentItem['controller'] as TextEditingController;
            final selectedType = currentItem['selectedType'] as String;
            final identityId = currentItem['identityId'] as String;
            final defaultCardNum = currentItem['defaultCardNum'] as String;

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: 440,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header (Swipe Card + Close Button)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Swipe Card',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.of(swipeDialogContext).pop(),
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                    // Content Body
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Visitor count & name
                          Text(
                            'Visitor ${currentStep + 1} / $totalSteps',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentVisitorName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Manual Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF005696),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Manual',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Type Label
                          Text(
                            'Type',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Type Dropdown Box
                          isTypeLocked
                              ? Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFCBD5E1),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Card Access',
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          color: const Color(0xFF94A3B8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ],
                                  ),
                                )
                              : Theme(
                                  data: Theme.of(context).copyWith(
                                    cardColor: Colors.white,
                                    popupMenuTheme: PopupMenuThemeData(
                                      color: Colors.white,
                                      surfaceTintColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                      elevation: 6,
                                    ),
                                  ),
                                  child: PopupMenuButton<String>(
                                    offset: const Offset(0, 46),
                                    color: Colors.white,
                                    surfaceTintColor: Colors.white,
                                    constraints: const BoxConstraints(
                                      minWidth: 400,
                                      maxWidth: 400,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    elevation: 6,
                                    onSelected: (newVal) {
                                      setModalState(() {
                                        currentItem['selectedType'] = newVal;
                                        if ((newVal == 'NIK' || newVal == 'KTP') && identityId.isNotEmpty) {
                                          inputController.text = identityId;
                                        } else if (newVal == 'Card Access' && defaultCardNum.isNotEmpty) {
                                          inputController.text = defaultCardNum;
                                        }
                                      });
                                    },
                                    itemBuilder: (context) {
                                      return typeOptions.map((type) {
                                        final isItemPicked = type == selectedType;
                                        return PopupMenuItem<String>(
                                          value: type,
                                          height: 38,
                                          padding: EdgeInsets.zero,
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: isItemPicked ? const Color(0xFFCFE2FF) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              type,
                                              style: GoogleFonts.inter(
                                                fontSize: 13.5,
                                                color: const Color(0xFF1E293B),
                                                fontWeight: isItemPicked ? FontWeight.w600 : FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList();
                                    },
                                    child: Container(
                                      height: 42,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFF005696),
                                          width: 1.4,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            selectedType,
                                            style: GoogleFonts.inter(
                                              fontSize: 13.5,
                                              color: const Color(0xFF1E293B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_drop_down,
                                            color: Color(0xFF64748B),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 16),

                          // Dynamic Field Label
                          Text(
                            getFieldLabel(selectedType),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Dynamic Value Input Field
                          Container(
                            height: 42,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 1.2,
                              ),
                            ),
                            child: TextField(
                              controller: inputController,
                              textAlignVertical: TextAlignVertical.center,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                height: 1.2,
                                color: const Color(0xFF1E293B),
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Action Button (Next or Swipe)
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF005696),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: () async {
                                if (!isLastStep) {
                                  setModalState(() {
                                    currentStep++;
                                  });
                                } else {
                                  // Final step: Execute Swipe
                                  if (totalSteps > 1) {
                                    final items = <Map<String, dynamic>>[];
                                    for (int i = 0; i < totalSteps; i++) {
                                      final s = stepStates[i];
                                      final v = s['visitor'] as Map<String, dynamic>;
                                      final c = (i < selectedCardsList.length) ? selectedCardsList[i] : selectedCardsList.first;
                                      final cardNum = (c['card_number'] ?? c['card_barcode'] ?? c['card_mac'] ?? '').toString().trim();
                                      final customSwapFrom = (s['controller'] as TextEditingController).text.trim();
                                      final sType = mapSwapTypeToApi(s['selectedType'] as String);

                                      items.add({
                                        'visitor': v,
                                        'card_number': cardNum,
                                        'trx_visitor_id': (v['id'] ?? v['transaction_visitor_id'] ?? '').toString().trim(),
                                        'swap_card_from_card': customSwapFrom,
                                        'swap_type': sType,
                                      });
                                    }

                                    final success = await controller.grantAccessCardMultiple(
                                      items: items,
                                      isSwapCard: true,
                                    );

                                    if (success) {
                                      if (swipeDialogContext.mounted) {
                                        Navigator.of(swipeDialogContext).pop();
                                      }
                                      if (parentDialogContext.mounted) {
                                        Navigator.of(parentDialogContext).pop();
                                      }
                                    }
                                  } else {
                                    // Single Visitor Swipe
                                    final pickedCard = selectedCardsList.isNotEmpty ? selectedCardsList.first : null;
                                    final newCardNumber = (pickedCard?['card_number'] ??
                                            pickedCard?['card_barcode'] ??
                                            pickedCard?['card_mac'] ??
                                            '')
                                        .toString()
                                        .trim();
                                    final customSwapFrom = inputController.text.trim();
                                    final apiSwapType = mapSwapTypeToApi(selectedType);

                                    final success = await controller.grantAccessCard(
                                      cardNumber: newCardNumber,
                                      selectedCard: pickedCard,
                                      isSwapCard: true,
                                      swapType: apiSwapType,
                                      customSwapCardFrom: customSwapFrom,
                                    );

                                    if (success) {
                                      if (swipeDialogContext.mounted) {
                                        Navigator.of(swipeDialogContext).pop();
                                      }
                                      if (parentDialogContext.mounted) {
                                        Navigator.of(parentDialogContext).pop();
                                      }
                                    }
                                  }
                                }
                              },
                              child: Obx(() {
                                final isLoading = controller.rxIsActionLoading.value;
                                if (isLoading && isLastStep) {
                                  return const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  );
                                }
                                return Text(
                                  !isLastStep ? 'Next (${currentStep + 1}/$totalSteps)' : 'Swipe',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCurrentCardWidget({
    required Map<String, dynamic> currentCard,
    required String visitorName,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final cardNum = (currentCard['card_number'] ?? currentCard['card_barcode'] ?? '-').toString();
    final cardType = (currentCard['card_type'] ?? currentCard['type'] ?? 'BLE').toString();
    final cardMac = (currentCard['card_mac'] ?? currentCard['card_barcode'] ?? cardNum).toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9EE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFA000),
              width: 1.6,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large number
              Text(
                cardNum,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              // Card number row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Card',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cardNum,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      if (cardNum.isNotEmpty && cardNum != '-') ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: cardNum));
                            AppSnackbar.success(
                              title: 'Card Copied',
                              message: 'Card number $cardNum copied to clipboard.',
                            );
                          },
                          child: const Icon(
                            Icons.copy_rounded,
                            size: 12,
                            color: Color(0xFF004385),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // BLE / Type row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cardType,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    cardMac,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Visitor Name
              Text(
                visitorName,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                '(Current Card)',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFA000),
                ),
              ),
              const SizedBox(height: 8),
              // Checkbox indicator
              Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF003082) : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF003082) : const Color(0xFF94A3B8),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableCardItem({
    required Map<String, dynamic> card,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final remarks = (card['remarks'] ?? '').toString().trim();
    final name = (card['name'] ?? '').toString().trim();
    final cardNum = (card['card_number'] ?? '-').toString().trim();
    final cardType = (card['type'] ?? 'BLE').toString().trim();
    final cardMac = (card['card_mac'] ?? card['card_barcode'] ?? '-').toString().trim();
    final isUsed = card['is_used'] == true;

    // Display title
    String displayTitle = remarks.isNotEmpty
        ? remarks
        : (name.isNotEmpty ? name : (cardNum != '-' ? 'CARD $cardNum' : 'Card'));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUsed ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUsed
                ? const Color(0xFFF1F5F9)
                : (isSelected ? const Color(0xFFF0F7FF) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUsed
                  ? const Color(0xFFCBD5E1)
                  : (isSelected ? const Color(0xFF003082) : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.8 : 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top row: Used badge (if is_used == true)
              Align(
                alignment: Alignment.topLeft,
                child: isUsed
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF94A3B8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Used',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const SizedBox(height: 16),
              ),

              // Center Large Title
              Text(
                displayTitle,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isUsed ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),

              // Card details (Card / BLE or Type)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Card',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isUsed ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          cardNum.isNotEmpty ? cardNum : '-',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isUsed ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cardType,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isUsed ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          cardMac.isNotEmpty ? cardMac : '-',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isUsed ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom card name
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isUsed ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Bottom Checkbox
              Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: isUsed
                      ? const Color(0xFFE2E8F0)
                      : (isSelected ? const Color(0xFF003082) : Colors.white),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isUsed
                        ? const Color(0xFFCBD5E1)
                        : (isSelected ? const Color(0xFF003082) : const Color(0xFF94A3B8)),
                    width: 1.5,
                  ),
                ),
                child: isSelected && !isUsed
                    ? const Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReturnCardDialog(
    BuildContext context,
    Map<String, dynamic>? visitor,
  ) {
    final cardNumberController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Title + Close button)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Return Card',
                        style: GoogleFonts.inter(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                // Body: Card Number field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Card Number',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: cardNumberController,
                        autofocus: true,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter card number...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Color(0xFF004385), width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Color(0xFF004385), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Color(0xFF004385), width: 1.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                // Bottom Action Buttons (Cancel / Submit)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF004385),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF004385),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004385),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          onPressed: () {
                            final cardNum = cardNumberController.text.trim();
                            if (cardNum.isEmpty) {
                              AppSnackbar.warning(
                                title: 'Card Number Required',
                                message: 'Please enter card number to return.',
                              );
                              return;
                            }
                            Navigator.of(dialogContext).pop();
                            controller.returnAccessCard(cardNumber: cardNum);
                          },
                          child: Text(
                            'Submit',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConfirmationActionDialog(
    BuildContext context, {
    required String action,
    required String question,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top right red 'X' button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: Colors.red,
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ),
                ),

                // Circle Icon with green border
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF86EFAC),
                      width: 2.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 38,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Question Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    question,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Action Buttons (Cancel / Yes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 88,
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A6A80),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 88,
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            controller.performOperatorInvitationAction(action: action);
                          },
                          child: Text(
                            'Yes',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReasonActionDialog(
    BuildContext context, {
    required String action,
  }) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final isBlacklist = action.toLowerCase() == 'blacklist';
        final isBlock = action.toLowerCase() == 'block';

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: 360,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top right red 'X' button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: Colors.red,
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ),
                ),

                // Icon in circle with amber/orange border
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFED7AA),
                      width: 2.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.priority_high_rounded,
                      size: 38,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  isBlacklist
                      ? 'Blacklist Visitor'
                      : (isBlock ? 'Block Visitor' : 'Action Reason'),
                  style: GoogleFonts.inter(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    isBlacklist
                        ? 'Please provide a reason for blacklisting this visitor:'
                        : (isBlock
                            ? 'Please provide a reason for blocking this visitor:'
                            : 'Please provide a reason for this action:'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Reason TextField
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: reasonController,
                    autofocus: true,
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B)),
                    decoration: InputDecoration(
                      hintText: 'Enter reason...',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFF004385), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons (Cancel / Yes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 88,
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A6A80),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 88,
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () {
                            final reasonText = reasonController.text.trim();
                            if (reasonText.isEmpty) {
                              AppSnackbar.warning(
                                title: 'Reason Required',
                                message: 'Please provide a reason to continue.',
                              );
                              return;
                            }
                            Navigator.of(dialogContext).pop();
                            if (isBlacklist) {
                              controller.blacklistVisitor(reason: reasonText);
                            } else {
                              controller.performOperatorInvitationAction(
                                action: action,
                                reason: reasonText,
                              );
                            }
                          },
                          child: Text(
                            'Yes',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWarningNoticeDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: 330,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top right red 'X' button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: Colors.red,
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ),
                ),

                // Icon in circle with amber/orange border
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFED7AA),
                      width: 2.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.priority_high_rounded,
                      size: 38,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),

                // Message Body
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // OK Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SizedBox(
                    width: 96,
                    height: 34,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(
                        'OK',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showScanQrDialog({
    void Function(Map<String, dynamic> loadedVisitor)? onVisitorLoaded,
  }) {
    int tabMode = 0; // 0: Manual, 1: Scan Camera
    final searchInputController = TextEditingController();
    bool isSearching = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 24,
            ),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Title + Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scan QR Visitor',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: Color(0xFF64748B),
                        ),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tab Switchers (Manual vs Scan Camera)
                  Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setModalState(() => tabMode = 0),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: tabMode == 0
                                  ? const Color(0xFF004385)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: tabMode == 0
                                    ? const Color(0xFF004385)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.text_fields_rounded,
                                  size: 15,
                                  color: tabMode == 0
                                      ? Colors.white
                                      : const Color(0xFF004385),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Manual',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: tabMode == 0
                                        ? Colors.white
                                        : const Color(0xFF004385),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setModalState(() => tabMode = 1),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: tabMode == 1
                                  ? const Color(0xFF004385)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: tabMode == 1
                                    ? const Color(0xFF004385)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.photo_camera_outlined,
                                  size: 15,
                                  color: tabMode == 1
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Scan Camera',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: tabMode == 1
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mode 0: Manual Input
                  if (tabMode == 0) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF004385),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      child: TextField(
                        controller: searchInputController,
                        autofocus: true,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          UpperCaseTextFormatter(),
                        ],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                        decoration: const InputDecoration(
                          hintText:
                              'Enter Invitation Code (e.g. 15Y1H5-QR5FHL)',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (val) async {
                          final code = searchInputController.text.trim().toUpperCase();
                          if (code.isEmpty) return;
                          setModalState(() => isSearching = true);
                          final success = await controller.searchInvitationCode(
                            code,
                          );
                          setModalState(() => isSearching = false);
                          if (success) {
                            Get.back();
                            final loaded = controller.rxSelectedVisitor.value;
                            if (loaded != null && onVisitorLoaded != null) {
                              onVisitorLoaded(loaded);
                            }
                            AppSnackbar.success(
                              title: 'Success',
                              message: 'Data retrieved successfully',
                            );
                          } else {
                            AppSnackbar.error(
                              title: 'Search Failed',
                              message:
                                  'No visitor data found for invitation code: $code',
                            );
                          }
                        },
                      ),
                    ),
                  ] else ...[
                    // Mode 1: Camera Scanner
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: MobileScanner(
                        onDetect: (capture) async {
                          final barcodes = capture.barcodes;
                          for (final b in barcodes) {
                            final code = b.rawValue?.trim().toUpperCase() ?? '';
                            if (code.isNotEmpty) {
                              setModalState(() => isSearching = true);
                              final success = await controller
                                  .searchInvitationCode(code);
                              setModalState(() => isSearching = false);
                              if (success) {
                                Get.back();
                                final loaded = controller.rxSelectedVisitor.value;
                                if (loaded != null && onVisitorLoaded != null) {
                                  onVisitorLoaded(loaded);
                                }
                                AppSnackbar.success(
                                  title: 'Success',
                                  message: 'Data retrieved successfully',
                                );
                              }
                              break;
                            }
                          }
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Footer: [New Invitation] (Left) & [Submit] (Right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004385),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        icon: const Icon(
                          Icons.person_outline_rounded,
                          size: 16,
                        ),
                        label: Text(
                          'New Invitation',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          Get.back();
                          _handleAction('New Invitation');
                        },
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004385),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                        ),
                        onPressed: isSearching
                            ? null
                            : () async {
                                final code = searchInputController.text.trim().toUpperCase();
                                if (code.isEmpty) {
                                  AppSnackbar.error(
                                    title: 'Validation Error',
                                    message: 'Please enter an invitation code',
                                  );
                                  return;
                                }
                                setModalState(() => isSearching = true);
                                final success = await controller
                                    .searchInvitationCode(code);
                                setModalState(() => isSearching = false);
                                if (success) {
                                  Get.back();
                                  final loaded = controller.rxSelectedVisitor.value;
                                  if (loaded != null && onVisitorLoaded != null) {
                                    onVisitorLoaded(loaded);
                                  }
                                  AppSnackbar.success(
                                    title: 'Success',
                                    message: 'Data retrieved successfully',
                                  );
                                } else {
                                  AppSnackbar.error(
                                    title: 'Search Failed',
                                    message:
                                        'No visitor data found for code: $code',
                                  );
                                }
                              },
                        child: isSearching
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Submit',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showExtendVisitDialog(BuildContext context) {
    final visitor = controller.rxSelectedVisitor.value;
    final hasMultiple = controller.rxSelectMultiple.value && controller.rxSelectedItems.isNotEmpty;
    if (visitor == null && !hasMultiple) {
      AppSnackbar.warning(
        title: 'Warning',
        message: 'Please select a visitor first to extend visit period.',
      );
      return;
    }

    int? selectedPeriod;
    bool applyToAll = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final periodOptions = [15, 30, 45, 60, 90, 120, 150, 180];

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                width: 490,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Title & Close Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Extend Visit',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.of(dialogContext).pop(),
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 22,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFF1F5F9)),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Duration Pill Buttons in 2 Rows matching screenshot
                          Center(
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: periodOptions.map((period) {
                                final isSelected = selectedPeriod == period;

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setModalState(() {
                                        selectedPeriod = period;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF004385)
                                            : const Color(0xFFEDEDED),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF004385)
                                              : const Color(0xFFE2E8F0),
                                          width: 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF004385).withValues(alpha: 0.25),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Text(
                                        '$period min',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected ? Colors.white : const Color(0xFF334155),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // "Apply to another visitor" Checkbox Row
                          InkWell(
                            onTap: () {
                              setModalState(() {
                                applyToAll = !applyToAll;
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: applyToAll ? const Color(0xFF004385) : Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: applyToAll ? const Color(0xFF004385) : const Color(0xFF94A3B8),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: applyToAll
                                        ? const Center(
                                            child: Icon(
                                              Icons.check_rounded,
                                              size: 13,
                                              color: Colors.white,
                                            )
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Apply to another visitor',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Extend Button
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedPeriod != null
                                    ? const Color(0xFF004385)
                                    : const Color(0xFFEDEDED),
                                foregroundColor: selectedPeriod != null
                                    ? Colors.white
                                    : const Color(0xFF94A3B8),
                                elevation: selectedPeriod != null ? 2 : 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: (selectedPeriod == null || isSubmitting)
                                  ? null
                                  : () async {
                                      setModalState(() => isSubmitting = true);
                                      final periodVal = selectedPeriod!;
                                      final success = await controller.extendVisitorPeriod(
                                        period: periodVal,
                                        applyToAll: applyToAll,
                                      );
                                      setModalState(() => isSubmitting = false);
                                      if (success && dialogContext.mounted) {
                                        Navigator.of(dialogContext).pop();
                                        _showExtendSuccessDialog(context, periodVal);
                                      }
                                    },
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Extend',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: selectedPeriod != null
                                            ? Colors.white
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showExtendSuccessDialog(BuildContext context, int minutes) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (successContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 360,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                    onTap: () => Navigator.of(successContext).pop(),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.red,
                    ),
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 32,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Success!',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Visit extended by $minutes minutes',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableCheckbox({
    required bool isChecked,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 17,
        height: 17,
        decoration: BoxDecoration(
          color: isChecked ? const Color(0xFF003082) : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isChecked ? const Color(0xFF003082) : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        child: isChecked
            ? const Center(
                child: Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  void _showAccessIssuanceDialog(
    BuildContext context,
    Map<String, dynamic> visitor,
  ) {
    final searchController = TextEditingController();
    final visitorId = (visitor['id'] ??
            visitor['transaction_visitor_id'] ??
            visitor['visitor_id'] ??
            '')
        .toString();

    List<Map<String, dynamic>> cardList = List<Map<String, dynamic>>.from(
      (visitor['card'] as List?) ?? (visitor['cards'] as List?) ?? [],
    );
    List<Map<String, dynamic>> accessList = List<Map<String, dynamic>>.from(
      (visitor['access'] as List?) ?? [],
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        bool isLoadingDetails =
            cardList.isEmpty && accessList.isEmpty && visitorId.isNotEmpty;
        bool hasFetched = false;
        final selectedCards = <int>{};
        final selectedAccess = <int>{};
        String searchQuery = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (isLoadingDetails && !hasFetched) {
              hasFetched = true;
              controller.fetchVisitorAccessDetails(visitorId).then((details) {
                if (details != null && dialogContext.mounted) {
                  setDialogState(() {
                    cardList = List<Map<String, dynamic>>.from(
                      (details['card'] as List?) ??
                          (details['cards'] as List?) ??
                          [],
                    );
                    accessList = List<Map<String, dynamic>>.from(
                      (details['access'] as List?) ?? [],
                    );
                    isLoadingDetails = false;
                  });
                } else if (dialogContext.mounted) {
                  setDialogState(() {
                    isLoadingDetails = false;
                  });
                }
              });
            }

            final filteredAccess = accessList.where((a) {
              if (searchQuery.trim().isEmpty) return true;
              final name = (a['access_control_name'] ?? a['name'] ?? '')
                  .toString()
                  .toLowerCase();
              return name.contains(searchQuery.trim().toLowerCase());
            }).toList();

            final allCardsSelected =
                cardList.isNotEmpty && selectedCards.length == cardList.length;
            final allAccessSelected = filteredAccess.isNotEmpty &&
                selectedAccess.length == filteredAccess.length;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                width: 960,
                constraints: const BoxConstraints(maxHeight: 560),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Modal Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 16, 16, 14),
                      child: Row(
                        children: [
                          Text(
                            'Access Issuance',
                            style: GoogleFonts.inter(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const Spacer(),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () => Navigator.of(dialogContext).pop(),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 19,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),

                    // Content Body (Two Columns: List Card & Access)
                    Expanded(
                      child: isLoadingDetails
                          ? const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF003082),
                              ),
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 14, 20, 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Column: List Card
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'List Card',
                                          style: GoogleFonts.inter(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // List Card Table Header
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              _buildTableCheckbox(
                                                isChecked: allCardsSelected,
                                                onTap: () {
                                                  setDialogState(() {
                                                    if (allCardsSelected) {
                                                      selectedCards.clear();
                                                    } else {
                                                      selectedCards.addAll(
                                                        List.generate(
                                                          cardList.length,
                                                          (i) => i,
                                                        ),
                                                      );
                                                    }
                                                  });
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              SizedBox(
                                                width: 30,
                                                child: Text(
                                                  'No',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        const Color(0xFF64748B),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  'Card Number',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        const Color(0xFF64748B),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 90,
                                                child: Center(
                                                  child: Text(
                                                    'Current Used',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                          0xFF64748B),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),

                                        // List Card Rows
                                        Expanded(
                                          child: cardList.isEmpty
                                              ? Center(
                                                  child: Text(
                                                    'No cards assigned to this visitor',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12.5,
                                                      color: const Color(
                                                          0xFF94A3B8),
                                                    ),
                                                  ),
                                                )
                                              : ListView.separated(
                                                  itemCount: cardList.length,
                                                  separatorBuilder: (_, __) =>
                                                      const Divider(
                                                    height: 1,
                                                    color: Color(0xFFF1F5F9),
                                                  ),
                                                  itemBuilder:
                                                      (context, index) {
                                                    final c = cardList[index];
                                                    final isSelected =
                                                        selectedCards
                                                            .contains(index);
                                                    final cardNum = (c[
                                                                'card_number'] ??
                                                            c['card_barcode'] ??
                                                            c['visitor_card'] ??
                                                            '-')
                                                        .toString();
                                                    final isUsed = c[
                                                                'current_used'] ==
                                                            true ||
                                                        c['is_employee_used'] ==
                                                            true ||
                                                        (c['card_status'] ?? '')
                                                                .toString()
                                                                .toLowerCase() ==
                                                            'available' ||
                                                        (c['status'] ?? '')
                                                                .toString()
                                                                .toLowerCase() ==
                                                            'issued';

                                                    return Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 10,
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          _buildTableCheckbox(
                                                            isChecked:
                                                                isSelected,
                                                            onTap: () {
                                                              setDialogState(
                                                                  () {
                                                                if (isSelected) {
                                                                  selectedCards
                                                                      .remove(
                                                                          index);
                                                                } else {
                                                                  selectedCards
                                                                      .add(
                                                                          index);
                                                                }
                                                              });
                                                            },
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          SizedBox(
                                                            width: 30,
                                                            child: Text(
                                                              '${index + 1}',
                                                              style:
                                                                  GoogleFonts
                                                                      .inter(
                                                                fontSize: 12.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: const Color(
                                                                    0xFF1E293B),
                                                              ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              cardNum,
                                                              style:
                                                                  GoogleFonts
                                                                      .inter(
                                                                fontSize: 12.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: const Color(
                                                                    0xFF1E293B),
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 90,
                                                            child: Center(
                                                              child: isUsed
                                                                  ? const Icon(
                                                                      Icons
                                                                          .check_circle_rounded,
                                                                      size: 19,
                                                                      color: Color(
                                                                          0xFF10B981),
                                                                    )
                                                                  : const Icon(
                                                                      Icons
                                                                          .cancel_rounded,
                                                                      size: 19,
                                                                      color: Color(
                                                                          0xFFEF4444),
                                                                    ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Subtle Vertical Divider
                                  Container(
                                    width: 1,
                                    color: const Color(0xFFE2E8F0),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                  ),

                                  // Right Column: Access
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Access',
                                          style: GoogleFonts.inter(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        // Search Bar Row
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color:
                                                        const Color(0xFFCBD5E1),
                                                  ),
                                                ),
                                                child: TextField(
                                                  controller: searchController,
                                                  onChanged: (val) {
                                                    setDialogState(() {
                                                      searchQuery = val;
                                                    });
                                                  },
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12.5,
                                                    color:
                                                        const Color(0xFF1E293B),
                                                  ),
                                                  decoration: InputDecoration(
                                                    hintText: 'Search...',
                                                    hintStyle:
                                                        GoogleFonts.inter(
                                                      fontSize: 12.5,
                                                      color: const Color(
                                                          0xFF94A3B8),
                                                    ),
                                                    prefixIcon: const Icon(
                                                      Icons.search_rounded,
                                                      size: 17,
                                                      color: Color(0xFF94A3B8),
                                                    ),
                                                    prefixIconConstraints:
                                                        const BoxConstraints(
                                                      minWidth: 32,
                                                      minHeight: 32,
                                                    ),
                                                    border: InputBorder.none,
                                                    contentPadding:
                                                        const EdgeInsets.only(
                                                            top: 6),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF003082),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                minimumSize: const Size(0, 36),
                                              ),
                                              onPressed: () {
                                                setDialogState(() {
                                                  searchQuery =
                                                      searchController.text;
                                                });
                                              },
                                              child: Text(
                                                'Search',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),

                                        // Access Table Header
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              _buildTableCheckbox(
                                                isChecked: allAccessSelected,
                                                onTap: () {
                                                  setDialogState(() {
                                                    if (allAccessSelected) {
                                                      selectedAccess.clear();
                                                    } else {
                                                      selectedAccess.addAll(
                                                        List.generate(
                                                          filteredAccess.length,
                                                          (i) => i,
                                                        ),
                                                      );
                                                    }
                                                  });
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              SizedBox(
                                                width: 30,
                                                child: Text(
                                                  'No',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        const Color(0xFF64748B),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  'Name',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        const Color(0xFF64748B),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 90,
                                                child: Center(
                                                  child: Text(
                                                    'Early Access',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                          0xFF64748B),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),

                                        // Access Table Rows
                                        Expanded(
                                          child: filteredAccess.isEmpty
                                              ? Center(
                                                  child: Text(
                                                    'No access controls found',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12.5,
                                                      color: const Color(
                                                          0xFF94A3B8),
                                                    ),
                                                  ),
                                                )
                                              : ListView.separated(
                                                  itemCount:
                                                      filteredAccess.length,
                                                  separatorBuilder: (_, __) =>
                                                      const Divider(
                                                    height: 1,
                                                    color: Color(0xFFF1F5F9),
                                                  ),
                                                  itemBuilder:
                                                      (context, index) {
                                                    final a =
                                                        filteredAccess[index];
                                                    final isSelected =
                                                        selectedAccess
                                                            .contains(index);
                                                    final accessName = (a[
                                                                'access_control_name'] ??
                                                            a['name'] ??
                                                            a['access_name'] ??
                                                            '-')
                                                        .toString();
                                                    final isEarlyAccess = a[
                                                            'early_access'] ==
                                                        true;

                                                    return Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 10,
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          _buildTableCheckbox(
                                                            isChecked:
                                                                isSelected,
                                                            onTap: () {
                                                              setDialogState(
                                                                  () {
                                                                if (isSelected) {
                                                                  selectedAccess
                                                                      .remove(
                                                                          index);
                                                                } else {
                                                                  selectedAccess
                                                                      .add(
                                                                          index);
                                                                }
                                                              });
                                                            },
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          SizedBox(
                                                            width: 30,
                                                            child: Text(
                                                              '${index + 1}',
                                                              style:
                                                                  GoogleFonts
                                                                      .inter(
                                                                fontSize: 12.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: const Color(
                                                                    0xFF1E293B),
                                                              ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              accessName,
                                                              style:
                                                                  GoogleFonts
                                                                      .inter(
                                                                fontSize: 12.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: const Color(
                                                                    0xFF1E293B),
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 90,
                                                            child: Center(
                                                              child: isEarlyAccess
                                                                  ? const Icon(
                                                                      Icons
                                                                          .check_circle_rounded,
                                                                      size: 19,
                                                                      color: Color(
                                                                          0xFF10B981),
                                                                    )
                                                                  : const Icon(
                                                                      Icons
                                                                          .cancel_rounded,
                                                                      size: 19,
                                                                      color: Color(
                                                                          0xFFEF4444),
                                                                    ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),

                                        const SizedBox(height: 6),
                                        // Bottom Action dropdown selector matching Image 3
                                        Container(
                                          height: 32,
                                          width: 85,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: const Color(0xFFCBD5E1)),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Spacer(),
                                              Icon(
                                                Icons
                                                    .keyboard_arrow_down_rounded,
                                                size: 18,
                                                color: Color(0xFF64748B),
                                              ),
                                            ],
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
            );
          },
        );
      },
    );
  }

  void _handlePrintAction() {
    AppSnackbar.success(
      title: 'Print Badge',
      message: 'Sending visitor pass badge to connected thermal printer...',
    );
  }

  void _handleContactAction(String message) {
    AppSnackbar.info(title: 'Host Contact', message: message);
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 4,
                  ),
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
                        isSelected:
                            _selectedVisitorSiteMenu == 'Blacklist Visitor',
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
            color: isSelected ? const Color(0xFFEBF3FC) : Colors.transparent,
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
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          'Select Site',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      // Options: SPU, Gedung SINERGI, Resident (from API)
                      ...((controller.rxRegisteredSites.isNotEmpty)
                              ? controller.rxRegisteredSites
                                  .map((s) => (s['name'] ?? '').toString())
                                  .where((name) => name.isNotEmpty)
                                  .toList()
                              : ['SPU', 'Gedung SINERGI', 'Resident'])
                          .map((site) {
                        final isSelected = _selectedSite == site;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedSite = site;
                              });
                              controller.rxSelectedSiteName.value = site;
                              final match = controller.rxRegisteredSites.firstWhereOrNull(
                                (s) => (s['name'] ?? '').toString().toLowerCase() == site.toLowerCase(),
                              );
                              if (match != null) {
                                controller.rxSelectedSiteId.value = (match['id'] ?? '').toString();
                              }
                              _closeSiteMenu();
                            },
                            hoverColor: const Color(0xFFF1F5F9),
                            child: Container(
                              color: isSelected
                                  ? const Color(0xFFEBF3FC)
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
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
  // Dynamic Bulk Actions List & Apply Logic
  // ─────────────────────────────────────────────────────────────────────────
  List<String> _getAvailableBulkActions() {
    // Bulk actions only exist when Select Multiple is active and at least one visitor is checked
    if (!controller.rxSelectMultiple.value || controller.rxSelectedItems.isEmpty) {
      return [];
    }

    final selectedSet = controller.rxSelectedItems.toSet();
    final selectedList = controller.rxAllRelatedVisitors.where((v) {
      final keys = [
        v['id'],
        v['trx_id'],
        v['transaction_visitor_id'],
        v['visitor_id'],
        v['invitation_code'],
        v['visitor_code'],
        v['visitor_number'],
        v['name'],
        v['visitor_name'],
      ].where((k) => k != null && k.toString().trim().isNotEmpty).map((k) => k.toString().trim()).toList();
      return keys.any((k) => selectedSet.contains(k));
    }).toList();

    if (selectedList.isEmpty) {
      return [];
    }

    final actions = <String>{};
    for (final v in selectedList) {
      final rawStatus = (v['visitor_status'] ?? v['status'] ?? '').toString().toLowerCase();
      final isBlocked = v['is_block'] == true || rawStatus == 'block' || rawStatus == 'blacklist';
      final isHost = v['is_host'] == true || v['raw']?['is_host'] == true;

      // 1. Blocked visitor -> can Unblock
      if (isBlocked) {
        actions.add('Unblock');
      } else {
        // 2. Active non-blocked visitor -> can Block
        actions.add('Block');

        // 3. Status Checkin -> can Check Out
        if (rawStatus.contains('checkin') || rawStatus == 'in') {
          actions.add('Check Out');
        }
        // 4. Host or Available/Waiting -> can Check In
        else if (isHost || rawStatus.contains('available') || rawStatus.contains('waiting')) {
          actions.add('Check In');
        }
        // 5. Preregis regular visitor -> can Fill Form
        else if (!rawStatus.contains('checkout') && rawStatus != 'out') {
          actions.add('Fill Form');
        }
      }
    }

    return actions.toList();
  }

  void _applyBulkAction() {
    if (_selectedBulkAction == null) {
      AppSnackbar.warning(
        title: 'Action Required',
        message: 'Please choose an action from the dropdown first.',
      );
      return;
    }
    final action = _selectedBulkAction!;

    final selectedVisitors = <Map<String, dynamic>>[];
    if (controller.rxSelectMultiple.value && controller.rxSelectedItems.isNotEmpty) {
      final selectedSet = controller.rxSelectedItems.toSet();
      selectedVisitors.addAll(controller.rxAllRelatedVisitors.where((v) {
        final keys = [
          v['id'],
          v['trx_id'],
          v['transaction_visitor_id'],
          v['visitor_id'],
          v['invitation_code'],
          v['visitor_code'],
          v['visitor_number'],
          v['name'],
          v['visitor_name'],
        ].where((k) => k != null && k.toString().trim().isNotEmpty).map((k) => k.toString().trim()).toList();
        return keys.any((k) => selectedSet.contains(k));
      }));
    }

    if (selectedVisitors.isEmpty) {
      AppSnackbar.warning(
        title: 'Warning',
        message: 'Please select at least one visitor to apply $action.',
      );
      return;
    }

    if (action == 'Fill Form') {
      _handleAction('Fill Form');
      return;
    }

    final validVisitors = <Map<String, dynamic>>[];
    for (final v in selectedVisitors) {
      final rawStatus = (v['visitor_status'] ?? v['status'] ?? '').toString().toLowerCase();
      final isBlocked = v['is_block'] == true || rawStatus == 'block' || rawStatus == 'blacklist';
      final isHost = v['is_host'] == true || v['raw']?['is_host'] == true;

      if ((action == 'Check In' || action == 'Checkin') && !isBlocked && (isHost || rawStatus.contains('available') || rawStatus.contains('waiting'))) {
        validVisitors.add(v);
      } else if ((action == 'Check Out' || action == 'Checkout') && !isBlocked && (rawStatus.contains('checkin') || rawStatus == 'in')) {
        validVisitors.add(v);
      } else if (action == 'Block' && !isBlocked) {
        validVisitors.add(v);
      } else if (action == 'Unblock' && isBlocked) {
        validVisitors.add(v);
      } else if (action == 'Blacklist' && !isBlocked) {
        validVisitors.add(v);
      }
    }

    if (validVisitors.isEmpty) {
      AppSnackbar.warning(
        title: 'Action Not Applicable',
        message: 'None of the selected visitors are eligible for $action.',
      );
      return;
    }

    if (action == 'Blacklist' || action == 'Block') {
      _showMultipleReasonActionDialog(context, action: action, validVisitors: validVisitors);
    } else {
      _showMultipleConfirmationActionDialog(context, action: action, validVisitors: validVisitors);
    }
  }

  void _showMultipleConfirmationActionDialog(
    BuildContext context, {
    required String action,
    required List<Map<String, dynamic>> validVisitors,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: 360,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: Colors.red,
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ),
                ),
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF86EFAC),
                      width: 2.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 38,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Do you want to apply $action to ${validVisitors.length} selected visitors?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 88,
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A6A80),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 88,
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            controller.performMultipleOperatorInvitationAction(
                              action: action,
                              visitors: validVisitors,
                            );
                          },
                          child: Text(
                            'Yes',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMultipleReasonActionDialog(
    BuildContext context, {
    required String action,
    required List<Map<String, dynamic>> validVisitors,
  }) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final isBlock = action.toLowerCase() == 'block';

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: 360,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: Colors.red,
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ),
                ),
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFED7AA),
                      width: 2.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.priority_high_rounded,
                      size: 38,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isBlock ? 'Multiple Blacklist Action' : 'Multiple Action',
                  style: GoogleFonts.inter(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Please provide a reason for applying $action to ${validVisitors.length} visitors:',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: reasonController,
                    autofocus: true,
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B)),
                    decoration: InputDecoration(
                      hintText: 'Enter reason...',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFF004385), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 88,
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A6A80),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 88,
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () {
                            final reason = reasonController.text.trim();
                            if (reason.isEmpty) {
                              AppSnackbar.warning(
                                title: 'Reason Required',
                                message: 'Please enter a reason before submitting.',
                              );
                              return;
                            }
                            Navigator.of(dialogContext).pop();
                            controller.performMultipleOperatorInvitationAction(
                              action: action,
                              visitors: validVisitors,
                              reason: reason,
                            );
                          },
                          child: Text(
                            'Submit',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Custom Floating Bulk Action Dropdown Menu & Helpers
  // ─────────────────────────────────────────────────────────────────────────
  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'check in':
      case 'checkin':
        return Icons.login_rounded;
      case 'check out':
      case 'checkout':
        return Icons.logout_rounded;
      case 'unblock':
        return Icons.lock_open_rounded;
      case 'block':
        return Icons.block_rounded;
      case 'blacklist':
        return Icons.gavel_rounded;
      case 'fill form':
      default:
        return Icons.edit_note_rounded;
    }
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'check in':
      case 'checkin':
        return const Color(0xFF10B981);
      case 'check out':
      case 'checkout':
        return const Color(0xFFEF4444);
      case 'unblock':
        return const Color(0xFF004385);
      case 'block':
        return const Color(0xFF1E293B);
      case 'blacklist':
        return const Color(0xFF212121);
      case 'fill form':
      default:
        return const Color(0xFF004385);
    }
  }

  void _toggleBulkActionMenu() {
    if (_bulkActionOverlay != null) {
      _closeBulkActionMenu();
      return;
    }

    setState(() {
      _isBulkActionMenuOpen = true;
    });

    final actions = _getAvailableBulkActions();
    final menuHeight = (actions.length * 38.0) + 12.0;

    final overlay = Overlay.of(context);
    _bulkActionOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeBulkActionMenu,
            ),
          ),
          Positioned(
            width: 155,
            child: CompositedTransformFollower(
              link: _bulkActionLayerLink,
              showWhenUnlinked: false,
              offset: Offset(0, -(menuHeight + 4)),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 5,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...actions.map((action) {
                        final isSelected = _selectedBulkAction == action;
                        final itemColor = _getActionColor(action);
                        final itemIcon = _getActionIcon(action);

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
                            hoverColor: const Color(0xFFF8FAFC),
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFEFF6FF)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    itemIcon,
                                    size: 16,
                                    color: itemColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      action,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? const Color(0xFF003082)
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 15,
                                      color: Color(0xFF003082),
                                    ),
                                ],
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

  // ─────────────────────────────────────────────────────────────────────────
  // Upcoming Visitors Modal Dialog (Live Occupancy Drill-Down - No Horizontal Scroll)
  // ─────────────────────────────────────────────────────────────────────────
  void _showUpcomingVisitorsDialog(
    BuildContext context, {
    required String categoryName,
    required String categoryId,
    int? initialCount,
  }) {
    controller.rxSelectedPurposeCategory.value = categoryName;
    controller.rxSelectedPurposeId.value = categoryId;
    controller.rxUpcomingVisitorsSearch.value = '';
    controller.rxUpcomingVisitorsPage.value = 1;
    controller.rxUpcomingVisitorsLength.value = 10;
    if (initialCount != null && initialCount > 0) {
      controller.rxUpcomingVisitorsTotal.value = initialCount;
    }

    final searchController = TextEditingController();
    Timer? searchDebounce;

    // Trigger API call
    controller.fetchUpcomingVisitors(
      visitorTypeId: categoryId,
      page: 1,
      length: 10,
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final screenHeight = MediaQuery.of(dialogContext).size.height;

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Container(
            width: (screenWidth * 0.94).clamp(750.0, 1150.0),
            height: (screenHeight * 0.88).clamp(460.0, 680.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F2B48).withValues(alpha: 0.16),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Dialog Header & Toolbar ────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF003082), Color(0xFF00529C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF003082).withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.badge_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    categoryName.toLowerCase().endsWith('visitors')
                                        ? categoryName
                                        : (categoryName.toLowerCase().endsWith('visitor')
                                            ? '${categoryName}s'
                                            : '$categoryName Visitors'),
                                    style: GoogleFonts.inter(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F2B48),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Obx(() {
                                    final total = controller.rxUpcomingVisitorsTotal.value;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFF93C5FD)),
                                      ),
                                      child: Text(
                                        '$total ${total == 1 ? "Visitor" : "Visitors"}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF003082),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Live upcoming schedule & check-in details for today',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Search Box with Instant Auto-Search & Reactive Clear Button
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: searchController,
                            builder: (context, value, _) {
                              final hasText = value.text.isNotEmpty;
                              return Container(
                                width: 280,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                alignment: Alignment.center,
                                child: TextField(
                                  controller: searchController,
                                  textAlignVertical: TextAlignVertical.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF1E293B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'Search visitor name...',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      size: 17,
                                      color: Color(0xFF64748B),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 34,
                                      minHeight: 36,
                                    ),
                                    suffixIcon: hasText
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.cancel_rounded,
                                              size: 16,
                                              color: Color(0xFF94A3B8),
                                            ),
                                            onPressed: () {
                                              searchDebounce?.cancel();
                                              searchController.clear();
                                              controller.rxUpcomingVisitorsSearch.value = '';
                                              controller.fetchUpcomingVisitors(
                                                visitorTypeId: categoryId,
                                                page: 1,
                                                search: '',
                                              );
                                            },
                                            splashRadius: 14,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 30, minHeight: 36),
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (query) {
                                    searchDebounce?.cancel();
                                    if (query.trim().isEmpty) {
                                      controller.rxUpcomingVisitorsSearch.value = '';
                                      controller.fetchUpcomingVisitors(
                                        visitorTypeId: categoryId,
                                        page: 1,
                                        search: '',
                                      );
                                    } else {
                                      searchDebounce = Timer(const Duration(milliseconds: 350), () {
                                        controller.rxUpcomingVisitorsSearch.value = query.trim();
                                        controller.fetchUpcomingVisitors(
                                          visitorTypeId: categoryId,
                                          page: 1,
                                          search: query.trim(),
                                        );
                                      });
                                    }
                                  },
                                  onSubmitted: (query) {
                                    searchDebounce?.cancel();
                                    controller.rxUpcomingVisitorsSearch.value = query.trim();
                                    controller.fetchUpcomingVisitors(
                                      visitorTypeId: categoryId,
                                      page: 1,
                                      search: query.trim(),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 14),
                          Material(
                            color: const Color(0xFFF1F5F9),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                searchDebounce?.cancel();
                                Navigator.of(dialogContext).pop();
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(7.0),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Table Column Headers (Fixed 100% Width, Zero Scroll) ──
                Container(
                  margin: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          'No',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 6,
                        child: Text(
                          'Visitor Details',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Host',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Invitation Code',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: Text(
                          'Agenda & Schedule',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Vehicle Plate',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Status',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Table Body (Clean Responsive Rows, No Horizontal Scroll) ──
                Expanded(
                  child: Obx(() {
                    if (controller.rxIsUpcomingVisitorsLoading.value) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF003082)),
                            SizedBox(height: 12),
                            Text(
                              'Loading upcoming visitors...',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }

                    final list = controller.rxUpcomingVisitorsList;
                    if (list.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.people_outline_rounded, size: 28, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No upcoming visitors found.',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No visitors currently scheduled under this category for today.',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final page = controller.rxUpcomingVisitorsPage.value;
                    final length = controller.rxUpcomingVisitorsLength.value;
                    final startIndex = (page - 1) * length;

                    return ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.stylus,
                          PointerDeviceKind.trackpad,
                        },
                      ),
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final item = list[index];
                          final no = startIndex + index + 1;
                          final name = (item['visitor_name'] ?? item['name'] ?? item['visitor']?['name'] ?? '-').toString();
                          final host = (item['host_name'] ?? item['host'] ?? '-').toString();
                          final invCode = (item['invitation_code'] ?? item['visitor_code'] ?? item['initial_trx_code'] ?? '-').toString();
                          final org = (item['visitor_organization_name'] ?? item['organization'] ?? '').toString();
                          final agenda = (item['agenda'] ?? item['purpose'] ?? item['remarks'] ?? 'Meeting').toString();
                          final periodStart = _formatUpcomingDate(item['visitor_period_start']?.toString());
                          final periodEnd = _formatUpcomingDate(item['visitor_period_end']?.toString());
                          final rawStatus = (item['visitor_status'] ?? item['status'] ?? '-').toString();
                          final plate = (item['vehicle_plate_number'] ?? item['plate_number'] ?? '').toString();
                          final rawSelfie = (item['selfie_image'] ?? item['visitor_face'] ?? item['faceimage'] ?? item['photo'] ?? '').toString().trim();
                          final cdnUrl = AppConstants.getCdnImageUrl(rawSelfie);
                          final hasSelfie = rawSelfie.isNotEmpty && rawSelfie != '-' && rawSelfie != 'null' && cdnUrl.isNotEmpty;

                          final isCheckin = rawStatus.toLowerCase().contains('checkin') || rawStatus.toLowerCase() == 'in';
                          final isCheckout = rawStatus.toLowerCase().contains('checkout') || rawStatus.toLowerCase() == 'out';
                          final isBlocked = rawStatus.toLowerCase().contains('block') || rawStatus.toLowerCase().contains('black');

                          Color statusBg = const Color(0xFFEFF6FF);
                          Color statusColor = const Color(0xFF003082);
                          Color statusBorder = const Color(0xFFBFDBFE);

                          if (isCheckin) {
                            statusBg = const Color(0xFFDCFCE7);
                            statusColor = const Color(0xFF10B981);
                            statusBorder = const Color(0xFF86EFAC);
                          } else if (isCheckout) {
                            statusBg = const Color(0xFFFEE2E2);
                            statusColor = const Color(0xFFEF4444);
                            statusBorder = const Color(0xFFFCA5A5);
                          } else if (isBlocked) {
                            statusBg = const Color(0xFFFEF2F2);
                            statusColor = const Color(0xFF991B1B);
                            statusBorder = const Color(0xFFFECACA);
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Row(
                              children: [
                                // 1. No
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    no.toString().padLeft(2, '0'),
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // 2. Visitor Details (Tappable Avatar Image + Name + Org)
                                Expanded(
                                  flex: 6,
                                  child: Row(
                                    children: [
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: () {
                                            _showVisitorImageModal(
                                              context,
                                              visitorName: name,
                                              imageUrl: cdnUrl,
                                              hasImage: hasSelfie,
                                            );
                                          },
                                          child: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: hasSelfie
                                                ? Image.network(
                                                    cdnUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Center(
                                                      child: Icon(
                                                        Icons.person,
                                                        size: 20,
                                                        color: Color(0xFF003082),
                                                      ),
                                                    ),
                                                  )
                                                : const Center(
                                                    child: Icon(
                                                      Icons.person,
                                                      size: 20,
                                                      color: Color(0xFF003082),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.inter(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF1E293B),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (org.isNotEmpty && org != '-')
                                              Text(
                                                org,
                                                style: GoogleFonts.inter(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(0xFF64748B),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // 3. Host
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    host,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF334155),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // 4. Invitation Code
                                Expanded(
                                  flex: 4,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFBFDBFE)),
                                            ),
                                            child: Text(
                                              invCode,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF003082),
                                                letterSpacing: 0.3,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        if (invCode.isNotEmpty && invCode != '-') ...[
                                          const SizedBox(width: 4),
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(4),
                                              onTap: () {
                                                Clipboard.setData(ClipboardData(text: invCode));
                                                AppSnackbar.success(
                                                  title: 'Copied',
                                                  message: 'Invitation code copied to clipboard',
                                                );
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.all(3.0),
                                                child: Icon(
                                                  Icons.copy_rounded,
                                                  size: 13.5,
                                                  color: Color(0xFF003082),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),

                              // 5. Agenda & Schedule
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      agenda,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '$periodStart - $periodEnd',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 6. Vehicle Plate
                              Expanded(
                                flex: 3,
                                child: Text(
                                  plate.isNotEmpty && plate != '-' ? plate : '-',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF475569),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 7. Status
                              Expanded(
                                flex: 3,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: statusBorder),
                                    ),
                                    child: Text(
                                      rawStatus,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),

                // ── Dialog Bottom Pagination Footer ────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border(
                      top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                  ),
                  child: Obx(() {
                    final total = controller.rxUpcomingVisitorsTotal.value;
                    final page = controller.rxUpcomingVisitorsPage.value;
                    final length = controller.rxUpcomingVisitorsLength.value;
                    final totalPages = total > 0 ? (total / length).ceil() : 1;
                    final start = total == 0 ? 0 : (page - 1) * length + 1;
                    final end = (page * length).clamp(0, total);
                    final hasPrev = page > 1;
                    final hasNext = page < totalPages;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing $start-$end of $total visitors',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                'Max rows: $length',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Text(
                                'Page $page of $totalPages',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF003082),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                                    color: hasPrev ? const Color(0xFF003082) : const Color(0xFFCBD5E1),
                                    onPressed: hasPrev
                                        ? () {
                                            controller.fetchUpcomingVisitors(
                                              visitorTypeId: categoryId,
                                              page: page - 1,
                                            );
                                          }
                                        : null,
                                    tooltip: hasPrev ? 'Previous Page' : null,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 34, minHeight: 30),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 20,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                                    color: hasNext ? const Color(0xFF003082) : const Color(0xFFCBD5E1),
                                    onPressed: hasNext
                                        ? () {
                                            controller.fetchUpcomingVisitors(
                                              visitorTypeId: categoryId,
                                              page: page + 1,
                                            );
                                          }
                                        : null,
                                    tooltip: hasNext ? 'Next Page' : null,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 34, minHeight: 30),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatUpcomingDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      DateTime dt;
      final clean = raw.trim();
      if (clean.endsWith('Z') || clean.contains('+') || (clean.length > 19 && clean.substring(19).contains('-'))) {
        dt = DateTime.parse(clean).toLocal();
      } else {
        dt = DateTime.parse('${clean}Z').toLocal();
      }
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$day $month $hour:$min';
    } catch (_) {
      return raw;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Visitor Profile Image Modal Preview (Darkened Backdrop + Close Button)
  // ─────────────────────────────────────────────────────────────────────────
  void _showVisitorImageModal(
    BuildContext context, {
    required String visitorName,
    required String imageUrl,
    required bool hasImage,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top "X" close button directly above the profile circle
                Container(
                  width: 250,
                  alignment: Alignment.centerRight,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 6,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                ),

                // Large Circular Profile Image
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasImage && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.person,
                              size: 90,
                              color: Color(0xFF003082),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.person,
                            size: 90,
                            color: Color(0xFF003082),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
