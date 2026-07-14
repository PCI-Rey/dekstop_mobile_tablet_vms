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
  // Mock state logic for non-compiling simulator fallback if necessary,
  // but we implement mobile_scanner package directly.
  late final MobileScannerController cameraController;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      facing: widget.initialFacing,
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => cameraController.toggleTorch(),
          ),
          // Camera facing state toggle button
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
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
