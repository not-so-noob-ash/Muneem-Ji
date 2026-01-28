import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isScanComplete = false;
  bool isTorchOn = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan UPI QR Code'),
        actions: [
          IconButton(
            icon: Icon(
              isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: isTorchOn ? Colors.yellow : Colors.white70,
            ),
            onPressed: () async {
              await controller.toggleTorch();
              setState(() {
                isTorchOn = !isTorchOn;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (!isScanComplete) {
                final String? code = capture.barcodes.first.rawValue;
                if (code != null) {
                  setState(() {
                    isScanComplete = true;
                  });
                  // Return the scanned code to the previous screen
                  Navigator.of(context).pop(code);
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: const Text(
              "Align QR code within the frame",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, backgroundColor: Colors.black54),
            ),
          )
        ],
      ),
    );
  }
}