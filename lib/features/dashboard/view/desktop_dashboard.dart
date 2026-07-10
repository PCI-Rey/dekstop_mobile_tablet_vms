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
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column (Visitor profile card & QR)
                            Expanded(
                              flex: 3,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _buildSelectedVisitorCard(
                                      theme,
                                      colorScheme,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildVisitorTabs(theme, colorScheme),
                                    const SizedBox(height: 16),
                                    _buildQrCodeCard(theme, colorScheme),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Center Column (Actions grid, Related visitors, Timeline)
                            Expanded(
                              flex: 4,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _buildQuickActionsGrid(
                                      context,
                                      theme,
                                      colorScheme,
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 400,
                                      child: _buildRelatedVisitorsPanel(
                                        theme,
                                        colorScheme,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // A3: Timeline Card — tablet style: card penuh, bukan section scroll
                                    _buildTimelineCard(theme, colorScheme),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Right Column (Host details, Occupancy statistics, ID photo, Alerts)
                            Expanded(
                              flex: 3,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _buildHostInfoCard(theme, colorScheme),
                                    const SizedBox(height: 16),
                                    _buildLiveOccupancyCard(theme, colorScheme),
                                    const SizedBox(height: 16),
                                    _buildIdentityIdCard(theme, colorScheme),
                                    const SizedBox(height: 16),
                                    _buildAlertsCard(theme, colorScheme),
                                  ],
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
                color: colorScheme.surfaceVariant.withOpacity(0.4),
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
      if (visitor == null) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: theme.cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 48.0,
              horizontal: 24.0,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.qr_code_scanner,
                      color: colorScheme.primary,
                      size: 54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Belum Ada Data Scan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Gunakan scanner hardware / kamera tablet, atau pilih salah satu tamu terdaftar di panel tengah untuk memuat berkas profile.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: theme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo with simulated hover edit cam icon
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          visitor['avatar'],
                          width: 90,
                          height: 90,
                          fit: BoxThemeFallback.imageFit,
                          errorBuilder: (_, __, ___) => Container(
                            color: colorScheme.primary.withOpacity(0.1),
                            width: 90,
                            height: 90,
                            child: Icon(
                              Icons.person,
                              color: colorScheme.primary,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Primary Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visitor['name'],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (visitor['vip'] == true)
                              _buildBadge(
                                'VIP VISITOR',
                                Colors.purple,
                                Colors.purple[50]!,
                              ),
                            const SizedBox(width: 4),
                            if (visitor['frequent'] == true)
                              _buildBadge(
                                'FREQUENT',
                                Colors.blue,
                                Colors.blue[50]!,
                              ),
                            const SizedBox(width: 4),
                            if (visitor['verified'] == true)
                              _buildBadge(
                                'VERIFIED',
                                Colors.green,
                                Colors.green[50]!,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildDetailText(
                          Icons.business,
                          'Company',
                          visitor['company'],
                        ),
                        _buildDetailText(
                          Icons.mail_outline,
                          'Email',
                          visitor['email'],
                        ),
                        _buildDetailText(
                          Icons.phone_iphone,
                          'Phone',
                          visitor['phone'],
                        ),
                        _buildDetailText(
                          Icons.badge,
                          'ID/Card No',
                          visitor['id_card_no'],
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

  Widget _buildBadge(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailText(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            '$label : ',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyVisitorTabsPlaceholder(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Shortened labels so they always fit on one line
    final tabLabels = ['Kunjungan', 'Tujuan', 'Kartu', 'Riwayat'];
    final subtextColor = theme.brightness == Brightness.dark
        ? const Color(0xFF718096)
        : Colors.grey[400]!;

    Widget emptyRow(IconData icon, String label) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, size: 18, color: subtextColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '-',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Obx(() {
      final selectedIndex = controller.rxSelectedTab.value;
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: theme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tab header — tappable, single-line labels
              Row(
                children: tabLabels.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final label = entry.value;
                  final isSelected = selectedIndex == idx;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => controller.rxSelectedTab.value = idx,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? colorScheme.primary
                                : subtextColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              // Two-column grid of placeholder rows
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        emptyRow(Icons.people_outline, 'Kode Tamu'),
                        emptyRow(Icons.person_outline, 'Diundang Oleh'),
                        emptyRow(Icons.format_list_numbered, 'Nomor Tamu'),
                        emptyRow(
                          Icons.directions_car_outlined,
                          'Jenis Kendaraan',
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    color: theme.dividerColor,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        emptyRow(
                          Icons.calendar_today_outlined,
                          'Diundang Oleh',
                        ),
                        emptyRow(Icons.group_outlined, 'Nama Grup'),
                        emptyRow(
                          Icons.assignment_turned_in_outlined,
                          'Status Tamu',
                        ),
                        emptyRow(
                          Icons.receipt_outlined,
                          'Nomor Plat Kendaraan',
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

  Widget _buildVisitorTabs(ThemeData theme, ColorScheme colorScheme) {
    return Obx(() {
      final visitor = controller.rxSelectedVisitor.value;
      if (visitor == null) {
        return _buildEmptyVisitorTabsPlaceholder(theme, colorScheme);
      }

      final selectedIndex = controller.rxSelectedTab.value;

      final tabLabels = ['Info', 'Details', 'Documents', 'Card', 'History'];

      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tabs selectors
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: tabLabels.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final label = entry.value;
                  final isSelected = selectedIndex == idx;
                  return GestureDetector(
                    onTap: () => controller.rxSelectedTab.value = idx,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? colorScheme.primary : Colors.grey,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Tab contents
              _buildTabContents(selectedIndex, visitor, theme),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTabContents(
    int index,
    Map<String, dynamic> visitor,
    ThemeData theme,
  ) {
    if (index == 0) {
      // Info
      return Column(
        children: [
          _buildTabInfoRow('Address', visitor['address']),
          _buildTabInfoRow('Organization', visitor['organization']),
          _buildTabInfoRow('Occupation', visitor['occupation']),
          _buildTabInfoRow(
            'ID Type / No',
            '${visitor['id_type']} / ${visitor['id_number']}',
          ),
        ],
      );
    } else if (index == 1) {
      // Visit Details
      return Column(
        children: [
          _buildTabInfoRow('Purpose', visitor['visit_purpose']),
          _buildTabInfoRow('Host (PIC)', visitor['host']),
          _buildTabInfoRow('Department', visitor['department']),
          _buildTabInfoRow('Period', visitor['visit_period']),
          _buildTabInfoRow('Created By', visitor['created_by']),
        ],
      );
    } else if (index == 2) {
      // Documents (mock signed files list)
      return Column(
        children: [
          _buildDocRow('Signed NDA Contract.pdf', 'Signed 09:35', Colors.green),
          _buildDocRow('Visitor Form.pdf', 'Signed 09:36', Colors.green),
          _buildDocRow('Vaccination Certificate.jpg', 'Uploaded', Colors.blue),
        ],
      );
    } else if (index == 3) {
      // Card Status
      return Column(
        children: [
          _buildTabInfoRow('Card Status', 'Active & Registered'),
          _buildTabInfoRow('Card ID Ref', visitor['id_card_no']),
          _buildTabInfoRow('Swipe Count', '4 Swipes Today'),
        ],
      );
    } else {
      // History list
      return Column(
        children: [
          _buildHistoryRow(
            'Checked In',
            'Lobby A - Gates',
            '14 Jan 2026, 09:47',
          ),
          _buildHistoryRow(
            'Created Registration',
            'Portal Pre-Reg',
            '12 Jan 2026, 14:15',
          ),
        ],
      );
    }
  }

  Widget _buildTabInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocRow(String name, String status, Color color) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.picture_as_pdf, color: color, size: 20),
      title: Text(
        name,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(status, style: const TextStyle(fontSize: 10)),
      trailing: const Icon(Icons.download, size: 16),
    );
  }

  Widget _buildHistoryRow(String action, String gate, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          const Icon(Icons.history, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  gate,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
            : Colors.grey[500]!;
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: theme.cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kode QR Tamu',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Placeholder box for QR area
                    Container(
                      width: 100,
                      height: 110,
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF161B26)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.document_scanner_outlined,
                            size: 36,
                            color: subtextColor,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tidak Ada\nQR/Kartu',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 9, color: subtextColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Scan tamu untuk\nmenampilkan QR',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 8, color: subtextColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQrDetailRow('Kode Undangan', '-'),
                          _buildQrDetailRow('Waktu Check In', '-'),
                          _buildQrDetailRow('Waktu Check Out', '-'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'qr_code'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: QrImageView(
                      data: visitor['qr_code_data'] ?? 'VMS-TICKET',
                      version: QrVersions.auto,
                      size: 90.0,
                    ),
                  ),
                  const SizedBox(width: 16),
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
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
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
                              fontSize: 10,
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
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
          const Text(' : ', style: TextStyle(fontSize: 10, color: Colors.grey)),
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

  // --- Center Panel Actions Grid ---
  Widget _buildQuickActionsGrid(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A2: Quick Actions header row dengan Edit icon
            Row(
              children: [
                Text(
                  'quick_actions'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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
                      'Fitur kustomisasi aksi akan segera hadir.',
                      snackPosition: SnackPosition.BOTTOM,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.3,
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
                  () => Get.snackbar('Parking Lot', 'Pendaftaran tiket parkir...'),
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
                  () => Get.snackbar('VMS Registration', 'Membuka formulir Pre-Registration...'),
                ),
                _buildActionTile(
                  Icons.directions_walk_rounded,
                  'Walk In',
                  Colors.blue[600]!,
                  () => Get.snackbar('VMS Registration', 'Membuka formulir walk-in...'),
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
                  () => Get.snackbar('Log', 'Membuka log kedatangan...'),
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
                  () => Get.snackbar('Print', 'Mencetak dokumen tamu...'),
                ),
                _buildActionTile(
                  Icons.block,
                  'Blacklist',
                  Colors.grey[850]!,
                  () => controller.executeAction('blacklist'),
                ),
                // Row 4
                _buildActionTile(
                  Icons.credit_card,
                  'Card Issuance',
                  Colors.purple,
                  () => Get.snackbar('RFID Integration', 'Menerbitkan kartu tamu...'),
                ),
                _buildActionTile(
                  Icons.credit_card_off_outlined,
                  'Card Return',
                  Colors.purple[300]!,
                  () => Get.snackbar('RFID Integration', 'Mengembalikan kartu tamu...'),
                ),
                _buildActionTile(
                  Icons.edit_note_outlined,
                  'Enable Edit',
                  Colors.deepPurple[300]!,
                  () => Get.snackbar('Edit Mode', 'Mode edit diaktifkan...'),
                ),
                // Row 5 (last row, single item)
                _buildActionTile(
                  Icons.key,
                  'Access Issuance',
                  Colors.orange,
                  () => Get.snackbar('Security Access', 'Mengakses panel kontrol pintu...'),
                ),
                _buildActionTile(
                  Icons.edit_document,
                  'Edit Form',
                  Colors.deepPurple[400]!,
                  () => Get.snackbar('Edit Form', 'Membuka formulir edit tamu...'),
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
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;
    final adjustedColor = (color == Colors.grey[850] && isDark)
        ? Colors.grey[300]!
        : color;

    return Material(
      color: adjustedColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: adjustedColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: adjustedColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Center Related Visitors Panel ---
  Widget _buildRelatedVisitorsPanel(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Tabs and Header
            Row(
              children: [
                const Text(
                  'Related Visitors (50)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Obx(
                  () => Row(
                    children: [
                      Checkbox(
                        value: controller.rxSelectMultiple.value,
                        onChanged: (val) {
                          controller.rxSelectMultiple.value = val ?? false;
                          if (val == false) controller.clearSelectedItems();
                        },
                      ),
                      const Text(
                        'Select Multiple',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list, size: 14),
                  label: const Text('Filter', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const Divider(),

            // Grid of visitors
            SizedBox(
              height: 220,
              child: Obx(() {
                final visitors = controller.rxRelatedVisitors;
                if (visitors.isEmpty) {
                  return const Center(child: Text('Data kosong'));
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.8,
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
                          } else {
                            // select for detail focus
                            // for demo, Maza Instansi is selected
                          }
                        },
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? colorScheme.primary
                                  : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Stack(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          colorScheme.secondaryContainer,
                                      backgroundImage: NetworkImage(
                                        item['avatar'] ?? '',
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      company,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 8,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                    ),
                                  ],
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
                                      size: 14,
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

            // A4: Action Bar — muncul di bawah panel saat multi-select aktif (Tablet: melekat di card, bukan floating)
            Obx(() {
              if (!controller.rxSelectMultiple.value ||
                  controller.rxSelectedItems.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${controller.rxSelectedItems.length} dipilih',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => controller.executeAction('check_in'),
                        icon: const Icon(
                          Icons.login,
                          size: 14,
                          color: Colors.green,
                        ),
                        label: const Text(
                          'Check-In',
                          style: TextStyle(fontSize: 11, color: Colors.green),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => controller.executeAction('check_out'),
                        icon: const Icon(
                          Icons.logout,
                          size: 14,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Check-Out',
                          style: TextStyle(fontSize: 11, color: Colors.red),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          controller.clearSelectedItems();
                          controller.rxSelectMultiple.value = false;
                        },
                        icon: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.grey,
                        ),
                        label: const Text(
                          'Batal',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informasi Host',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Large circular profile/avatar matching image
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(
                      0xFF78909C,
                    ), // Slate blue/grey placeholder
                    backgroundImage: hostAvatar != null && hostAvatar.isNotEmpty
                        ? NetworkImage(hostAvatar)
                        : null,
                    child: hostAvatar == null || hostAvatar.isEmpty
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 40,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hostName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hostDept,
                          style: TextStyle(color: subtextColor, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        // Phone Row
                        Row(
                          children: [
                            Icon(
                              Icons.phone_in_talk_outlined,
                              size: 14,
                              color: subtextColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ':  $hostPhone',
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Email Row
                        Row(
                          children: [
                            Icon(
                              Icons.mail_outline_rounded,
                              size: 14,
                              color: subtextColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ':  $hostEmail',
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28, thickness: 1),
              // Horizontal row of buttons matching the image layout
              Row(
                children: [
                  Expanded(
                    child: _buildHostActionIconButton(
                      icon: Icons.phone_in_talk_outlined,
                      label: 'Call',
                      bgColor: const Color(0xFF7CA1C4), // Muted slate-blue
                      onTap: () => Get.snackbar('Call', 'Menghubungi host...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHostActionIconButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Chat',
                      bgColor: const Color(0xFF80EED2), // Mint green
                      onTap: () =>
                          Get.snackbar('Chat', 'Mengirim chat ke host...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHostActionIconButton(
                      icon: Icons.mail_outline_rounded,
                      label: 'Email',
                      bgColor: const Color(0xFF9AD5FA), // Light sky blue
                      onTap: () =>
                          Get.snackbar('Email', 'Mengirim email ke host...'),
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
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'live_occupancy'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Today',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(
              () => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        border: Border.all(color: color.withOpacity(0.12), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 9),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gambar Identitas',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: docUrl != null && docUrl.isNotEmpty
                    ? Image.network(
                        docUrl,
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildNoIdentityImagePlaceholder(theme),
                      )
                    : _buildNoIdentityImagePlaceholder(theme),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNoIdentityImagePlaceholder(ThemeData theme) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF161B26)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
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
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'alerts'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  'View All',
                  style: TextStyle(color: Colors.blue, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(
              () => Column(
                children: controller.rxAlerts.map((alert) {
                  final isCritical = alert['critical'] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCritical ? Colors.red[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
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
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert['message'],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isCritical
                                      ? Colors.red[900]
                                      : Colors.orange[900],
                                ),
                              ),
                              Text(
                                alert['subText'],
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isCritical
                                      ? Colors.red[700]
                                      : Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          alert['time'],
                          style: const TextStyle(
                            fontSize: 9,
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

  // --- A3: Timeline Card (Tablet style \u2014 wrapped in Card, compact rows) ---
  Widget _buildTimelineCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'visit_timeline'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
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
                  child: const Text('View All', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(
              () => Column(
                children: controller.rxTimeline.map((item) {
                  final color = _getTimelineColor(item['status']);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getTimelineIcon(item['status']),
                            color: color,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          item['time'],
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item['title'],
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                item['desc'],
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
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
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Scanning Camera',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_front),
              title: const Text('Front Camera'),
              onTap: () {
                Get.back();
                Get.snackbar('Scan QR', 'Membuka kamera depan...');
                if (controller.rxAllRelatedVisitors.isNotEmpty) {
                  controller.rxSelectedVisitor.value =
                      controller.rxAllRelatedVisitors[0];
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_rear),
              title: const Text('Rear Camera'),
              onTap: () {
                Get.back();
                Get.snackbar('Scan QR', 'Membuka kamera belakang...');
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
              onTap: () {
                Get.back();
                Get.snackbar('Scan QR', 'Membuka USB camera...');
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
              onTap: () {
                Get.back();
                Get.snackbar('Scan QR', 'Menghubungkan IP camera feed...');
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
      ), // replacing surfaceVariant
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
