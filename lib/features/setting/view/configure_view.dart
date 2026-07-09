import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/setting_controller.dart';
import '../../../core/config/constants.dart';

class ConfigureView extends GetView<SettingController> {
  const ConfigureView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;

    return Scaffold(
      appBar: AppBar(
        title: Text('settings_title'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: isDesktop
          ? _buildDesktopLayout(context, theme, colorScheme)
          : _buildMobileLayout(context, theme, colorScheme),
    );
  }

  // --- Desktop Layout: Side Navigation Tab View ---
  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final activeTab = 0.obs; // GetX reactive index for tab selection

    final sections = [
      {'title': 'server_config'.tr, 'icon': Icons.dns_rounded},
      {'title': 'printer_config'.tr, 'icon': Icons.print_rounded},
      {'title': 'camera_config'.tr, 'icon': Icons.camera_alt_rounded},
      {'title': 'about'.tr, 'icon': Icons.info_outline_rounded},
      {'title': 'reset'.tr, 'icon': Icons.settings_backup_restore_rounded},
    ];

    return Row(
      children: [
        // Side Menu Pane
        Container(
          width: 260,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: colorScheme.outlineVariant, width: 0.8),
            ),
          ),
          child: ListView.builder(
            itemCount: sections.length,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemBuilder: (context, index) {
              final section = sections[index];
              return Obx(() {
                final isSelected = activeTab.value == index;
                return ListTile(
                  leading: Icon(
                    section['icon'] as IconData,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    section['title'] as String,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: colorScheme.primaryContainer.withOpacity(
                    0.3,
                  ),
                  onTap: () => activeTab.value = index,
                );
              });
            },
          ),
        ),

        // Settings Content Pane
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant, width: 0.8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: SingleChildScrollView(
                  child: Obx(() {
                    switch (activeTab.value) {
                      case 0:
                        return _buildServerConfig(theme, colorScheme);
                      case 1:
                        return _buildPrinterConfig(theme, colorScheme);
                      case 2:
                        return _buildCameraConfig(theme, colorScheme);
                      case 3:
                        return _buildAboutConfig(theme, colorScheme);
                      case 4:
                        return _buildResetConfig(theme, colorScheme);
                      default:
                        return const SizedBox.shrink();
                    }
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Mobile Layout: Standard Vertical List of Panels ---
  Widget _buildMobileLayout(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildMobileExpandableTile(
          title: 'server_config'.tr,
          icon: Icons.dns_rounded,
          colorScheme: colorScheme,
          child: _buildServerConfig(theme, colorScheme),
        ),
        const SizedBox(height: 12),
        _buildMobileExpandableTile(
          title: 'printer_config'.tr,
          icon: Icons.print_rounded,
          colorScheme: colorScheme,
          child: _buildPrinterConfig(theme, colorScheme),
        ),
        const SizedBox(height: 12),
        _buildMobileExpandableTile(
          title: 'camera_config'.tr,
          icon: Icons.camera_alt_rounded,
          colorScheme: colorScheme,
          child: _buildCameraConfig(theme, colorScheme),
        ),
        const SizedBox(height: 12),
        _buildMobileExpandableTile(
          title: 'about'.tr,
          icon: Icons.info_outline_rounded,
          colorScheme: colorScheme,
          child: _buildAboutConfig(theme, colorScheme),
        ),
        const SizedBox(height: 12),
        _buildMobileExpandableTile(
          title: 'reset'.tr,
          icon: Icons.settings_backup_restore_rounded,
          colorScheme: colorScheme,
          child: _buildResetConfig(theme, colorScheme),
        ),
      ],
    );
  }

  Widget _buildMobileExpandableTile({
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.8),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        childrenPadding: const EdgeInsets.all(16.0),
        expandedAlignment: Alignment.topLeft,
        children: [child],
      ),
    );
  }

  // ===================== Sub-Configuration Renderers =====================

