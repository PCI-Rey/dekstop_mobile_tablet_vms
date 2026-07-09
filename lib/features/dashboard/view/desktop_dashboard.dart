import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../controller/dashboard_controller.dart';
import '../../../core/shared/routes/app_pages.dart';

class DesktopDashboard extends GetView<DashboardController> {
  const DesktopDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.2),
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
                            _buildSelectedVisitorCard(theme, colorScheme),
                            const SizedBox(height: 16),
                            _buildVisitorTabs(theme, colorScheme),
                            const SizedBox(height: 16),
                            _buildQrCodeCard(theme, colorScheme),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Center Column (Actions grid & Related visitors list)
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _buildQuickActionsGrid(context, theme, colorScheme),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _buildRelatedVisitorsPanel(
                              theme,
                              colorScheme,
                            ),
                          ),
                        ],
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
              child: TextFormField(
                initialValue: controller.rxSearchQuery.value,
                onChanged: (val) => controller.rxSearchQuery.value = val,
                decoration: InputDecoration(
                  hintText: 'search_visitor_hint'.tr,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
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
            icon: const Icon(Icons.dark_mode_outlined),
            onPressed: () {
              Get.changeThemeMode(
                Get.isDarkMode ? ThemeMode.light : ThemeMode.dark,
              );
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

  Widget _buildVisitorTabs(ThemeData theme, ColorScheme colorScheme) {
    return Obx(() {
      final visitor = controller.rxSelectedVisitor.value;
      if (visitor == null) return const SizedBox.shrink();

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
      if (visitor == null) return const SizedBox.shrink();

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
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          Text(
            val,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
            Text(
              'quick_actions'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.6,
              children: [
                _buildActionTile(
                  Icons.qr_code_scanner,
                  'action_scan_qr'.tr,
                  Colors.blue,
                  () {
                    _showCameraChoiceBottomSheet(context);
                  },
                ),
                _buildActionTile(
                  Icons.directions_walk_rounded,
                  'action_walkin'.tr,
                  Colors.indigo,
                  () {
                    Get.snackbar(
                      'VMS Registration',
                      'Membuka formulir walk-in...',
                    );
                  },
                ),
                _buildActionTile(
                  Icons.how_to_reg,
                  'Pre-Regist',
                  Colors.indigoAccent,
                  () {
                    Get.snackbar(
                      'VMS Registration',
                      'Membuka formulir Pre-Registration...',
                    );
                  },
                ),
                _buildActionTile(
                  Icons.login,
                  'action_check_in'.tr,
                  Colors.green,
                  () {
                    controller.executeAction('check_in');
                  },
                ),
                _buildActionTile(
                  Icons.logout,
                  'action_check_out'.tr,
                  Colors.red,
                  () {
                    controller.executeAction('check_out');
                  },
                ),
                _buildActionTile(
                  Icons.credit_card,
                  'action_swipe_card'.tr,
                  Colors.purple,
                  () {
                    Get.snackbar('RFID Integration', 'Membaca sensor kartu...');
                  },
                ),
                _buildActionTile(
                  Icons.key,
                  'action_access_control'.tr,
                  Colors.orange,
                  () {
                    Get.snackbar(
                      'Security Access',
                      'Mengakses panel kontrol pintu...',
                    );
                  },
                ),
                _buildActionTile(
                  Icons.local_parking,
                  'action_parking'.tr,
                  Colors.teal,
                  () {
                    Get.snackbar('Parking Lot', 'Pendaftaran tiket parkir...');
                  },
                ),
                _buildActionTile(
                  Icons.door_sliding_outlined,
                  'action_open_door'.tr,
                  Colors.deepOrange,
                  () {
                    controller.executeAction('open_door');
                  },
                ),
                _buildActionTile(
                  Icons.restore,
                  'action_arrival_log'.tr,
                  Colors.greenAccent[700]!,
                  () {
                    Get.snackbar('Log', 'Membuka log kedatangan...');
                  },
                ),
                _buildActionTile(
                  Icons.update,
                  'action_extend_visit'.tr,
                  Colors.amber[800]!,
                  () {
                    controller.executeAction('extend_visit');
                  },
                ),
                _buildActionTile(
                  Icons.block,
                  'action_blacklist'.tr,
                  Colors.grey[850]!,
                  () {
                    controller.executeAction('blacklist');
                  },
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
    return Material(
      color: color.withOpacity(0.08),
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
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
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
            Expanded(
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
          ],
        ),
      ),
    );
  }

  // --- Right Panel widgets ---
  Widget _buildHostInfoCard(ThemeData theme, ColorScheme colorScheme) {
    return Obx(() {
      final visitor = controller.rxSelectedVisitor.value;
      if (visitor == null) return const SizedBox.shrink();

      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Host Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(visitor['host_avatar'] ?? ""),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visitor['host'] ?? "",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${visitor['host_title']} | ${visitor['host_phone']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Available',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildHostActionBtn(Icons.call, 'Call', Colors.blue, () {}),
                  _buildHostActionBtn(
                    Icons.chat_bubble_outline,
                    'Chat',
                    Colors.green,
                    () {},
                  ),
                  _buildHostActionBtn(
                    Icons.mail_outline,
                    'Email',
                    Colors.grey,
                    () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHostActionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: color),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      if (visitor == null) return const SizedBox.shrink();

      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'identity_card'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  visitor['identity_doc_url'] ?? "",
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.credit_card,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
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
