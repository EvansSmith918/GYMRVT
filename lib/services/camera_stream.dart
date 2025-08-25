import 'package:camera/camera.dart';

class CameraStream {
  CameraController? controller;
  List<CameraDescription> _cams = [];
  int _index = 0; // current camera index in _cams

  Future<void> init() async {
    _cams = await availableCameras();
    if (_cams.isEmpty) {
      throw StateError('No cameras available on this device.');
    }

    // Prefer back camera first
    final backIdx = _cams.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    _index = backIdx >= 0 ? backIdx : 0;

    controller = CameraController(
      _cams[_index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420, // best for ML Kit
    );
    await controller!.initialize();
  }

  bool get isReady => controller?.value.isInitialized ?? false;

  Future<void> start(void Function(CameraImage img) onImage) async {
    if (!isReady) return;
    if (!(controller!.value.isStreamingImages)) {
      await controller!.startImageStream(onImage);
    }
  }

  Future<void> stop() async {
    if (controller?.value.isStreamingImages ?? false) {
      await controller!.stopImageStream();
    }
  }

  /// Toggle between front/back (or cycle if more lenses exist).
  Future<void> switchCamera() async {
    if (_cams.length < 2) return; // nothing to flip to
    // Stop current stream and dispose controller
    await stop();
    await controller?.dispose();

    // Try to pick the opposite lens first
    final cur = _cams[_index];
    int? nextIdx;

    if (cur.lensDirection == CameraLensDirection.back) {
      nextIdx = _cams.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
    } else if (cur.lensDirection == CameraLensDirection.front) {
      nextIdx = _cams.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
    }

    // Fallback: cycle to the next available camera
    _index = (nextIdx != null && nextIdx >= 0) ? nextIdx : ((_index + 1) % _cams.length);

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

