import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanBarcodePage extends StatefulWidget {
  final void Function(String code) onScan;
  const ScanBarcodePage({super.key, required this.onScan});

  @override
  State<ScanBarcodePage> createState() => _ScanBarcodePageState();
}

class _ScanBarcodePageState extends State<ScanBarcodePage> {
  final _controller = MobileScannerController(torchEnabled: false);
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handle(String code) {
    if (_handled) return;
    _handled = true;
    Navigator.pop(context);
    widget.onScan(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final code = capture.barcodes.isNotEmpty
                  ? capture.barcodes.first.rawValue
                  : null;
              if (code != null) _handle(code);
            },
          ),
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _controller.toggleTorch(),
                  icon: const Icon(Icons.flashlight_on),
                  label: const Text('Torch'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _controller.switchCamera(),
                  icon: const Icon(Icons.cameraswitch),
                  label: const Text('Flip'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
