import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:client/features/camera/application/camera_state.dart';

class CameraNotifier extends StateNotifier<CameraState> {
  CameraNotifier({
    Future<List<CameraDescription>> Function()? camerasFactory,
    CameraController Function(CameraDescription, ResolutionPreset)?
        controllerFactory,
    TextRecognizer Function()? recognizerFactory,
    Future<Size> Function(XFile)? imageSizeResolver,
  })  : _getCameras = camerasFactory ?? availableCameras,
        _buildController = controllerFactory ?? _defaultController,
        _buildRecognizer = recognizerFactory ?? _defaultRecognizer,
        _resolveImageSize = imageSizeResolver ?? _defaultImageSize,
        super(const CameraState());

  final Future<List<CameraDescription>> Function() _getCameras;
  final CameraController Function(CameraDescription, ResolutionPreset)
      _buildController;
  final TextRecognizer Function() _buildRecognizer;
  final Future<Size> Function(XFile) _resolveImageSize;

  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;

  static CameraController _defaultController(
    CameraDescription desc,
    ResolutionPreset preset,
  ) =>
      CameraController(
        desc,
        preset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

  static TextRecognizer _defaultRecognizer() =>
      TextRecognizer(script: TextRecognitionScript.latin);

  static Future<Size> _defaultImageSize(XFile file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
  }

  Future<void> initialize() async {
    if (state.controller?.value.isInitialized == true) return;

    try {
      await state.controller?.dispose();

      _cameras = await _getCameras();
      if (_cameras.isEmpty) {
        if (mounted) state = state.copyWith(error: 'Nenhuma câmera disponível');
        return;
      }
      _cameraIndex = _backCameraIndex();
      await _startController(_cameras[_cameraIndex]);
    } on CameraException catch (e) {
      if (!mounted) return;
      if (e.code == 'CameraAccessDenied' ||
          e.code == 'CameraAccessDeniedWithoutPrompt') {
        state = state.copyWith(permissionDenied: true);
      } else {
        state = state.copyWith(
          error: e.description ?? 'Erro ao inicializar câmera',
        );
      }
    }
  }

  Future<void> pauseCamera() async {
    final controller = state.controller;
    if (controller == null) return;
    await controller.dispose();
    if (mounted) state = CameraState(flashMode: state.flashMode);
  }

  Future<void> resumeCamera() async {
    if (state.controller?.value.isInitialized == true) return;
    await initialize();
  }

  int _backCameraIndex() {
    final idx = _cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    return idx >= 0 ? idx : 0;
  }

  Future<void> _startController(CameraDescription description) async {
    final controller = _buildController(description, ResolutionPreset.high);
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    state = state.copyWith(controller: controller, flashMode: FlashMode.off);
  }

  Future<void> toggleFlash() async {
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) return;
    final next =
        state.flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await controller.setFlashMode(next);
    if (mounted) state = state.copyWith(flashMode: next);
  }

  Future<void> flipCamera() async {
    if (_cameras.length < 2) return;
    final old = state.controller;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await old?.dispose();
    if (!mounted) return;
    state = CameraState(flashMode: state.flashMode);
    await _startController(_cameras[_cameraIndex]);
  }

  Future<void> capture() async {
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state.isProcessing) return;

    if (mounted) state = state.copyWith(isProcessing: true);

    try {
      final file = await controller.takePicture();
      await _runOcr(file);
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isProcessing: false, clearError: false);
      }
    }
  }

  Future<void> _runOcr(XFile file) async {
    final imageSize = await _resolveImageSize(file);
    if (!mounted) return;

    state = CameraState(
      controller: state.controller,
      flashMode: state.flashMode,
      capturedFrame: file,
      imageSize: imageSize,
      isProcessing: true,
    );

    final recognizer = _buildRecognizer();
    try {
      final result =
          await recognizer.processImage(InputImage.fromFilePath(file.path));
      if (!mounted) return;

      final words = <DetectedWord>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          for (final element in line.elements) {
            words.add(
              DetectedWord(
                text: element.text,
                boundingBox: element.boundingBox,
                contextLine: line.text,
              ),
            );
          }
        }
      }
      state = state.copyWith(words: words, isProcessing: false);
    } catch (_) {
      if (mounted) state = state.copyWith(isProcessing: false);
    } finally {
      await recognizer.close();
    }
  }

  void reset() {
    state = CameraState(
      controller: state.controller,
      flashMode: state.flashMode,
    );
  }

  @override
  void dispose() {
    state.controller?.dispose();
    super.dispose();
  }
}

final cameraNotifierProvider =
    StateNotifierProvider.autoDispose<CameraNotifier, CameraState>(
  (_) => CameraNotifier(),
);
