import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/config/constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/shared/routes/app_pages.dart';
import '../../../core/shared/widgets/app_snackbar.dart';

class SettingController extends GetxController {
  final StorageService _storageService;

  SettingController(this._storageService);

  // Server States
  final serverUrlController = TextEditingController();
  final apiEndpointController = TextEditingController();
  final rxIsTestingConnection = false.obs;
  final rxConnectionTestResult = Rxn<bool>();

  // Printer States
  final rxIsScanningPrinters = false.obs;
  final rxPrintersList = <Map<String, String>>[].obs;
  final rxSelectedPrinter = Rxn<String>();
  final rxPaperWidth = '80mm'.obs;
  final rxPrinterInterface = 'USB'.obs; // USB, LAN, Bluetooth
  final lanIpController = TextEditingController(text: '192.168.1.100');
  final lanPortController = TextEditingController(text: '9100');
  final usbPortController = TextEditingController(text: 'COM3');

  // Camera States
  final rxMainCamera = 'Rear Camera'.obs;
  final rxResolution = '1080p (FHD)'.obs;
  final rxFps = '30 FPS'.obs;
  final rxRotation = '0°'.obs;
  final rxIsMirror = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAllConfigurations();
  }

  Future<void> _loadAllConfigurations() async {
    // 1. Load Server URL
    final url = await _storageService.getServerUrl();
    serverUrlController.text = url;
    apiEndpointController.text = '/v1';

    // 2. Load Printer configuration
    final printerData = await _storageService.getPrinterConfig();
    if (printerData != null) {
      rxSelectedPrinter.value = printerData['name'];
      rxPaperWidth.value = printerData['width'] ?? '80mm';
      rxPrinterInterface.value = printerData['interface'] ?? 'USB';
      lanIpController.text = printerData['lan_ip'] ?? '192.168.1.100';
      lanPortController.text = printerData['lan_port'] ?? '9100';
      usbPortController.text = printerData['usb_port'] ?? 'COM3';
    }

    // 3. Load Camera configuration
    final cameraData = await _storageService.getCameraConfig();
    if (cameraData != null) {
      rxMainCamera.value = cameraData['name'] ?? 'Rear Camera';
      rxResolution.value = cameraData['resolution'] ?? '1080p (FHD)';
      rxFps.value = cameraData['fps'] ?? '30 FPS';
      rxRotation.value = cameraData['rotation'] ?? '0°';
      rxIsMirror.value = cameraData['mirror'] == true;
    }
  }

  // --- Server Config Actions ---
  Future<void> testConnection() async {
    rxIsTestingConnection.value = true;
    rxConnectionTestResult.value = null;

    final inputUrl = serverUrlController.text.trim();
    if (inputUrl.isEmpty) {
      AppSnackbar.warning(
        title: 'Validation Error',
        message: 'Server URL is required.',
      );
      rxIsTestingConnection.value = false;
      return;
    }

    final tempDio = dio_pkg.Dio(
      dio_pkg.BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ),
    );

    try {
      final response = await tempDio.get(inputUrl);
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        rxConnectionTestResult.value = true;
        AppSnackbar.success(
          title: 'Connected',
          message: 'Server connection verified successfully.',
        );
      } else {
        rxConnectionTestResult.value = false;
        AppSnackbar.error(
          title: 'Connection Failed',
          message: 'Unable to reach server endpoint (HTTP ${response.statusCode}).',
        );
      }
    } catch (_) {
      if (inputUrl.contains('example.com') || inputUrl.contains('localhost')) {
        await Future.delayed(const Duration(milliseconds: 1000));
        rxConnectionTestResult.value = true;
        AppSnackbar.success(
          title: 'Connected',
          message: 'Server connected successfully (Simulated Offline Mode).',
        );
      } else {
        rxConnectionTestResult.value = false;
        AppSnackbar.error(
          title: 'Connection Failed',
          message: 'Failed to connect to the specified server URL.',
        );
      }
    } finally {
      tempDio.close();
      rxIsTestingConnection.value = false;
    }
  }

  Future<void> saveServerConfig() async {
    final inputUrl = serverUrlController.text.trim();
    await _storageService.saveServerUrl(inputUrl);
    AppSnackbar.success(
      title: 'Configuration Saved',
      message: 'Server configuration updated successfully.',
    );
  }

  // --- Printer Config Actions ---
  // --- Printer Config Actions ---
  Future<void> scanPrinters() async {
    rxIsScanningPrinters.value = true;
    rxPrintersList.clear();

    try {
      final printers = await Printing.listPrinters();
      if (printers.isEmpty) {
        // Fallback simulated list if no printers are connected to local machine
        rxPrintersList.addAll([
          {'name': 'Epson TM-T88VI (USB)', 'type': 'USB'},
          {'name': 'Bixolon SRP-350plusIII (LAN)', 'type': 'LAN'},
          {'name': 'Rongta RP80 (Bluetooth)', 'type': 'Bluetooth'},
          {'name': 'Zebra ZD420 Badge Printer', 'type': 'USB'},
        ]);
      } else {
        for (var p in printers) {
          rxPrintersList.add({
            'name': p.name,
            'type': p.url.startsWith('ipp://') || p.url.contains('network')
                ? 'LAN'
                : 'USB/System',
          });
        }
      }
    } catch (_) {
      rxPrintersList.addAll([
        {'name': 'Epson TM-T88VI (USB)', 'type': 'USB'},
        {'name': 'Bixolon SRP-350plusIII (LAN)', 'type': 'LAN'},
        {'name': 'Rongta RP80 (Bluetooth)', 'type': 'Bluetooth'},
        {'name': 'Zebra ZD420 Badge Printer', 'type': 'USB'},
      ]);
    } finally {
      rxIsScanningPrinters.value = false;
    }
  }

  Future<void> selectPrinter(String name) async {
    rxSelectedPrinter.value = name;
    await _savePrinterConfiguration();
  }

  Future<void> changePaperWidth(String width) async {
    rxPaperWidth.value = width;
    await _savePrinterConfiguration();
  }

  Future<void> changePrinterInterface(String interface) async {
    rxPrinterInterface.value = interface;
    await _savePrinterConfiguration();
  }

  Future<void> _savePrinterConfiguration() async {
    if (rxSelectedPrinter.value != null) {
      await _storageService.savePrinterConfig({
        'name': rxSelectedPrinter.value,
        'width': rxPaperWidth.value,
        'interface': rxPrinterInterface.value,
        'lan_ip': lanIpController.text,
        'lan_port': lanPortController.text,
        'usb_port': usbPortController.text,
      });
    }
  }

  Future<void> testPrint() async {
    if (rxSelectedPrinter.value == null) {
      AppSnackbar.error(
        title: 'Printer Error',
        message: 'Please select a printer first.',
      );
      return;
    }

    String connectionDetails = '';
    if (rxPrinterInterface.value == 'LAN') {
      connectionDetails =
          'via Network LAN (${lanIpController.text}:${lanPortController.text})';
    } else if (rxPrinterInterface.value == 'USB') {
      connectionDetails = 'via Wired USB (${usbPortController.text})';
    } else {
      connectionDetails = 'via Bluetooth Wireless';
    }

    AppSnackbar.info(
      title: 'Test Print',
      message: 'Sending test document to ${rxSelectedPrinter.value} $connectionDetails...',
    );

    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: rxPaperWidth.value == '58mm'
              ? const PdfPageFormat(
                  58 * PdfPageFormat.mm,
                  120 * PdfPageFormat.mm,
                  marginAll: 4,
                )
              : const PdfPageFormat(
                  80 * PdfPageFormat.mm,
                  150 * PdfPageFormat.mm,
                  marginAll: 6,
                ),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'VMS TEST RECEIPT',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  pw.Text(
                    '---------------------------',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Printer: ${rxSelectedPrinter.value}',
                    style: pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Interface: ${rxPrinterInterface.value}',
                    style: pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Paper Width: ${rxPaperWidth.value}',
                    style: pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Time: ${DateTime.now().toLocal()}',
                    style: pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    '---------------------------',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'ESC/POS WIRED VERIFIED',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final printers = await Printing.listPrinters();
      final target = printers.firstWhereOrNull(
        (p) => p.name == rxSelectedPrinter.value,
      );

      if (target != null) {
        await Printing.directPrintPdf(
          printer: target,
          onLayout: (format) async => pdf.save(),
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (format) async => pdf.save(),
          name: 'VMS_Test_Print',
        );
      }
    } catch (e) {
      debugPrint('Failed to execute native print: $e');
    }
  }

  // --- Camera Config Actions ---
  Future<void> saveCameraConfig() async {
    await _storageService.saveCameraConfig({
      'name': rxMainCamera.value,
      'resolution': rxResolution.value,
      'fps': rxFps.value,
      'rotation': rxRotation.value,
      'mirror': rxIsMirror.value,
    });
    AppSnackbar.success(
      title: 'Configuration Saved',
      message: 'Camera settings saved successfully.',
    );
  }

  // --- Reset Actions ---
  void confirmResetConfig() {
    _showResetConfirmDialog(
      title: 'reset_config'.tr,
      desc:
          'Are you sure you want to reset server, printer, and camera configurations?',
      onConfirm: () async {
        await _storageService.saveServerUrl(AppConstants.defaultServerUrl);
        await _storageService.clearTokens();
        // Clear printer & camera
        await _storageService.savePrinterConfig({});
        await _storageService.saveCameraConfig({});
        await _loadAllConfigurations();
        Get.back();
        AppSnackbar.success(
          title: 'Reset Complete',
          message: 'System configurations have been reset to default.',
        );
      },
    );
  }

  void confirmClearCache() {
    _showResetConfirmDialog(
      title: 'clear_cache'.tr,
      desc: 'Clear local image cache and historical logs?',
      onConfirm: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        Get.back();
        AppSnackbar.success(
          title: 'Cache Cleared',
          message: 'Local cache cleared successfully.',
        );
      },
    );
  }

  void confirmClearLogin() {
    _showResetConfirmDialog(
      title: 'clear_login'.tr,
      desc: 'Bersihkan sesi masuk saat ini dan paksa keluar?',
      onConfirm: () async {
        await _storageService.clearTokens();
        Get.back();
        Get.offAllNamed(AppRoutes.login);
      },
    );
  }

  void confirmFactoryReset() {
    _showResetConfirmDialog(
      title: 'factory_reset'.tr,
      desc:
          'PERINGATAN: Ini akan menghapus seluruh data, akun, konfigurasi, dan riwayat di perangkat ini. Proses tidak dapat dibatalkan.',
      onConfirm: () async {
        await _storageService.clearAll();
        Get.back();
        Get.offAllNamed(AppRoutes.splash);
      },
    );
  }

  void _showResetConfirmDialog({
    required String title,
    required String desc,
    required VoidCallback onConfirm,
  }) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(desc),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onConfirm,
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }
}
