import 'package:camera/camera.dart';

class CameraStream {
  CameraController? controller;
  late final List<CameraDescription> _cams;

  Future<void> init() async {
    _cams = await availableCameras();
    final back = _cams.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cams.first,
    );
    controller = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await controller!.initialize();
  }

  bool get isReady => controller?.value.isInitialized ?? false;

  Future<void> start(void Function(CameraImage img) onImage) async {
    if (!isReady) return;
    await controller!.startImageStream(onImage);
  }

  Future<void> stop() async {
    if (controller?.value.isStreamingImages ?? false) {
      await controller!.stopImageStream();
    }
  }

  Future<void> dispose() async {
    await stop();
    await controller?.dispose();
  }
}
