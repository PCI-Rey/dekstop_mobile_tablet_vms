import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/dashboard_controller.dart';
import '../../../core/shared/routes/app_pages.dart';

class DesktopDashboard extends GetView<DashboardController> {
  const DesktopDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = controller.rxIsDarkMode.value;
      final localTheme = _getDashboardTheme(isDark);

      return Theme(
        data: localTheme,
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;

            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: SafeArea(
                child: Column(
                  children: [
                    // 1. Top Navigation Bar
                    _buildTopBar(context, theme, colorScheme),

                    // 2. Main 3-Column Layout
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column (Visitor profile card & QR)
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildSelectedVisitorCard(
                                    theme,
                                    colorScheme,
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: _buildVisitorTabs(theme, colorScheme),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildQrCodeCard(theme, colorScheme),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Center Column (Actions grid, Related visitors, Timeline)
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: [
                                  _buildQuickActionsGrid(
                                    context,
                                    theme,
                                    colorScheme,
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    flex: 3,
                                    child: _buildRelatedVisitorsPanel(
                                      theme,
                                      colorScheme,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    flex: 2,
                                    child: _buildTimelineCard(theme, colorScheme),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Right Column (Host details, Occupancy statistics, ID photo, Alerts)
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildHostInfoCard(theme, colorScheme),
                                  const SizedBox(height: 8),
                                  _buildLiveOccupancyCard(theme, colorScheme),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: _buildIdentityIdCard(theme, colorScheme),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildAlertsCard(theme, colorScheme),
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
        ),
      );
    });
  }

  // --- Top Navigation Header ---
  Widget _buildTopBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.search, size: 20, color: Colors.grey),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: controller.rxSearchQuery.value,
                      onChanged: (val) => controller.rxSearchQuery.value = val,
                      textAlignVertical: TextAlignVertical.center,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'search_visitor_hint'.tr,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),

          // Action Buttons: Notifications, Print, Configuration, Themes, Profile initials
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Get.toNamed(AppRoutes.noInternet),
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () => Get.toNamed(AppRoutes.configure),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Get.toNamed(AppRoutes.configure),
          ),
          IconButton(
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () {
              controller.toggleTheme();
            },
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.profile),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primary,
              child: const Text(
                'OP',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Left Panel widgets ---
  Widget _buildSelectedVisitorCard(ThemeData theme, ColorScheme colorScheme) {
    return Obx(() {
      final visitor = controller.rxSelectedVisitor.value;
      final name = visitor?['name'] ?? 'Name';
      final company = visitor?['company'] ?? '-';
      final email = visitor?['email'] ?? '-';
      final phone = visitor?['phone'] ?? '-';
      final idCardNo = visitor?['id_card_no'] ?? '-';
      final gender = visitor?['gender'] ?? '-';
      final occupancy = visitor?['occupation'] ?? '-';
      
      final avatarUrl = visitor?['avatar'] ?? 'https://images.unsplash.com/photo-1560250097-0b93528c311a?fit=crop&w=300&h=300';

      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: theme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Photo on the Left with Face recognition overlay
                SizedBox(
                  width: 100,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.person,
                                color: colorScheme.primary,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ),
                  // Green face detection overlay brackets
                  Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Stack(
                          children: [
                            // Top-left
                            Positioned(
                              top: 0,
                              left: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Colors.greenAccent, width: 2),
                                    left: BorderSide(color: Colors.greenAccent, width: 2),
                                  ),
                                ),
                              ),
                            ),
                            // Top-right
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Colors.greenAccent, width: 2),
                                    right: BorderSide(color: Colors.greenAccent, width: 2),
                                  ),
                                ),
                              ),
                            ),
                            // Bottom-left
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.greenAccent, width: 2),
                                    left: BorderSide(color: Colors.greenAccent, width: 2),
                                  ),
                                ),
                              ),
                            ),
                            // Bottom-right
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.greenAccent, width: 2),
                                    right: BorderSide(color: Colors.greenAccent, width: 2),
                                  ),
                                ),
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
            const SizedBox(width: 10),

              // 2. Profile details on the Right
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 4),
                    _buildProfileDetailRow(Icons.business, 'Organization', company, colorScheme, theme),
                    _buildProfileDetailRow(Icons.mail_outline, 'Email', email, colorScheme, theme),
                    _buildProfileDetailRow(Icons.phone_iphone, 'Phone', phone, colorScheme, theme),
                    _buildProfileDetailRow(Icons.credit_card, 'Identity ID', idCardNo, colorScheme, theme),
                    _buildProfileDetailRow(Icons.wc, 'Gender', gender, colorScheme, theme),
                    _buildProfileDetailRow(Icons.person_outline, 'Occupancy', occupancy, colorScheme, theme),
                  ],
                ),
              ),
            ],
          ),
         ),
        ),
      );
    });
  }

  Widget _buildProfileDetailRow(
    IconData icon,
    String label,
    String? value,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white70 : Colors.grey[700]!;
    final valColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Icon(icon, size: 13, color: colorScheme.primary),
          const SizedBox(width: 6),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: labelColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            ' :  ',
            style: TextStyle(
              fontSize: 10,
              color: labelColor,
            ),
          ),
          Expanded(
            child: Text(
              (value == null || value.trim().isEmpty) ? '-' : value,
              style: TextStyle(
                fontSize: 10,
                color: valColor,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorTabs(ThemeData theme, ColorScheme colorScheme) {
    return Obx(() {
      final visitor = controller.rxSelectedVisitor.value;
      final selectedIndex = controller.rxSelectedTab.value;
      final tabLabels = ['Visit Info', 'Purpose', 'Card', 'History'];
      
      final safeIndex = selectedIndex >= tabLabels.length ? 0 : selectedIndex;

      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: theme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tabs selectors
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: tabLabels.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final label = entry.value;
                  final isSelected = safeIndex == idx;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => controller.rxSelectedTab.value = idx,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected ? colorScheme.primary : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              // Tab contents filling vertical space evenly
              Expanded(
                child: _buildTabContents(safeIndex, visitor, theme),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTabContents(
    int index,
    Map<String, dynamic>? visitor,
    ThemeData theme,
  ) {
    final subtextColor = theme.brightness == Brightness.dark
        ? const Color(0xFF718096)
        : Colors.grey[600]!;

    if (index == 0) {
      // Visit Information
      final leftRows = [
        _buildTabDetailColumnRow(Icons.badge_outlined, 'Visitor Code', visitor?['visitor_code'], subtextColor, theme),
        _buildTabDetailColumnRow(Icons.format_list_numbered, 'Visitor Number', visitor?['ticket_no'], subtextColor, theme),
        _buildTabDetailColumnRow(Icons.group_outlined, 'Group Name', visitor?['group_name'], subtextColor, theme),
        _buildTabDetailColumnRow(Icons.verified_user_outlined, 'Status', visitor?['status'], subtextColor, theme),
      ];
      final rightRows = [
        _buildTabDetailColumnRow(Icons.person_add_alt_1_outlined, 'Invited By', visitor?['created_by'], subtextColor, theme),
        _buildTabDetailColumnRow(Icons.directions_car_outlined, 'Vehicle Type', visitor?['visit_type'], subtextColor, theme),
        _buildTabDetailColumnRow(Icons.receipt_outlined, 'Vehicle Plate', visitor?['vehicle_plate_number'], subtextColor, theme),
        _buildTabDetailColumnRow(Icons.shield_outlined, 'Access Gate', visitor?['gate'] ?? 'Lobby A Main', subtextColor, theme),
      ];

      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: leftRows,
              ),
            ),
            VerticalDivider(
              width: 16,
              thickness: 1,
              color: theme.dividerColor,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rightRows,
              ),
            ),
          ],
        ),
      );
    } else if (index == 1) {
      // Purpose Visit
      final leftRows = [
        _buildTabDetailColumnRow(Icons.calendar_today_outlined, 'Agenda', visitor?['visit_purpose'], subtextColor, theme),
        _buildTabDetailColumnRow(
          Icons.event_note_outlined,
          'Period Start',
          visitor?['visitor_period_start']?.toString().replaceAll('T', ' '),
          subtextColor,
          theme,
        ),
        _buildTabDetailColumnRow(Icons.location_on_outlined, 'Site Location', visitor?['site_place_name'], subtextColor, theme),
      ];
      final rightRows = [
        _buildTabDetailColumnRow(Icons.person_outline, 'PIC Host', visitor?['host'], subtextColor, theme),
        _buildTabDetailColumnRow(
          Icons.event_note_outlined,
          'Period End',
          visitor?['visitor_period_end']?.toString().replaceAll('T', ' '),
          subtextColor,
          theme,
        ),
        _buildTabDetailColumnRow(Icons.business_outlined, 'Department', visitor?['host_title'], subtextColor, theme),
      ];

      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: leftRows,
              ),
            ),
            VerticalDivider(
              width: 16,
              thickness: 1,
              color: theme.dividerColor,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rightRows,
              ),
            ),
          ],
        ),
      );
    } else if (index == 2) {
      // Card Info
      final leftRows = [
        _buildTabDetailColumnRow(Icons.credit_card, 'Card Status', visitor != null ? 'Active & Registered' : null, subtextColor, theme),
        _buildTabDetailColumnRow(Icons.credit_card_off_outlined, 'Card ID Ref', visitor?['id_card_no'], subtextColor, theme),
        _buildTabDetailColumnRow(Icons.nfc_outlined, 'RFID Tag', visitor != null ? 'RFID-88392-A' : null, subtextColor, theme),
      ];
      final rightRows = [
        _buildTabDetailColumnRow(Icons.swipe_vertical_outlined, 'Swipe Count', visitor != null ? '4 Swipes Today' : null, subtextColor, theme),
        _buildTabDetailColumnRow(Icons.security_outlined, 'Access Zone', visitor != null ? 'Zone 1 - Main Floor' : null, subtextColor, theme),
        _buildTabDetailColumnRow(Icons.timelapse_outlined, 'Valid Until', visitor?['visitor_period_end']?.toString().replaceAll('T', ' '), subtextColor, theme),
      ];

      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: leftRows,
              ),
            ),
            VerticalDivider(
              width: 16,
              thickness: 1,
              color: theme.dividerColor,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rightRows,
              ),
            ),
          ],
        ),
      );
    } else {
      // History List
      final historyRows = [
        _buildHistoryRow('Checked In', 'Lobby A - Gates', visitor?['check_in_time'] ?? '14 Jan 2026, 09:47'),
        _buildHistoryRow('Badge Issued', 'Reception Kiosk 2', '14 Jan 2026, 09:45'),
        _buildHistoryRow('Created Registration', 'Portal Pre-Reg', '12 Jan 2026, 14:15'),
      ];
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: historyRows,
      );
    }
  }

  Widget _buildTabDetailColumnRow(
    IconData icon,
    String label,
    String? value,
    Color subtextColor,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white : Colors.black87;
    final valueColor = isDark ? Colors.white70 : Colors.grey[700]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: subtextColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: labelColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  (value == null || value.trim().isEmpty) ? '-' : value,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: valueColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(String action, String gate, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(Icons.history, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  gate,
                  style: TextStyle(fontSize: 8.5, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(time, style: TextStyle(fontSize: 8.5, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildQrCodeCard(ThemeData theme, ColorScheme colorScheme) {
    return Obx(() {
      final visitor = controller.rxSelectedVisitor.value;
      if (visitor == null) {
        final subtextColor = theme.brightness == Brightness.dark
            ? const Color(0xFF718096)
            : Colors.grey[600]!;
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          color: theme.cardColor,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Visitor QR Code',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Placeholder box for QR area
                    Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF161B26)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.document_scanner_outlined,
                            size: 24,
                            color: subtextColor,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'No QR/Card',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 8, color: subtextColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQrDetailRowWithIcon(Icons.confirmation_number_outlined, 'Invitation Code', '-', subtextColor),
                          _buildQrDetailRowWithIcon(Icons.login_outlined, 'Check In Time', '-', subtextColor),
                          _buildQrDetailRowWithIcon(Icons.logout_outlined, 'Check Out Time', '-', subtextColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }

      final isCheckedIn = visitor['status'] == 'Checked In';

      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'qr_code'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: QrImageView(
                      data: visitor['qr_code_data'] ?? 'VMS-TICKET',
                      version: QrVersions.auto,
                      size: 65.0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQrDetailRow(
                          'Ticket No',
                          visitor['ticket_no'] ?? "",
                        ),
                        _buildQrDetailRow(
                          'Code',
                          visitor['invitation_code'] ?? "",
                        ),
                        _buildQrDetailRow('Type', visitor['visit_type']),
                        _buildQrDetailRow('Status', visitor['status']),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isCheckedIn
                                ? Colors.green
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            visitor['status'],
                            style: TextStyle(
                              color: isCheckedIn ? Colors.white : Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildQrDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ),
          Text(' : ', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          Expanded(
            child: Text(
              val,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Row dengan icon di sebelah kiri — digunakan pada placeholder QR Tamu
  Widget _buildQrDetailRowWithIcon(
    IconData icon,
    String label,
    String val,
    Color iconColor,
  ) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        // Label lebih gelap di light mode agar terbaca jelas
        final labelColor = isDark ? iconColor : Colors.grey[700]!;
        final valColor = isDark
            ? Colors.white70
            : Colors.grey[850] ?? const Color(0xFF1A1A1A);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isDark ? iconColor : Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 10, color: labelColor),
                    ),
                    Text(
                      val,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: valColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Center Panel Actions Grid ---
  Widget _buildQuickActionsGrid(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A2: Quick Actions header row dengan Edit icon
            Row(
              children: [
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                // Edit icon — compact, tidak ganggu layout
                Tooltip(
                  message: 'Customise actions',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => Get.snackbar(
                      'Quick Actions',
                      'Action customisation feature will be available soon.',
                      snackPosition: SnackPosition.BOTTOM,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.8,
              children: [
                // Row 1
                _buildActionTile(
                  Icons.qr_code_scanner,
                  'Scan QR',
                  Colors.blue[700]!,
                  () => _showCameraChoiceBottomSheet(context),
                ),
                _buildActionTile(
                  Icons.local_parking,
                  'Parking',
                  Colors.teal,
                  () => Get.snackbar('Parking Lot', 'Registering parking ticket...'),
                ),
                _buildActionTile(
                  Icons.door_sliding_outlined,
                  'Open',
                  const Color(0xFF8B1A1A), // dark red
                  () => controller.executeAction('open_door'),
                ),
                // Row 2
                _buildActionTile(
                  Icons.how_to_reg,
                  'Pra Register',
                  Colors.blue[400]!,
                  () => Get.snackbar('VMS Registration', 'Opening Pre-Registration form...'),
                ),
                _buildActionTile(
                  Icons.directions_walk_rounded,
                  'Walk In',
                  Colors.blue[600]!,
                  () => Get.snackbar('VMS Registration', 'Opening walk-in form...'),
                ),
                _buildActionTile(
                  Icons.update,
                  'Extend',
                  Colors.amber[700]!,
                  () => controller.executeAction('extend_visit'),
                ),
                _buildActionTile(
                  Icons.restore,
                  'Arrival',
                  Colors.greenAccent[700]!,
                  () => Get.snackbar('Log', 'Opening arrival log...'),
                ),
                // Row 3
                _buildActionTile(
                  Icons.login,
                  'Checkin',
                  Colors.green[600]!,
                  () => controller.executeAction('check_in'),
                ),
                _buildActionTile(
                  Icons.logout,
                  'Checkout',
                  Colors.red,
                  () => controller.executeAction('check_out'),
                ),
                _buildActionTile(
                  Icons.print_outlined,
                  'Print',
                  Colors.blueGrey[600]!,
                  () => Get.snackbar('Print', 'Printing visitor document...'),
                ),
                _buildActionTile(
                  Icons.block,
                  'Blacklist',
                  Colors.blueGrey[700]!,
                  () => controller.executeAction('blacklist'),
                ),
                // Row 4
                _buildActionTile(
                  Icons.credit_card,
                  'Card Issuance',
                  Colors.purple,
                  () => Get.snackbar('RFID Integration', 'Issuing visitor card...'),
                ),
                _buildActionTile(
                  Icons.credit_card_off_outlined,
                  'Card Return',
                  Colors.purple[300]!,
                  () => Get.snackbar('RFID Integration', 'Returning visitor card...'),
                ),
                _buildActionTile(
                  Icons.edit_note_outlined,
                  'Enable Edit',
                  Colors.deepPurple[300]!,
                  () => Get.snackbar('Edit Mode', 'Edit mode enabled...'),
                ),
                // Row 5
                _buildActionTile(
                  Icons.key,
                  'Access Issuance',
                  Colors.orange,
                  () => Get.snackbar('Security Access', 'Accessing door control panel...'),
                ),
                _buildActionTile(
                  Icons.edit_document,
                  'Edit Form',
                  Colors.deepPurple[400]!,
                  () => Get.snackbar('Edit Form', 'Opening visitor edit form...'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    final adjustedColor = color;

    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark
            ? adjustedColor.withValues(alpha: 0.12)
            : adjustedColor.withValues(alpha: 0.13);
        final labelColor = isDark
            ? adjustedColor
            : HSLColor.fromColor(adjustedColor)
                .withLightness(
                    (HSLColor.fromColor(adjustedColor).lightness - 0.15)
                        .clamp(0.0, 1.0))
                .toColor();

        return Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: adjustedColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(icon, color: Colors.white, size: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      color: labelColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 9.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Center Related Visitors Panel ---
  Widget _buildRelatedVisitorsPanel(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs and Header
            Row(
              children: [
                const Text(
                  'Related Visitors (50)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const Spacer(),
                Obx(
                  () => Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: controller.rxSelectMultiple.value,
                          onChanged: (val) {
                            controller.rxSelectMultiple.value = val ?? false;
                            if (val == false) controller.clearSelectedItems();
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Select Multiple',
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  icon: const Icon(Icons.filter_list, size: 12),
                  label: const Text('Filter', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
            const Divider(height: 12),

            // Grid of visitors
            Expanded(
              child: Obx(() {
                final visitors = controller.rxRelatedVisitors;
                if (visitors.isEmpty) {
                  return const Center(child: Text('No data available'));
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: visitors.length,
                  itemBuilder: (context, index) {
                    final item = visitors[index];
                    final name = item['name'] as String;
                    final company = item['company'] as String;

                    return Obx(() {
                      final isSelected = controller.rxSelectedItems.contains(
                        name,
                      );

                      return InkWell(
                        onTap: () {
                          if (controller.rxSelectMultiple.value) {
                            controller.toggleSelectItem(name);
                          }
                        },
                        child: Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(
                              color: isSelected
                                  ? colorScheme.primary
                                  : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 15,
                                        backgroundColor:
                                            colorScheme.secondaryContainer,
                                        backgroundImage: NetworkImage(
                                          item['avatar'] ?? '',
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        company,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 7.5,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (controller.rxSelectMultiple.value)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: isSelected
                                          ? colorScheme.primary
                                          : Colors.grey,
                                      size: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    });
                  },
                );
              }),
            ),

            // A4: Action Bar
            Obx(() {
              if (!controller.rxSelectMultiple.value ||
                  controller.rxSelectedItems.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${controller.rxSelectedItems.length} selected',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => controller.executeAction('check_in'),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        icon: const Icon(
                          Icons.login,
                          size: 12,
                          color: Colors.green,
                        ),
                        label: const Text(
                          'Check-In',
                          style: TextStyle(fontSize: 10, color: Colors.green),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => controller.executeAction('check_out'),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        icon: const Icon(
                          Icons.logout,
                          size: 12,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Check-Out',
                          style: TextStyle(fontSize: 10, color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          controller.clearSelectedItems();
                          controller.rxSelectMultiple.value = false;
                        },
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        icon: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.grey,
                        ),
                        label: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // --- Right Panel widgets ---
  Widget _buildHostInfoCard(ThemeData theme, ColorScheme colorScheme) {
    return Obx(() {
      final visitor = controller.rxSelectedVisitor.value;
      final hostName = visitor?['host'] ?? '-';
      final hostDept = visitor?['host_title'] ?? '-';
      final hostPhone = visitor?['host_phone'] ?? '-';
      final hostEmail = visitor?['host_email'] ?? '-';
      final hostAvatar = visitor?['host_avatar'] as String?;

      final subtextColor = theme.brightness == Brightness.dark
          ? const Color(0xFFA0AEC0)
          : Colors.grey[600]!;

      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Host Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF78909C),
                    backgroundImage: hostAvatar != null && hostAvatar.isNotEmpty
                        ? NetworkImage(hostAvatar)
                        : null,
                    child: hostAvatar == null || hostAvatar.isEmpty
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 26,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hostName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          hostDept,
                          style: TextStyle(color: subtextColor, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_in_talk_outlined,
                              size: 12,
                              color: subtextColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ': $hostPhone',
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.mail_outline_rounded,
                              size: 12,
                              color: subtextColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ': $hostEmail',
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 14, thickness: 1),
              Row(
                children: [
                  Expanded(
                    child: _buildHostActionIconButton(
                      icon: Icons.phone_in_talk_outlined,
                      label: 'Call',
                      bgColor: const Color(0xFF7CA1C4),
                      onTap: () => Get.snackbar('Call', 'Calling host...'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildHostActionIconButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Chat',
                      bgColor: const Color(0xFF80EED2),
                      onTap: () =>
                          Get.snackbar('Chat', 'Sending chat to host...'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildHostActionIconButton(
                      icon: Icons.mail_outline_rounded,
                      label: 'Email',
                      bgColor: const Color(0xFF9AD5FA),
                      onTap: () =>
                          Get.snackbar('Email', 'Sending email to host...'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHostActionIconButton({
    required IconData icon,
    required String label,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveOccupancyCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Live Occupancy',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  'Today',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(
              () => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 2.2,
                children: [
                  _buildOccupancyTile(
                    'employees'.tr,
                    controller.rxOccupancy['employees'].toString(),
                    Icons.people_outline,
                    Colors.blue,
                  ),
                  _buildOccupancyTile(
                    'visitors'.tr,
                    controller.rxOccupancy['visitors'].toString(),
                    Icons.person_pin_circle_outlined,
                    Colors.green,
                  ),
                  _buildOccupancyTile(
                    'contractors'.tr,
                    controller.rxOccupancy['contractors'].toString(),
                    Icons.engineering_outlined,
                    Colors.orange,
                  ),
                  _buildOccupancyTile(
                    'vehicles'.tr,
                    controller.rxOccupancy['vehicles'].toString(),
                    Icons.local_shipping_outlined,
                    Colors.purple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccupancyTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        border: Border.all(color: color.withValues(alpha: 0.12), width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 8),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityIdCard(ThemeData theme, ColorScheme colorScheme) {
    return Obx(() {
      final visitor = controller.rxSelectedVisitor.value;
      final docUrl = visitor?['identity_doc_url'] as String?;

      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Identity Image',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: docUrl != null && docUrl.isNotEmpty
                      ? Image.network(
                          docUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildNoIdentityImagePlaceholder(theme),
                        )
                      : _buildNoIdentityImagePlaceholder(theme),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNoIdentityImagePlaceholder(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF161B26)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF2D3748)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Center(
        child: Text(
          'No Identity Image',
          style: TextStyle(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF718096)
                : const Color(0xFFA0AEC0),
            fontStyle: FontStyle.italic,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alerts',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const Text(
                  'View All',
                  style: TextStyle(color: Colors.blue, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Obx(
              () => Column(
                children: controller.rxAlerts.map((alert) {
                  final isCritical = alert['critical'] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isCritical ? Colors.red[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isCritical
                            ? Colors.red[100]!
                            : Colors.orange[100]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCritical ? Icons.warning : Icons.info,
                          color: isCritical
                              ? Colors.redAccent
                              : Colors.orangeAccent,
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert['message'],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isCritical
                                      ? Colors.red[900]
                                      : Colors.orange[900],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                alert['subText'],
                                style: TextStyle(
                                  fontSize: 8,
                                  color: isCritical
                                      ? Colors.red[700]
                                      : Colors.orange[700],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          alert['time'],
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- A3: Timeline Card ---
  Widget _buildTimelineCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Visit Timeline',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.visitorDetail),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('View All', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Obx(
                () => ListView(
                  padding: EdgeInsets.zero,
                  children: controller.rxTimeline.map((item) {
                    final color = _getTimelineColor(item['status']);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getTimelineIcon(item['status']),
                              color: color,
                              size: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item['time'],
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item['title'],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  item['desc'],
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTimelineIcon(String? status) {
    switch (status) {
      case 'invitation':
        return Icons.mail_outline;
      case 'arrived':
        return Icons.face;
      case 'checked_in':
        return Icons.login;
      case 'card_issued':
        return Icons.credit_card;
      default:
        return Icons.circle;
    }
  }

  Color _getTimelineColor(String? status) {
    switch (status) {
      case 'invitation':
        return Colors.blue;
      case 'arrived':
        return Colors.green;
      case 'checked_in':
        return Colors.teal;
      case 'card_issued':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // --- Scan Bottom Sheet Choice Options ---

  void _showCameraChoiceBottomSheet(BuildContext context) {
    final textController = TextEditingController();
    final rxHasInput = false.obs;
    final rxIsLoading = false.obs;
    textController.addListener(() {
      rxHasInput.value = textController.text.trim().isNotEmpty;
    });

    final colorScheme = Theme.of(context).colorScheme;

    Get.bottomSheet(
      Obx(() {
        return Material(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Scan QR Visitor',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 1. Input Text Section
                  Text(
                    'Input Text',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: textController,
                    autofocus: false,
                    enabled: !rxIsLoading.value,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Enter your code',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                    ),
                    onFieldSubmitted: (val) async {
                      if (val.trim().isNotEmpty && !rxIsLoading.value) {
                        rxIsLoading.value = true;
                        final success = await controller.searchInvitationCode(val.trim());
                        rxIsLoading.value = false;
                        Get.back();
                        if (success) {
                          Get.snackbar(
                            'Visitor Found',
                            'Loaded profile for ${controller.rxSelectedVisitor.value?['name']}',
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.TOP,
                          );
                        } else {
                          Get.snackbar(
                            'Not Found',
                            'No visitor matches invitation code "$val"',
                            backgroundColor: Colors.redAccent,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.TOP,
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                          foregroundColor: colorScheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: !rxIsLoading.value
                            ? () {
                                Get.back();
                                Get.snackbar(
                                  'New Invitation',
                                  'Opening new invitation registration form...',
                                  backgroundColor: Colors.blueAccent,
                                  colorText: Colors.white,
                                );
                              }
                            : null,
                        icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                        label: const Text(
                          'New Invitation',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rxHasInput.value && !rxIsLoading.value
                              ? colorScheme.primary
                              : Colors.grey[300],
                          foregroundColor: rxHasInput.value && !rxIsLoading.value
                              ? Colors.white
                              : Colors.grey[600],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: rxHasInput.value && !rxIsLoading.value
                            ? () async {
                                rxIsLoading.value = true;
                                final success = await controller.searchInvitationCode(textController.text.trim());
                                rxIsLoading.value = false;
                                Get.back();
                                if (success) {
                                  Get.snackbar(
                                    'Visitor Found',
                                    'Loaded profile for ${controller.rxSelectedVisitor.value?['name']}',
                                    backgroundColor: Colors.green,
                                    colorText: Colors.white,
                                    snackPosition: SnackPosition.TOP,
                                  );
                                } else {
                                  Get.snackbar(
                                    'Not Found',
                                    'No visitor matches invitation code "${textController.text.trim()}"',
                                    backgroundColor: Colors.redAccent,
                                    colorText: Colors.white,
                                    snackPosition: SnackPosition.TOP,
                                  );
                                }
                              }
                            : null,
                        child: rxIsLoading.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // 2. Camera list selection Section
                  Text(
                    'Select Scanning Camera',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.camera_front),
                    title: const Text('Front Camera'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onTap: () {
                      Get.back();
                      Get.snackbar('Scan QR', 'Opening front camera...');
                      if (controller.rxAllRelatedVisitors.isNotEmpty) {
                        controller.rxSelectedVisitor.value =
                            controller.rxAllRelatedVisitors[0];
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_rear),
                    title: const Text('Rear Camera'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onTap: () {
                      Get.back();
                      Get.snackbar('Scan QR', 'Opening rear camera...');
                      if (controller.rxAllRelatedVisitors.isNotEmpty) {
                        controller.rxSelectedVisitor.value =
                            controller.rxAllRelatedVisitors[1 %
                                controller.rxAllRelatedVisitors.length];
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.usb),
                    title: const Text('External USB Camera'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onTap: () {
                      Get.back();
                      Get.snackbar('Scan QR', 'Opening USB camera...');
                      if (controller.rxAllRelatedVisitors.isNotEmpty) {
                        controller.rxSelectedVisitor.value =
                            controller.rxAllRelatedVisitors[2 %
                                controller.rxAllRelatedVisitors.length];
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.dns),
                    title: const Text('IP Camera (Lobby A Gate 1)'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onTap: () {
                      Get.back();
                      Get.snackbar('Scan QR', 'Connecting IP camera feed...');
                      if (controller.rxAllRelatedVisitors.isNotEmpty) {
                        controller.rxSelectedVisitor.value =
                            controller.rxAllRelatedVisitors[3 %
                                controller.rxAllRelatedVisitors.length];
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }),
      isScrollControlled: true,
    );
  }
}

// Fallback image styling helper
class BoxThemeFallback {
  static const BoxFit imageFit = BoxFit.cover;
}

ThemeData _getDashboardTheme(bool isDark) {
  final seedColor = const Color(0xFF0F62FE); // Sleek tech blue

  if (isDark) {
    // Elegant Dark Theme
    final colorScheme = ColorScheme.dark(
      primary: seedColor,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF1E293B),
      onPrimaryContainer: const Color(0xFFE2E8F0),
      secondary: const Color(0xFF38BDF8),
      onSecondary: Colors.black,
      surface: const Color(0xFF0F172A), // Deep Slate Navy (tailwind slate-900)
      onSurface: const Color(0xFFF8FAFC), // Off-white (slate-50)
      surfaceContainerHighest: const Color(
        0xFF1E293B,
      ), // replacing surfaceContainerHighest
      error: Colors.redAccent,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(
        0xFF0B0F19,
      ), // Darker slate for background
      cardColor: const Color(0xFF1E293B), // Slate-800 for cards
      dividerColor: const Color(0xFF334155), // Slate-700
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            bodyMedium: const TextStyle(color: Color(0xFFCBD5E1)), // Slate-300
            bodySmall: const TextStyle(color: Color(0xFF94A3B8)), // Slate-400
          ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFF334155),
            width: 1,
          ), // subtle slate border
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
    );
  } else {
    // Sleek Light Theme
    final colorScheme = ColorScheme.light(
      primary: seedColor,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black87,
      surfaceContainerHighest: const Color(0xFFF1F5F9), // Light Slate
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(
        0xFFEDF2FF,
      ), // Periwinkle-blue background
      cardColor: Colors.white,
      dividerColor: Colors.grey[200],
      textTheme: GoogleFonts.interTextTheme(),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      iconTheme: IconThemeData(color: Colors.grey[700]),
    );
  }
}
