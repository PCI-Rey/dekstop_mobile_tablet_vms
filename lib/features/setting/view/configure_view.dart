import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/setting_controller.dart';
import '../../../core/config/constants.dart';

class ConfigureView extends GetView<SettingController> {
  const ConfigureView({super.key});

  static const Color _primaryBlue = Color(0xFF1976D2);
  static const Color _darkBlue = Color(0xFF0E5DB5);
  static const Color _bgSlate = Color(0xFFF8FAFC);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _borderSoft = Color(0xFFE2E8F0);
  static const Color _dangerRed = Color(0xFFEF4444);
  static const Color _warningOrange = Color(0xFFF59E0B);
  static const Color _successGreen = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSlate,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: _borderSoft)),
              ),
              child: Row(
                children: [
                  // Floating Back Button
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Get.back(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderSoft),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: _textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'System Configurations',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: _textDark,
                    ),
                  ),
                  const Spacer(),
                  // Environment Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune_rounded, size: 14, color: _primaryBlue),
                        const SizedBox(width: 6),
                        Text(
                          'Tablet Hybrid Client',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Settings Layout (Sidebar + Content Pane)
            Expanded(
              child: _buildMainLayout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainLayout(BuildContext context) {
    final activeTab = 0.obs;

    final sections = [
      {'title': 'Server Configuration', 'icon': Icons.dns_rounded, 'subtitle': 'Base URL & API endpoints'},
      {'title': 'Printer Configuration', 'icon': Icons.print_rounded, 'subtitle': 'Bluetooth, USB, & LAN printers'},
      {'title': 'Camera Configuration', 'icon': Icons.camera_alt_rounded, 'subtitle': 'Visitor scanner & OCR camera'},
      {'title': 'About Application', 'icon': Icons.info_outline_rounded, 'subtitle': 'Software release & tech stack'},
      {'title': 'Reset & Maintenance', 'icon': Icons.settings_backup_restore_rounded, 'subtitle': 'Cache clearing & data reset'},
    ];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar Navigation Card
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _primaryBlue.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: _primaryBlue.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              itemCount: sections.length,
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final section = sections[index];
                return Obx(() {
                  final isSelected = activeTab.value == index;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => activeTab.value = index,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFBFDBFE) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primaryBlue.withValues(alpha: 0.12)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              section['icon'] as IconData,
                              size: 18,
                              color: isSelected ? _primaryBlue : _textMuted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section['title'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: isSelected ? _primaryBlue : _textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  section['subtitle'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: _textMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: _primaryBlue,
                            ),
                        ],
                      ),
                    ),
                  );
                });
              },
            ),
          ),

          const SizedBox(width: 24),

          // Right Settings Content Card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _primaryBlue.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: _primaryBlue.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28.0),
                  child: Obx(() {
                    switch (activeTab.value) {
                      case 0:
                        return _buildServerConfig();
                      case 1:
                        return _buildPrinterConfig();
                      case 2:
                        return _buildCameraConfig();
                      case 3:
                        return _buildAboutConfig();
                      case 4:
                        return _buildResetConfig();
                      default:
                        return const SizedBox.shrink();
                    }
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== Sub-Configuration Renderers =====================

  // 1. Server Configuration Panel
  Widget _buildServerConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'SERVER CONFIGURATION',
          subtitle: 'Configure the primary backend API server base URL and connection endpoint.',
        ),
        const SizedBox(height: 24),

        // Server URL Input
        Text(
          'Server Base URL',
          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: _textDark),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.serverUrlController,
          style: GoogleFonts.inter(fontSize: 13.5, color: _textDark),
          decoration: InputDecoration(
            hintText: 'https://be-vms.app.bio-experience.com',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.link_rounded, size: 20, color: _primaryBlue),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _borderSoft),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _borderSoft),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // API Endpoint Input
        Text(
          'API Endpoint Route',
          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: _textDark),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.apiEndpointController,
          enabled: false,
          style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF64748B)),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.api_rounded, size: 20, color: Color(0xFF94A3B8)),
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _borderSoft),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _borderSoft),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Action Buttons: Test Connection & Save Config
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: _primaryBlue),
                      )
                    : const Icon(Icons.network_ping_rounded, size: 18, color: _primaryBlue),
                label: Text(
                  'Test Connection',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _primaryBlue),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  backgroundColor: const Color(0xFFEFF6FF),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            ElevatedButton.icon(
              onPressed: () => controller.saveServerConfig(),
              icon: const Icon(Icons.save_rounded, size: 18, color: Colors.white),
              label: Text(
                'Save Configuration',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Printer Configuration Panel
  Widget _buildPrinterConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'PRINTER CONFIGURATION',
          subtitle: 'Connect and configure thermal receipt and card badge printers via USB, LAN, or Bluetooth.',
        ),
        const SizedBox(height: 24),

        // Paper Width Options
        Text(
          'Paper Width',
          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: _textDark),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Row(
            children: ['58mm', '80mm'].map((width) {
              final isSel = controller.rxPaperWidth.value == width;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ChoiceChip(
                  label: Text(
                    width,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? Colors.white : _textDark,
                    ),
                  ),
                  selected: isSel,
                  selectedColor: _primaryBlue,
                  backgroundColor: const Color(0xFFF1F5F9),
                  side: BorderSide(color: isSel ? _primaryBlue : _borderSoft),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onSelected: (_) => controller.changePaperWidth(width),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Interface Type Options
        Text(
          'Printer Interface',
          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: _textDark),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Row(
            children: ['USB', 'LAN', 'Bluetooth'].map((iface) {
              final isSel = controller.rxPrinterInterface.value == iface;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ChoiceChip(
                  label: Text(
                    iface,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? Colors.white : _textDark,
                    ),
                  ),
                  selected: isSel,
                  selectedColor: _primaryBlue,
                  backgroundColor: const Color(0xFFF1F5F9),
                  side: BorderSide(color: isSel ? _primaryBlue : _borderSoft),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onSelected: (_) => controller.changePrinterInterface(iface),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Conditional forms for Wired Printer Interfaces
        Obx(() {
          if (controller.rxPrinterInterface.value == 'LAN') {
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderSoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LAN Printer ESC/POS Settings (Wired)',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _textDark),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: controller.lanIpController,
                          onChanged: (_) => controller.selectPrinter('ESC/POS LAN Printer'),
                          style: GoogleFonts.inter(fontSize: 13, color: _textDark),
                          decoration: InputDecoration(
                            labelText: 'Printer IP Address',
                            hintText: '192.168.1.100',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: controller.lanPortController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => controller.selectPrinter('ESC/POS LAN Printer'),
                          style: GoogleFonts.inter(fontSize: 13, color: _textDark),
                          decoration: InputDecoration(
                            labelText: 'Port',
                            hintText: '9100',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          if (controller.rxPrinterInterface.value == 'USB') {
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderSoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'USB Printer ESC/POS Settings (Wired / Serial)',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _textDark),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: controller.usbPortController,
                    onChanged: (_) => controller.selectPrinter('ESC/POS USB Printer'),
                    style: GoogleFonts.inter(fontSize: 13, color: _textDark),
                    decoration: InputDecoration(
                      labelText: 'USB Port / COM Path',
                      hintText: 'COM3 or /dev/usb/lp0',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        const SizedBox(height: 20),

        // Selected Printer Status Box
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderSoft),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: controller.rxSelectedPrinter.value != null
                        ? _successGreen.withValues(alpha: 0.15)
                        : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.print_rounded,
                    size: 17,
                    color: controller.rxSelectedPrinter.value != null ? _successGreen : _textMuted,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Printer',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: _textMuted),
                      ),
                      Text(
                        controller.rxSelectedPrinter.value ?? 'No printer selected',
                        style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: _textDark),
                      ),
                    ],
                  ),
                ),
                if (controller.rxSelectedPrinter.value != null)
                  ElevatedButton.icon(
                    onPressed: () => controller.testPrint(),
                    icon: const Icon(Icons.receipt_long_rounded, size: 16),
                    label: Text(
                      'Test Print',
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Detected Devices List
        Obx(() {
          if (controller.rxIsScanningPrinters.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(color: _primaryBlue),
              ),
            );
          }

          if (controller.rxPrintersList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: OutlinedButton.icon(
                  onPressed: () => controller.scanPrinters(),
                  icon: const Icon(Icons.search_rounded, size: 18, color: _primaryBlue),
                  label: Text(
                    'Scan for Printers',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _primaryBlue),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    backgroundColor: const Color(0xFFEFF6FF),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
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
                  Text(
                    'Detected Devices',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _textDark),
                  ),
                  TextButton.icon(
                    onPressed: () => controller.scanPrinters(),
                    icon: const Icon(Icons.refresh_rounded, size: 16, color: _primaryBlue),
                    label: Text(
                      'Rescan',
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: _primaryBlue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...controller.rxPrintersList.map((prt) {
                final isSelected = controller.rxSelectedPrinter.value == prt['name'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? const Color(0xFFBFDBFE) : _borderSoft),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      prt['name'] ?? '',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _textDark),
                    ),
                    subtitle: Text(
                      'Connection Type: ${prt['type']}',
                      style: GoogleFonts.inter(fontSize: 11.5, color: _textMuted),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: _successGreen, size: 20)
                        : null,
                    onTap: () => controller.selectPrinter(prt['name'] ?? ''),
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  // 3. Camera Configuration Panel
  Widget _buildCameraConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'CAMERA CONFIGURATION',
          subtitle: 'Select the active primary camera used for visitor photo capture, badge scanning, and OCR verification.',
        ),
        const SizedBox(height: 24),

        _buildDropdown(
          label: 'Primary Capture Camera',
          value: controller.rxMainCamera,
          items: [
            'Front Camera',
            'Rear Camera',
            'External USB Camera',
            'IP Camera (Lobby A)',
          ],
        ),
        const SizedBox(height: 18),

        _buildDropdown(
          label: 'Preview Resolution',
          value: controller.rxResolution,
          items: [
            '720p (HD)',
            '1080p (FHD)',
            '4K (Ultra HD)',
          ],
        ),
        const SizedBox(height: 18),

        _buildDropdown(
          label: 'Capture Frame Rate',
          value: controller.rxFps,
          items: [
            '24 FPS',
            '30 FPS',
            '60 FPS',
          ],
        ),
        const SizedBox(height: 28),

        ElevatedButton.icon(
          onPressed: () => controller.saveCameraConfig(),
          icon: const Icon(Icons.save_rounded, size: 18, color: Colors.white),
          label: Text(
            'Save Camera Settings',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: _textDark),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderSoft),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value.value,
                isExpanded: true,
                style: GoogleFonts.inter(fontSize: 13, color: _textDark, fontWeight: FontWeight.w600),
                items: items
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      ),
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
  Widget _buildAboutConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'ABOUT APPLICATION',
          subtitle: 'Software build specifications, platform target, and technology stack information.',
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryBlue, _darkBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primaryBlue.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.tablet_mac_rounded, size: 30, color: Colors.white),
            ),
            const SizedBox(width: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  AppConstants.companyName,
                  style: GoogleFonts.inter(fontSize: 13, color: _textMuted),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    'Release v${AppConstants.appVersion} (${AppConstants.buildNumber})',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _primaryBlue),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(color: _borderSoft),
        const SizedBox(height: 12),
        _buildInfoRow('Flutter SDK Version', '3.32.5 Stable'),
        _buildInfoRow('Target Platforms', 'Windows OS, Android (Tablet & Phone)'),
        _buildInfoRow('State Manager & Routing', 'GetX Reactive v4.7.3'),
        _buildInfoRow('Networking Service', 'Dio Client v5.10.0 + SecureStorage Lock'),
        const SizedBox(height: 32),
        Center(
          child: Text(
            'Copyright © ${DateTime.now().year} Bio Experience. All Rights Reserved.',
            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: _textDark)),
          Text(value, style: GoogleFonts.inter(fontSize: 12.5, color: _textMuted)),
        ],
      ),
    );
  }

  // 5. Reset Options Panel
  Widget _buildResetConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'RESET & MAINTENANCE',
          subtitle: 'Reset hardware peripherals, clear cache memory, or restore client to factory default.',
        ),
        const SizedBox(height: 24),

        _buildMaintenanceTile(
          icon: Icons.settings_backup_restore_rounded,
          iconColor: _warningOrange,
          title: 'Reset Peripheral Configurations',
          subtitle: 'Reset printer interfaces, camera indices, and server URLs back to system default.',
          onTap: () => controller.confirmResetConfig(),
        ),
        const Divider(color: _borderSoft, height: 1),
        _buildMaintenanceTile(
          icon: Icons.cleaning_services_rounded,
          iconColor: const Color(0xFF0F62FE),
          title: 'Clear Local Cache',
          subtitle: 'Delete cached avatar images, visitor logs, and temporary API response snapshots.',
          onTap: () => controller.confirmClearCache(),
        ),
        const Divider(color: _borderSoft, height: 1),
        _buildMaintenanceTile(
          icon: Icons.logout_rounded,
          iconColor: _warningOrange,
          title: 'Clear Login Session',
          subtitle: 'Clear current operator authentication tokens and return to the login screen.',
          onTap: () => controller.confirmClearLogin(),
        ),
        const Divider(color: _borderSoft, height: 1),
        _buildMaintenanceTile(
          icon: Icons.warning_amber_rounded,
          iconColor: _dangerRed,
          title: 'Factory Data Reset',
          subtitle: 'CAUTION: Wipe entire local SQLite database, tokens, cached files, and credentials.',
          isDanger: true,
          onTap: () => controller.confirmFactoryReset(),
        ),
      ],
    );
  }

  Widget _buildMaintenanceTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDanger ? _dangerRed : _textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 11.5, color: _textMuted),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDanger ? _dangerRed.withValues(alpha: 0.6) : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3.5,
              height: 15,
              decoration: BoxDecoration(
                color: _primaryBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: _textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12.5, color: _textMuted),
        ),
      ],
    );
  }
}