  // 1. Server Configuration Panel
  Widget _buildServerConfig(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'server_config'.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Atur URL dasar tempat layanan API VMS berjalan.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: controller.serverUrlController,
          decoration: InputDecoration(
            labelText: 'server_url'.tr,
            prefixIcon: const Icon(Icons.link),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.apiEndpointController,
          enabled: false,
          decoration: InputDecoration(
            labelText: 'api_endpoint'.tr,
            prefixIcon: const Icon(Icons.api_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Obx(
              () => OutlinedButton.icon(
                onPressed: controller.rxIsTestingConnection.value
                    ? null
                    : () => controller.testConnection(),
                icon: controller.rxIsTestingConnection.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.network_ping),
                label: Text('connection_test'.tr),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => controller.saveServerConfig(),
              icon: const Icon(Icons.save),
              label: Text('save_config'.tr),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Printer Configuration Panel
  Widget _buildPrinterConfig(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'printer_config'.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sambungkan printer Bluetooth Thermal, USB, atau LAN.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),

        // Paper width select
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Lebar Kertas:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 4,
                children: ['58mm', '80mm'].map((width) {
                  final isSel = controller.rxPaperWidth.value == width;
                  return ChoiceChip(
                    label: Text(width),
                    selected: isSel,
                    onSelected: (_) => controller.changePaperWidth(width),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Interface select
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Antarmuka Printer:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 4,
                children: ['USB', 'LAN', 'Bluetooth'].map((iface) {
                  final isSel = controller.rxPrinterInterface.value == iface;
                  return ChoiceChip(
                    label: Text(iface),
                    selected: isSel,
                    onSelected: (_) =>
                        controller.changePrinterInterface(iface),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Conditional forms for Wired Printer Interfaces
        Obx(() {
          if (controller.rxPrinterInterface.value == 'LAN') {
            return Card(
              color: colorScheme.surfaceVariant.withOpacity(0.2),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pengaturan LAN Printer ESC/POS (Wired):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: controller.lanIpController,
                            onChanged: (_) =>
                                controller.selectPrinter('ESC/POS LAN Printer'),
                            decoration: const InputDecoration(
                              labelText: 'IP Address Printer',
                              hintText: '192.168.1.100',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: controller.lanPortController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) =>
                                controller.selectPrinter('ESC/POS LAN Printer'),
                            decoration: const InputDecoration(
                              labelText: 'Port',
                              hintText: '9100',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
          if (controller.rxPrinterInterface.value == 'USB') {
            return Card(
              color: colorScheme.surfaceVariant.withOpacity(0.2),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pengaturan USB Printer ESC/POS (Wired):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.usbPortController,
                      onChanged: (_) =>
                          controller.selectPrinter('ESC/POS USB Printer'),
                      decoration: const InputDecoration(
                        labelText: 'USB Port / COM Path',
                        hintText: 'COM3 atau /dev/usb/lp0',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        const SizedBox(height: 16),

        // Selected Printer Status
        Obx(
          () => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.print,
                  color: controller.rxSelectedPrinter.value != null
                      ? Colors.green
                      : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.rxSelectedPrinter.value ??
                        'Belum ada printer yang dipilih',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (controller.rxSelectedPrinter.value != null)
                  TextButton(
                    onPressed: () => controller.testPrint(),
                    child: Text('test_print'.tr),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Printer List
        Obx(() {
          if (controller.rxIsScanningPrinters.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (controller.rxPrintersList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: OutlinedButton.icon(
                  onPressed: () => controller.scanPrinters(),
                  icon: const Icon(Icons.search_rounded),
                  label: Text('scan_printer'.tr),
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Perangkat Terdeteksi:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => controller.scanPrinters(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text('scan_printer'.tr),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...controller.rxPrintersList.map((prt) {
                final isSelected =
                    controller.rxSelectedPrinter.value == prt['name'];
                return ListTile(
                  dense: true,
                  title: Text(
                    prt['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text('Tipe Koneksi: ${prt['type']}'),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () => controller.selectPrinter(prt['name'] ?? ''),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  // 3. Camera Configuration Panel
  Widget _buildCameraConfig(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'camera_config'.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pilih kamera utama yang akan digunakan untuk memindai tamu dan identitas.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),

        _buildDropdown(
          label: 'main_camera'.tr,
          value: controller.rxMainCamera,
          items: [
            'Front Camera',
            'Rear Camera',
            'External USB Camera',
            'IP Camera (Lobby A)',
          ],
        ),
        const SizedBox(height: 24),

        ElevatedButton.icon(
          onPressed: () => controller.saveCameraConfig(),
          icon: const Icon(Icons.save),
          label: Text('save_config'.tr),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required RxString value,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value.value,
                items: items
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) value.value = val;
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 4. About Application Panel
  Widget _buildAboutConfig(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'about'.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.tablet_android,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppConstants.companyName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Versi: ${AppConstants.appVersion} (${AppConstants.buildNumber})',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        _buildInfoRow('Flutter SDK Version', '3.32.5 Stable'),
        _buildInfoRow('Target Platforms', 'Windows OS, Android (Tablet & Phone)'),
        _buildInfoRow('State Manager & Routing', 'GetX v4.7.3'),
        _buildInfoRow('Networking Service', 'Dio Client v5.10.0 + SecureStorage Token lock'),
        const SizedBox(height: 32),
        Center(
          child: Text(
            'Copyright © ${DateTime.now().year} Bio Experience. All Rights Reserved.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // 5. Reset Options Panel
  Widget _buildResetConfig(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'reset'.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Atur ulang pengaturan aplikasi atau hapus sesi tersimpan.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        ListTile(
          leading: const Icon(
            Icons.settings_backup_restore,
            color: Colors.orangeAccent,
          ),
          title: Text(
            'reset_config'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Menyetel ulang konfigurasi printer, kamera, dan URL server kembali ke bawaan.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => controller.confirmResetConfig(),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(
            Icons.cleaning_services,
            color: Colors.blueAccent,
          ),
          title: Text(
            'clear_cache'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Menghapus data gambar terunduh dan cache sesi API sementara.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => controller.confirmClearCache(),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.orange),
          title: Text(
            'clear_login'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Menghapus sesi masuk saat ini dan kembali ke menu masuk.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => controller.confirmClearLogin(),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.redAccent,
          ),
          title: Text(
            'factory_reset'.tr,
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text(
            'PERINGATAN: Menghapus total seluruh database lokal, cache, token login, dan konfigurasi.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => controller.confirmFactoryReset(),
        ),
      ],
    );
  }
}
