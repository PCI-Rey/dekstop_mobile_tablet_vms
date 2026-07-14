import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../dashboard/controller/dashboard_controller.dart';

class RelatedVisitorsView extends StatelessWidget {
  const RelatedVisitorsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Today's Visitors"),
        actions: [
          Obx(() => IconButton(
                icon: Icon(
                  controller.rxSelectMultiple.value ? Icons.check_box : Icons.check_box_outline_blank,
                ),
                onPressed: () {
                  controller.rxSelectMultiple.toggle();
                  if (!controller.rxSelectMultiple.value) {
                    controller.clearSelectedItems();
                  }
                },
                tooltip: 'Select Multiple',
              )),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Search Bar & Filter
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextFormField(
                            onChanged: (val) => controller.rxSearchQuery.value = val,
                            decoration: InputDecoration(
                              hintText: 'Search by name or company...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: Obx(() => controller.rxSearchQuery.value.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () => controller.clearSearch(),
                                    )
                                  : const SizedBox.shrink()),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.tune),
                        onPressed: () => _showFilterBottomSheet(context, controller),
                      ),
                    ],
                  ),
                ),

                // Pagination Indicator Mock: < 1 / 5 >
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                  child: Row(
                    children: [
                      Obx(() => Text(
                            controller.rxSelectedItems.isNotEmpty
                                ? '${controller.rxSelectedItems.length} Terpilih'
                                : 'Filter: ${controller.rxActiveFilter.value} | Halaman ${controller.rxCurrentPage.value} dari ${controller.rxTotalPages.value}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          )),
                      const Spacer(),
                      Obx(() => IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        onPressed: controller.rxCurrentPage.value > 1
                            ? () => controller.rxCurrentPage.value--
                            : null,
                      )),
                      Obx(() => Text(
                        '${controller.rxCurrentPage.value} / ${controller.rxTotalPages.value}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      )),
                      Obx(() => IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20),
                        onPressed: controller.rxCurrentPage.value < controller.rxTotalPages.value
                            ? () => controller.rxCurrentPage.value++
                            : null,
                      )),
                    ],
                  ),
                ),
                const Divider(),

                // List / Grid with pull-to-refresh
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await controller.fetchDashboardData();
                    },
                    child: Obx(() {
                      final visitors = controller.rxRelatedVisitors;
                      if (visitors.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_search_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              const Text('Tidak ada pengunjung ditemukan', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      }

                      final screenWidth = MediaQuery.of(context).size.width;
                      
                      int crossAxisCount = 2;
                      double spacing = 6;
                      double aspectRatio = 0.95;
                      
                      if (screenWidth >= 900) {
                        crossAxisCount = 6;
                        spacing = 6;
                        aspectRatio = 1.0;
                      } else if (screenWidth >= 700) {
                        crossAxisCount = 5;
                        spacing = 6;
                        aspectRatio = 0.95;
                      } else if (screenWidth >= 480) {
                        crossAxisCount = 3;
                        spacing = 6;
                        aspectRatio = 0.95;
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount: visitors.length,
                    itemBuilder: (context, index) {
                      final item = visitors[index];
                      final name = item['name'] as String;
                      final company = item['company'] as String;
                      
                      return Obx(() {
                        final isSelected = controller.rxSelectedItems.contains(name);
                        
                        return Card(
                          color: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected ? colorScheme.primary : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: InkWell(
                             onTap: () {
                               if (controller.rxSelectMultiple.value) {
                                 controller.toggleSelectItem(name);
                               } else {
                                 _showActionMenu(context, item);
                               }
                             },
                             borderRadius: BorderRadius.circular(12),
                             child: Padding(
                               padding: const EdgeInsets.all(12.0),
                               child: Stack(
                                 children: [
                                   Column(
                                     mainAxisAlignment: MainAxisAlignment.center,
                                     crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundImage: NetworkImage(item['avatar']),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        company,
                                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item['date'] ?? '',
                                        style: TextStyle(color: colorScheme.primary, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  if (controller.rxSelectMultiple.value)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Icon(
                                        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                        color: isSelected ? colorScheme.primary : Colors.grey,
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
            ),
          ],
        ),
        
        // Floating Quick Access Bar
        Obx(() {
          if (controller.rxSelectMultiple.value && controller.rxSelectedItems.isNotEmpty) {
            return Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildQuickAccessBar(context, controller),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    ),
  ),
    );
  }

  // --- Show Action Menu Bottom Sheet when a single visitor is clicked ---
  void _showActionMenu(BuildContext context, Map<String, dynamic> visitor) {
    final controller = Get.find<DashboardController>();
    final isCheckedIn = visitor['status'] == 'Checked In';

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
                      Text(visitor['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(visitor['company'] ?? 'No Company', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // General Info Section
            const Text('Informasi Umum Tamu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            _buildVisitorDetailRow(Icons.phone, 'Nomor Telepon', visitor['phone'] ?? '-'),
            _buildVisitorDetailRow(Icons.email, 'Alamat Email', visitor['email'] ?? '-'),
            _buildVisitorDetailRow(Icons.badge, 'ID / No. Kartu', visitor['id_card_no'] ?? '-'),
            _buildVisitorDetailRow(Icons.calendar_today, 'Tanggal Kunjungan', visitor['date'] ?? '-'),
            _buildVisitorDetailRow(Icons.info_outline, 'Status Kunjungan', visitor['status'] ?? 'Scheduled'),
            
            const Divider(height: 24),
            
            const Text('Tindakan Cepat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (!isCheckedIn) ...[
                  _buildSheetActionItem(Icons.login, 'Check In', Colors.green, () {
                    Get.back();
                    controller.executeAction('check_in');
                  }),
                ] else ...[
                  _buildSheetActionItem(Icons.logout, 'Check Out', Colors.red, () {
                    Get.back();
                    controller.executeAction('check_out');
                  }),
                  _buildSheetActionItem(Icons.credit_card, 'Issue Card', Colors.purple, () {
                    Get.back();
                    Get.snackbar('Issue Card', 'Kartu berhasil didaftarkan...');
                  }),
                ],
                _buildSheetActionItem(Icons.print, 'Print Badge', Colors.blue, () {
                  Get.back();
                  Get.snackbar('Cetak', 'Mengirim perintah cetak badge...');
                }),
                _buildSheetActionItem(Icons.door_back_door, 'Open Door', Colors.deepOrange, () {
                  Get.back();
                  controller.executeAction('open_door');
                }),
                _buildSheetActionItem(Icons.block, 'Block', Colors.orange, () {
                  Get.back();
                  controller.executeAction('blacklist');
                }),
                _buildSheetActionItem(Icons.gavel, 'Blacklist', Colors.red, () {
                  Get.back();
                  controller.executeAction('blacklist');
                }),
              ],
            )
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildVisitorDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildQuickAccessBar(BuildContext context, DashboardController controller) {
    final selectedVisitors = controller.rxAllRelatedVisitors.where((v) => controller.rxSelectedItems.contains(v['name'])).toList();
    final anyNotCheckedIn = selectedVisitors.any((v) => v['status'] != 'Checked In');

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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
              _buildQuickAccessActionButton(
                icon: Icons.login,
                label: 'Check In',
                color: Colors.greenAccent,
                onTap: () => _executeBulkAction(controller, 'check_in'),
              ),
              const SizedBox(width: 8),
            ] else ...[
              _buildQuickAccessActionButton(
                icon: Icons.logout,
                label: 'Check Out',
                color: Colors.redAccent,
                onTap: () => _executeBulkAction(controller, 'check_out'),
              ),
              const SizedBox(width: 8),
              _buildQuickAccessActionButton(
                icon: Icons.credit_card,
                label: 'Card',
                color: Colors.purpleAccent,
                onTap: () => _executeBulkAction(controller, 'issue_card'),
              ),
              const SizedBox(width: 8),
            ],
            _buildQuickAccessActionButton(
              icon: Icons.block,
              label: 'Block',
              color: Colors.orangeAccent,
              onTap: () => _executeBulkAction(controller, 'block'),
            ),
            const SizedBox(width: 8),
            _buildQuickAccessActionButton(
              icon: Icons.gavel,
              label: 'Blacklist',
              color: Colors.red,
              onTap: () => _executeBulkAction(controller, 'blacklist'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessActionButton({
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
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 8)),
          ],
        ),
      ),
    );
  }

  void _executeBulkAction(DashboardController controller, String action) {
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

  Widget _buildSheetActionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          border: Border.all(color: color.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, DashboardController controller) {
    Get.bottomSheet(
      Obx(() {
        final currentFilter = controller.rxActiveFilter.value;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter Visitors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              _buildFilterOption('Semua Tamu', 'All', currentFilter, controller),
              _buildFilterOption('VIP Visitors', 'VIP', currentFilter, controller),
              _buildFilterOption('Frequent Visitors', 'Frequent', currentFilter, controller),
              _buildFilterOption('Verified Visitors', 'Verified', currentFilter, controller),
              const SizedBox(height: 12),
            ],
          ),
        );
      })
    );
  }

  Widget _buildFilterOption(String label, String value, String current, DashboardController controller) {
    final isSelected = value == current;
    return ListTile(
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blueAccent) : null,
      onTap: () {
        controller.rxActiveFilter.value = value;
        Get.back();
      },
    );
  }
}
