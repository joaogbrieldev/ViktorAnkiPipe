import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class DetectedWord {
  const DetectedWord({
    required this.text,
    required this.boundingBox,
    this.contextLine,
  });

  final String text;
  final Rect boundingBox;
  final String? contextLine;
}

class CameraState {
  const CameraState({
    this.controller,
    this.flashMode = FlashMode.off,
    this.capturedFrame,
    this.imageSize,
    this.words = const [],
    this.isProcessing = false,
    this.error,
    this.permissionDenied = false,
  });

  final CameraController? controller;
  final FlashMode flashMode;
  final XFile? capturedFrame;
  final Size? imageSize;
  final List<DetectedWord> words;
  final bool isProcessing;
  final String? error;
  final bool permissionDenied;

  bool get isReview => capturedFrame != null;

  CameraState copyWith({
    CameraController? controller,
    bool clearController = false,
    FlashMode? flashMode,
    XFile? capturedFrame,
    bool clearCapturedFrame = false,
    Size? imageSize,
    List<DetectedWord>? words,
    bool? isProcessing,
    String? error,
    bool clearError = false,
    bool? permissionDenied,
  }) {
    return CameraState(
      controller: clearController ? null : controller ?? this.controller,
      flashMode: flashMode ?? this.flashMode,
      capturedFrame:
          clearCapturedFrame ? null : capturedFrame ?? this.capturedFrame,
      imageSize: clearCapturedFrame ? null : imageSize ?? this.imageSize,
      words: clearCapturedFrame ? const [] : words ?? this.words,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : error ?? this.error,
      permissionDenied: permissionDenied ?? this.permissionDenied,
    );
  }
}
