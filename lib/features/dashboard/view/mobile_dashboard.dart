import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controller/dashboard_controller.dart';
import '../../../core/shared/routes/app_pages.dart';
import '../../../core/services/storage_service.dart';
import '../../scan/view/mobile_scanner_view.dart';

class MobileDashboard extends GetView<DashboardController> {
  const MobileDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      // Floating Scan Button in the center (FAB)
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openConfiguredCamera(context),
        backgroundColor: Colors.blueAccent,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavigationBar(context, colorScheme),

      // Main Body
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header Search & Actions (Fixed floating at the top)
                _buildHeader(context, theme, colorScheme),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          // Selected Visitor Card
                          _buildSelectedVisitorCard(theme, colorScheme),
                          const SizedBox(height: 20),

                          // Quick Actions Section
                          _buildQuickActionsHeader(context, theme),
                          const SizedBox(height: 8),
                          _buildQuickActionsGrid(context, theme, colorScheme),
                          const SizedBox(height: 20),

                          // Live Occupancy row list
                          _buildOccupancySection(theme, colorScheme),
                          const SizedBox(height: 20),

                          // Related Visitors Row
                          _buildRelatedVisitorsRow(context, theme, colorScheme),
                          const SizedBox(height: 20),

                          // Visit Timeline
                          _buildTimelineSection(theme, colorScheme),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Floating Quick Access Bar
            Obx(() {
              if (controller.rxSelectMultiple.value &&
                  controller.rxSelectedItems.isNotEmpty) {
                return Positioned(
                  bottom: 76, // Float above bottom navigation bar
                  left: 16,
                  right: 16,
                  child: _buildQuickAccessBar(context),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  // --- Header: Hamburger, Search Field, Notifications, Expand screen ---
  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Open drawer mock
              Get.toNamed(AppRoutes.profile);
            },
          ),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextFormField(
                onChanged: (val) => controller.rxSearchQuery.value = val,
                decoration: InputDecoration(
                  hintText: 'Search visitor by name, code or email',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: Colors.grey,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () => Get.toNamed(AppRoutes.noInternet),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: () => Get.toNamed(AppRoutes.configure),
          ),
        ],
      ),
    );
  }

  // --- Selected Visitor Card ---
  Widget _buildSelectedVisitorCard(ThemeData theme, ColorScheme colorScheme) {
    return Obx(() {
      final visitor = controller.rxSelectedVisitor.value;
      if (visitor == null) {
        return Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 16.0,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.blueAccent,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Belum Ada Data Scan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Silakan scan QR code pengunjung atau pilih salah satu tamu di bawah untuk memuat informasi.',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo and Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          visitor['avatar'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: colorScheme.primary.withOpacity(0.1),
                            width: 80,
                            height: 80,
                            child: Icon(
                              Icons.person,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.circle,
                                    color: Colors.green,
                                    size: 6,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Checked In',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              visitor['name'],
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildBadge(
                              'VIP VISITOR',
                              Colors.purple,
                              Colors.purple[50]!,
                            ),
                            const SizedBox(width: 4),
                            _buildBadge(
                              'FREQUENT VISITOR',
                              Colors.blue,
                              Colors.blue[50]!,
                            ),
                            const SizedBox(width: 4),
                            _buildBadge(
                              'VERIFIED',
                              Colors.green,
                              Colors.green[50]!,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Key/Value details
              _buildInfoRow('Company', visitor['company']),
              _buildInfoRow('Phone', visitor['phone']),
              _buildInfoRow('Email', visitor['email']),
              _buildInfoRow('ID / Card No', visitor['id_card_no']),
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

  Widget _buildInfoRow(String label, String? val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.business, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              val ?? '-',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // --- Quick Actions Header and Grid ---
  Widget _buildQuickActionsHeader(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'quick_actions'.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () => _showEditActionsBottomSheet(context),
          child: const Text('Edit', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Obx(() {
      final activeActions = controller.rxQuickActions
          .where((a) => a['enabled'] == true)
          .toList();

      if (activeActions.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No active quick actions. Click Edit to add.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        );
      }

      final screenWidth = MediaQuery.of(context).size.width;

      int crossAxisCount = 3;
      double spacing = 10;
      double aspectRatio = 1.3;

      if (screenWidth >= 900) {
        crossAxisCount = 6;
        spacing = 6;
        aspectRatio = 1.4;
      } else if (screenWidth >= 700) {
        crossAxisCount = 5;
        spacing = 8;
        aspectRatio = 1.35;
      } else if (screenWidth >= 480) {
        crossAxisCount = 4;
        spacing = 8;
        aspectRatio = 1.3;
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: aspectRatio,
        ),
        itemCount: activeActions.length,
        itemBuilder: (context, index) {
          final action = activeActions[index];
          final label = action['label'] as String;
          final iconName = action['icon'] as String;
          final colorKey = action['color'] as String;

          final icon = _mapIcon(iconName);
          final color = _mapColor(colorKey);

          return Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[100]!),
            ),
            child: InkWell(
              onTap: () {
                if (label.contains('Scan')) {
                  _openConfiguredCamera(context);
                } else if (label.contains('In')) {
                  controller.executeAction('check_in');
                } else if (label.contains('Out')) {
                  controller.executeAction('check_out');
                } else {
                  Get.snackbar(
                    'Action Integration',
                    'Menjalankan aksi $label...',
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  void _showEditActionsBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Obx(
        () => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Quick Actions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Aktifkan atau nonaktifkan menu aksi cepat pada dashboard:',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.rxQuickActions.length,
                  itemBuilder: (context, index) {
                    final action = controller.rxQuickActions[index];
                    final label = action['label'] as String;
                    final isEnabled = action['enabled'] as bool;
                    final iconName = action['icon'] as String;
                    final colorKey = action['color'] as String;

                    return CheckboxListTile(
                      secondary: Icon(
                        _mapIcon(iconName),
                        color: _mapColor(colorKey),
                      ),
                      title: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      value: isEnabled,
                      onChanged: (val) {
                        if (val != null) {
                          final listCopy = List<Map<String, dynamic>>.from(
                            controller.rxQuickActions,
                          );
                          listCopy[index] = {
                            ...listCopy[index],
                            'enabled': val,
                          };
                          controller.rxQuickActions.value = listCopy;
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  IconData _mapIcon(String name) {
    switch (name) {
      case 'qr_code_scanner':
        return Icons.qr_code_scanner;
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'credit_card':
        return Icons.credit_card;
      case 'key':
        return Icons.key;
      case 'local_parking':
        return Icons.local_parking;
      case 'door_sliding_outlined':
        return Icons.door_sliding_outlined;
      case 'update':
        return Icons.update;
      case 'restore':
        return Icons.restore;
      case 'block':
        return Icons.block;
      case 'check_circle':
        return Icons.check_circle;
      case 'directions_walk':
        return Icons.directions_walk;
      default:
        return Icons.star;
    }
  }

  Color _mapColor(String key) {
    switch (key) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'teal':
        return Colors.teal;
      case 'deepOrange':
        return Colors.deepOrange;
      case 'amber':
        return Colors.amber[800]!;
      case 'greenAccent':
        return Colors.greenAccent[700]!;
      case 'grey':
        return Colors.grey[850]!;
      case 'indigo':
        return Colors.indigo;
      default:
        return Colors.blueGrey;
    }
  }

  // --- Live Occupancy Row ---
  Widget _buildOccupancySection(ThemeData theme, ColorScheme colorScheme) {
    return Obx(() {
      final employees = controller.rxOccupancy['employees'] ?? 0;
      final visitors = controller.rxOccupancy['visitors'] ?? 0;
      final contractors = controller.rxOccupancy['contractors'] ?? 0;
      final vehicles = controller.rxOccupancy['vehicles'] ?? 0;

      return LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;

          int crossAxisCount = 2;
          double spacing = 10;
          double aspectRatio = 2.5;

          if (screenWidth >= 700) {
            crossAxisCount = 4;
            spacing = 8;
            aspectRatio = 3.2;
          } else if (screenWidth >= 480) {
            crossAxisCount = 3;
            spacing = 8;
            aspectRatio = 2.8;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'live_occupancy'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: aspectRatio,
                children: [
                  _buildOccupancyTile(
                    'Employees',
                    employees.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                  _buildOccupancyTile(
                    'Visitors',
                    visitors.toString(),
                    Icons.person_pin_circle,
                    Colors.green,
                  ),
                  _buildOccupancyTile(
                    'Contractors',
                    contractors.toString(),
                    Icons.engineering,
                    Colors.orange,
                  ),
                  _buildOccupancyTile(
                    'Vehicles',
                    vehicles.toString(),
                    Icons.local_shipping,
                    Colors.purple,
                  ),
                ],
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildOccupancyTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[100]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[500], fontSize: 8),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
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

  // --- Related Visitors row ---
  Widget _buildRelatedVisitorsRow(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Related Visitors (50)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Obx(
                  () => IconButton(
                    icon: Icon(
                      controller.rxSelectMultiple.value
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 18,
                    ),
                    onPressed: () {
                      controller.rxSelectMultiple.toggle();
                      if (!controller.rxSelectMultiple.value) {
                        controller.clearSelectedItems();
                      }
                    },
                  ),
                ),
                TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.visitorList),
                  child: const Text('View All', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          final visitors = controller.rxRelatedVisitors;
          if (visitors.isEmpty) return const SizedBox.shrink();

          final displayCount = visitors.length > 3 ? 3 : visitors.length;
          final screenWidth = MediaQuery.of(context).size.width;

          int crossAxisCount = 4;
          double spacing = 6;
          double aspectRatio = 0.9;

          if (screenWidth >= 900) {
            crossAxisCount = 8;
            spacing = 6;
            aspectRatio = 1.0;
          } else if (screenWidth >= 700) {
            crossAxisCount = 6;
            spacing = 6;
            aspectRatio = 0.95;
          } else if (screenWidth >= 480) {
            crossAxisCount = 5;
            spacing = 6;
            aspectRatio = 0.95;
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: aspectRatio,
            ),
            itemCount: displayCount + 1,
            itemBuilder: (context, index) {
              if (index == displayCount) {
                // "+47 More" Circle avatar
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue[50],
                      child: const Text(
                        '+47',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'More',
                      style: TextStyle(fontSize: 9, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              }

              final visitor = visitors[index];
              return Obx(() {
                final isSelected = controller.rxSelectedItems.contains(
                  visitor['name'],
                );
                return InkWell(
                  onTap: () {
                    if (controller.rxSelectMultiple.value) {
                      controller.toggleSelectItem(visitor['name']);
                    } else {
                      controller.rxSelectedVisitor.value = visitor;
                      _showVisitorInfoBottomSheet(context, visitor);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(visitor['avatar']),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            visitor['name'],
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            visitor['date'] ?? '',
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      if (controller.rxSelectMultiple.value)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSelected
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: isSelected
                                  ? Colors.blueAccent
                                  : Colors.grey,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              });
            },
          );
        }),
      ],
    );
  }

  // --- Visit Timeline list ---
  Widget _buildTimelineSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'visit_timeline'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Get.toNamed(AppRoutes.visitorDetail),
              child: const Text('View All', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(
          () => Column(
            children: controller.rxTimeline.map((item) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getTimelineColor(
                            item['status'],
                          ).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getTimelineIcon(item['status']),
                          color: _getTimelineColor(item['status']),
                          size: 14,
                        ),
                      ),
                      // Line
                      Container(width: 2, height: 28, color: Colors.grey[200]),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item['time'],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          item['desc'],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
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

  // --- Bottom Dock Navigation Bar layout ---
  Widget _buildBottomNavigationBar(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return BottomAppBar(
      notchMargin: 6,
      shape: const CircularNotchedRectangle(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.home, 'Dashboard', 0, colorScheme),
            _buildNavItem(
              Icons.people_outline,
              'Visitors',
              1,
              colorScheme,
              onTap: () => Get.toNamed(AppRoutes.visitorList),
            ),
            const SizedBox(width: 48), // gap for scan button
            _buildNavItem(Icons.mail_outline, 'Invitations', 2, colorScheme),
            _buildNavItem(
              Icons.more_horiz,
              'More',
              3,
              colorScheme,
              onTap: () => Get.toNamed(AppRoutes.configure),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    ColorScheme colorScheme, {
    VoidCallback? onTap,
  }) {
    final isSelected = controller.rxMobileNavIndex.value == index;
    return InkWell(
      onTap: onTap ?? () => controller.rxMobileNavIndex.value = index,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : Colors.grey,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.primary : Colors.grey,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Direct Camera Launcher based on user configuration settings ---
  void _openConfiguredCamera(BuildContext context) async {
    final storage = Get.find<StorageService>();
    final cameraData = await storage.getCameraConfig();
    final cameraName = cameraData?['name'] ?? 'Rear Camera';

    // Determine default camera facing based on config settings
    CameraFacing facing = CameraFacing.back;
    if (cameraName.toLowerCase().contains('front')) {
      facing = CameraFacing.front;
    }

    // Go to scanner page and await result
    final scannedValue = await Get.to<String>(
      () => MobileScannerPage(initialFacing: facing),
    );

    if (scannedValue != null && scannedValue.isNotEmpty) {
      Get.snackbar(
        'Scan QR Berhasil',
        'Payload QR: $scannedValue',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );

      // Auto-trigger search in DashboardController
      controller.rxSearchQuery.value = scannedValue;

      // Find matching visitor and select immediately to show the full profile details card
      final matchingVisitor = controller.rxAllRelatedVisitors.firstWhere(
        (v) {
          // (v['name'] as String).toLowerCase().contains(
          //     scannedValue.toLowerCase(),
          //   ) ||
          //   (v['ticket_no'] as String).toLowerCase().contains(
          //     scannedValue.toLowerCase(),
          //   ) ||
          //   (v['qr_code_data'] as String).toLowerCase().contains(
          //     scannedValue.toLowerCase(),
          //   )
          return (v['name'] as String).toLowerCase().contains(
            scannedValue.toLowerCase(),
          );
        },
        orElse: () => controller.rxAllRelatedVisitors.isNotEmpty
            ? controller.rxAllRelatedVisitors.first
            : <String, dynamic>{},
      );

      if (matchingVisitor.isNotEmpty) {
        controller.rxSelectedVisitor.value = matchingVisitor;
      }
    }
  }

  // --- Click to show visitor info Bottom Sheet details ---
  void _showVisitorInfoBottomSheet(
    BuildContext context,
    Map<String, dynamic> visitor,
  ) {
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
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(visitor['avatar']),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visitor['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        visitor['company'] ?? 'No Company',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Informasi Umum Tamu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildVisitorDetailRow(
              Icons.phone,
              'Nomor Telepon',
              visitor['phone'] ?? '-',
            ),
            _buildVisitorDetailRow(
              Icons.email,
              'Alamat Email',
              visitor['email'] ?? '-',
            ),
            _buildVisitorDetailRow(
              Icons.badge,
              'ID / No. Kartu',
              visitor['id_card_no'] ?? '-',
            ),
            _buildVisitorDetailRow(
              Icons.calendar_today,
              'Tanggal Kunjungan',
              visitor['date'] ?? '-',
            ),
            _buildVisitorDetailRow(
              Icons.info_outline,
              'Status Kunjungan',
              visitor['status'] ?? 'Scheduled',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // --- Dynamic Quick Access Bar based on check-in state rules ---
  Widget _buildQuickAccessBar(BuildContext context) {
    final selectedVisitors = controller.rxAllRelatedVisitors
        .where((v) => controller.rxSelectedItems.contains(v['name']))
        .toList();
    final anyNotCheckedIn = selectedVisitors.any(
      (v) => v['status'] != 'Checked In',
    );

    return Card(
      color: Colors.grey[900],
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${controller.rxSelectedItems.length} Tamu Terpilih',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Text(
                  'Quick Access',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
            const Spacer(),

            // Dynamic actions
            if (anyNotCheckedIn) ...[
              _buildQuickActionButton(
                icon: Icons.login,
                label: 'Check In',
                color: Colors.greenAccent,
                onTap: () => _executeBulkAction('check_in'),
              ),
              const SizedBox(width: 8),
            ] else ...[
              _buildQuickActionButton(
                icon: Icons.logout,
                label: 'Check Out',
                color: Colors.redAccent,
                onTap: () => _executeBulkAction('check_out'),
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: Icons.credit_card,
                label: 'Card',
                color: Colors.purpleAccent,
                onTap: () => _executeBulkAction('issue_card'),
              ),
              const SizedBox(width: 8),
            ],
            _buildQuickActionButton(
              icon: Icons.block,
              label: 'Block',
              color: Colors.orangeAccent,
              onTap: () => _executeBulkAction('block'),
            ),
            const SizedBox(width: 8),
            _buildQuickActionButton(
              icon: Icons.gavel,
              label: 'Blacklist',
              color: Colors.red,
              onTap: () => _executeBulkAction('blacklist'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  void _executeBulkAction(String action) {
    final names = controller.rxSelectedItems.toList();
    controller.clearSelectedItems();
    controller.rxSelectMultiple.value = false;

    Get.snackbar(
      'Bulk Action Success',
      'Berhasil memproses $action untuk tamu: ${names.join(', ')}',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }
}
