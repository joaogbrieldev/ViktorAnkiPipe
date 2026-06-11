import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:client/core/providers/active_session_provider.dart';
import 'package:client/core/providers/pending_translation_provider.dart';
import 'package:client/core/router/routes.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/data/dto/word_selection.dart';
import 'package:client/features/camera/application/camera_controller.dart';
import 'package:client/features/camera/application/camera_state.dart';
import 'package:client/features/camera/widgets/camera_denied_view.dart';
import 'package:client/features/camera/widgets/ocr_tokens.dart';
import 'package:client/features/camera/widgets/viewfinder_overlay.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key, this.sessionId});

  final String? sessionId;

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.sessionId != null) {
        ref.read(activeSessionProvider.notifier).state = widget.sessionId;
      }
      ref.read(cameraNotifierProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    final notifier = ref.read(cameraNotifierProvider.notifier);
    switch (lifecycleState) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        notifier.pauseCamera();
      case AppLifecycleState.resumed:
        notifier.resumeCamera();
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _handleWordTapped(DetectedWord word) {
    final sessionId = ref.read(activeSessionProvider);
    final imagePath = ref.read(cameraNotifierProvider).capturedFrame?.path;
    ref.read(pendingTranslationProvider.notifier).state = WordSelection(
      word: word.text,
      contextLine: word.contextLine,
      sessionId: sessionId,
      capturedImagePath: imagePath,
    );
    context.push(Routes.result);
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraNotifierProvider);
    return ColoredBox(
      color: Colors.black,
      child: _buildBody(cameraState),
    );
  }

  Widget _buildBody(CameraState cameraState) {
    if (cameraState.permissionDenied) {
      return const CameraDeniedView();
    }

    if (cameraState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            cameraState.error!,
            style: AppText.bodyMd.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final controller = cameraState.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final safeTop = MediaQuery.of(context).padding.top;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Live preview or frozen frame
        if (cameraState.capturedFrame == null)
          CameraPreview(controller)
        else
          Image.file(
            File(cameraState.capturedFrame!.path),
            fit: BoxFit.cover,
          ),

        // 2. Viewfinder brackets (preview mode only)
        if (!cameraState.isReview) const ViewfinderOverlay(),

        // 3. OCR tap targets (review mode, after processing)
        if (cameraState.isReview &&
            cameraState.words.isNotEmpty &&
            cameraState.imageSize != null)
          OcrTokens(
            words: cameraState.words,
            imageSize: cameraState.imageSize!,
            onTap: _handleWordTapped,
          ),

        // 4. Processing overlay
        if (cameraState.isProcessing)
          const ColoredBox(
            color: Color(0x55000000),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Detectando...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

        // 5. Top bar with close / hint / flash
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _TopBar(
            safeTop: safeTop,
            isReview: cameraState.isReview,
            flashMode: cameraState.flashMode,
            onFlashToggle: () =>
                ref.read(cameraNotifierProvider.notifier).toggleFlash(),
            onClose: () => context.go(Routes.sessions),
          ),
        ),

        // 6. Bottom controls (preview or review)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _BottomControls(
            isReview: cameraState.isReview,
            isProcessing: cameraState.isProcessing,
            wordCount: cameraState.words.length,
            onShutter: () =>
                ref.read(cameraNotifierProvider.notifier).capture(),
            onFlip: () =>
                ref.read(cameraNotifierProvider.notifier).flipCamera(),
            onReset: () =>
                ref.read(cameraNotifierProvider.notifier).reset(),
            onDone: () => context.go(Routes.sessions),
          ),
        ),
      ],
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.safeTop,
    required this.isReview,
    required this.flashMode,
    required this.onFlashToggle,
    required this.onClose,
  });

  final double safeTop;
  final bool isReview;
  final FlashMode flashMode;
  final VoidCallback onFlashToggle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          padding: EdgeInsets.only(
            top: safeTop + AppSpacing.xs,
            bottom: AppSpacing.xs,
            left: AppSpacing.xs,
            right: AppSpacing.xs,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
              Expanded(
                child: Center(
                  child: _HintPill(
                    text: isReview
                        ? 'Toque em uma palavra para traduzir'
                        : 'Aponte para o texto para traduzir',
                  ),
                ),
              ),
              IconButton(
                onPressed: onFlashToggle,
                icon: Icon(
                  flashMode == FlashMode.torch
                      ? Icons.flash_on
                      : Icons.flash_off,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintPill extends StatelessWidget {
  const _HintPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        text,
        style: AppText.subhead.copyWith(color: Colors.white),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Bottom controls ───────────────────────────────────────────────────────────

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.isReview,
    required this.isProcessing,
    required this.wordCount,
    required this.onShutter,
    required this.onFlip,
    required this.onReset,
    required this.onDone,
  });

  final bool isReview;
  final bool isProcessing;
  final int wordCount;
  final VoidCallback onShutter;
  final VoidCallback onFlip;
  final VoidCallback onReset;
  final VoidCallback onDone;

  static const _gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0xAA000000)],
  );

  @override
  Widget build(BuildContext context) {
    return isReview ? _buildReview() : _buildPreview();
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      decoration: const BoxDecoration(gradient: _gradient),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Thumbnail placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.white38, width: 1.5),
            ),
          ),
          _ShutterButton(onTap: isProcessing ? null : onShutter),
          IconButton(
            onPressed: onFlip,
            icon: const Icon(
              Icons.flip_camera_ios,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReview() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(gradient: _gradient),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.close, color: Colors.white),
            label: const Text(
              'Refazer',
              style: TextStyle(color: Colors.white),
            ),
          ),
          _WordCountChip(wordCount: wordCount),
          TextButton(
            onPressed: onDone,
            child: const Text(
              'Concluir',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShutterButton extends StatefulWidget {
  const _ShutterButton({this.onTap});

  final VoidCallback? onTap;

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white70, width: 3),
        ),
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: _pressed ? 56 : 64,
          height: _pressed ? 56 : 64,
          decoration: BoxDecoration(
            color: _pressed ? Colors.white70 : Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _WordCountChip extends StatelessWidget {
  const _WordCountChip({required this.wordCount});

  final int wordCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        '$wordCount ${wordCount == 1 ? 'palavra' : 'palavras'} detectadas',
        style: AppText.footnote.copyWith(color: Colors.white),
      ),
    );
  }
}
