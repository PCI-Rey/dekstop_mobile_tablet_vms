import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';

class MobileScannerPage extends StatefulWidget {
  final CameraFacing initialFacing;

  const MobileScannerPage({
    super.key,
    required this.initialFacing,
  });

  @override
  State<MobileScannerPage> createState() => _MobileScannerPageState();
}

class _MockScannerPageState extends State<MobileScannerPage> {
  MobileScannerController? cameraController;
  final TextEditingController _desktopCodeController = TextEditingController();

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    if (!_isDesktop) {
      cameraController = MobileScannerController(
        facing: widget.initialFacing,
      );
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    _desktopCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Desktop Scanner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(28),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Color(0xFF38BDF8),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Hardware / USB Scanner Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Scan QR using your USB/Bluetooth hardware scanner or enter the code manually below:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _desktopCodeController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter or scan code...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (val) {
                    final trimmed = val.trim().toUpperCase();
                    if (trimmed.isNotEmpty) {
                      Get.back(result: trimmed);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004385),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      final trimmed = _desktopCodeController.text.trim().toUpperCase();
                      if (trimmed.isNotEmpty) {
                        Get.back(result: trimmed);
                      }
                    },
                    child: const Text('Submit Code', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Scan QR / Barcode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          // Torch state toggle button
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => cameraController?.toggleTorch(),
          ),
          // Camera facing state toggle button
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () => cameraController?.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (cameraController != null)
            MobileScanner(
              controller: cameraController,
              onDetect: (BarcodeCapture capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final rawValue = barcode.rawValue;
                  if (rawValue != null && rawValue.isNotEmpty) {
                    Get.back(result: rawValue);
                    break;
                  }
                }
              },
            ),
          
          // Reticle Scanner Overlay Tech Corners
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Positioned(
                    top: 0, left: 0,
                    child: Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF0F62FE), width: 4),
                          left: BorderSide(color: Color(0xFF0F62FE), width: 4),
                        ),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(10)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF0F62FE), width: 4),
                          right: BorderSide(color: Color(0xFF0F62FE), width: 4),
                        ),
                        borderRadius: BorderRadius.only(topRight: Radius.circular(10)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0, left: 0,
                    child: Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF0F62FE), width: 4),
                          left: BorderSide(color: Color(0xFF0F62FE), width: 4),
                        ),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF0F62FE), width: 4),
                          right: BorderSide(color: Color(0xFF0F62FE), width: 4),
                        ),
                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Instructions text bottom overlay
          const Positioned(
            bottom: 50,
            left: 32,
            right: 32,
            child: Column(
              children: [
                Text(
                  'Arahkan kamera ke QR Code / Barcode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6),
                Text(
                  'Sistem akan memindai kode secara otomatis',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Concrete state implementation
class _MobileScannerPageState extends _MockScannerPageState {}
