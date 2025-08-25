import 'package:camera/camera.dart';

class CameraStream {
  CameraController? controller;
  List<CameraDescription> _cams = const [];
  int _index = 0;

  Future<void> init({CameraLensDirection preferred = CameraLensDirection.back}) async {
    _cams = await availableCameras();
    if (_cams.isEmpty) {
      throw StateError('No cameras available on this device.');
    }

    // Pick preferred lens if available, else the first.
    final idx = _cams.indexWhere((c) => c.lensDirection == preferred);
    _index = idx >= 0 ? idx : 0;

    controller = CameraController(
      _cams[_index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await controller!.initialize();
  }

  bool get isReady => controller?.value.isInitialized ?? false;

  Future<void> start(void Function(CameraImage img) onImage) async {
    if (!isReady) return;
    if (controller!.value.isStreamingImages) {
      await controller!.stopImageStream();
    }
    await controller!.startImageStream(onImage);
  }

  Future<void> stop() async {
    if (controller?.value.isStreamingImages ?? false) {
      await controller!.stopImageStream();
    }
  }

  Future<void> switchCamera() async {
    if (_cams.length < 2) return;
    await stop();
    await controller?.dispose();

    // Cycle to the next different lens (front/back).
    final currentDir = _cams[_index].lensDirection;
    final nextIdx = _cams.indexWhere(
      (c) => c.lensDirection != currentDir,
      (_index + 1) % _cams.length,
    );
    _index = nextIdx >= 0 ? nextIdx : ((_index + 1) % _cams.length);

    controller = CameraController(
      _cams[_index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await controller!.initialize();
  }

  Future<void> dispose() async {
    await stop();
    await controller?.dispose();
  }
}
