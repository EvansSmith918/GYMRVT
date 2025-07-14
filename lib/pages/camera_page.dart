import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final frontCam = cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.front);

    _controller = CameraController(frontCam, ResolutionPreset.medium);
    await _controller?.initialize();
    if (!mounted) return;

    setState(() => _isCameraInitialized = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Camera")),
      body: _isCameraInitialized
          ? CameraPreview(_controller!)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
