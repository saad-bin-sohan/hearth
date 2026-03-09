import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_empty_state.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image/image.dart' as img_lib;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});

  static const String routePath = '/documents/scan';

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _imagePicker = ImagePicker();
  CameraController? _controller;
  Future<void>? _initializeFuture;
  bool _flashEnabled = false;
  bool _autoMode = true;
  String? _previewFilePath;
  String? _cameraError;
  Timer? _stillTimer;
  late final AnimationController _edgeController;

  @override
  void initState() {
    super.initState();
    _edgeController = AnimationController(
      vsync: this,
      duration: AppAnimations.standard,
      value: 0,
    );
    _setupCamera();
  }

  @override
  void dispose() {
    _stillTimer?.cancel();
    _edgeController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameraError = 'No camera is available on this device.';
        });
        return;
      }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _initializeFuture = controller.initialize().then((_) {
        _resetStillTimer();
      });
      if (mounted) {
        setState(() {
          _controller = controller;
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _cameraError = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_previewFilePath != null) {
      return _buildPreviewMode(context);
    }
    if (_cameraError != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: HearthEmptyState(
            icon: HugeIcons.strokeRoundedCameraOff01,
            title: 'Camera unavailable',
            body: _cameraError!,
            ctaLabel: 'Choose Photo',
            onCtaPressed: _pickFromGallery,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeFuture,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState != ConnectionState.done ||
              _controller == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(
                  onPanDown: (_) => _resetStillTimer(),
                  child: CameraPreview(_controller!),
                ),
              ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _edgeController,
                  builder: (BuildContext context, Widget? child) {
                    return CustomPaint(
                      painter: _DocumentFramePainter(
                        color: Color.lerp(
                          AppColors.textTertiary.withValues(alpha: 0.7),
                          AppColors.success,
                          _edgeController.value,
                        )!,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: AppSpacing.xl + AppSpacing.md,
                left: AppSpacing.md,
                right: AppSpacing.md,
                child: Row(
                  children: <Widget>[
                    _OverlayButton(
                      icon: HugeIcons.strokeRoundedCancel01,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Align document within the frame',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.surface.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _OverlayButton(
                      icon: _flashEnabled
                          ? HugeIcons.strokeRoundedFlash
                          : HugeIcons.strokeRoundedFlashOff,
                      onTap: _toggleFlash,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppRadius.radiusLg),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _OverlayButton(
                        icon: HugeIcons.strokeRoundedImage01,
                        darkForeground: true,
                        onTap: _pickFromGallery,
                      ),
                      GestureDetector(
                        onTap: _capturePhoto,
                        child: Container(
                          width: 72,
                          height: 72,
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 2,
                            ),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _autoMode = !_autoMode;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(
                              AppRadius.radiusFull,
                            ),
                          ),
                          child: Text(
                            _autoMode ? 'Auto' : 'Manual',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPreviewMode(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.file(
              File(_previewFilePath!),
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: AppSpacing.xl + AppSpacing.md,
            left: AppSpacing.md,
            child: _OverlayButton(
              icon: HugeIcons.strokeRoundedCancel01,
              onTap: () => setState(() {
                _previewFilePath = null;
                _resetStillTimer();
              }),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.xl,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: HearthButton(
                    label: 'Retake',
                    variant: HearthButtonVariant.ghost,
                    onPressed: () {
                      setState(() {
                        _previewFilePath = null;
                        _resetStillTimer();
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: HearthButton(
                    label: 'Use Photo',
                    onPressed: _usePhoto,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) {
      return;
    }
    _resetStillTimer();
    setState(() {
      _flashEnabled = !_flashEnabled;
    });
    await _controller!.setFlashMode(
      _flashEnabled ? FlashMode.torch : FlashMode.off,
    );
  }

  Future<void> _capturePhoto() async {
    if (_controller == null) {
      return;
    }
    _resetStillTimer();
    final file = await _controller!.takePicture();
    if (!mounted) {
      return;
    }
    setState(() {
      _previewFilePath = file.path;
    });
  }

  Future<void> _pickFromGallery() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) {
      return;
    }
    setState(() {
      _previewFilePath = file.path;
    });
  }

  Future<void> _usePhoto() async {
    if (_previewFilePath == null) {
      return;
    }
    final processedPath = await _compressIfNeeded(_previewFilePath!);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(processedPath);
  }

  Future<String> _compressIfNeeded(String originalPath) async {
    final originalFile = File(originalPath);
    if (!await originalFile.exists() || await originalFile.length() <= 1024 * 1024) {
      return originalPath;
    }
    final decoded = img_lib.decodeImage(await originalFile.readAsBytes());
    if (decoded == null) {
      return originalPath;
    }
    final compressed = img_lib.encodeJpg(decoded, quality: 85);
    final tempDirectory = await getTemporaryDirectory();
    final compressedFile = File(
      path.join(
        tempDirectory.path,
        'hearth_scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );
    await compressedFile.writeAsBytes(compressed, flush: true);
    return compressedFile.path;
  }

  void _resetStillTimer() {
    _stillTimer?.cancel();
    _edgeController.reverse();
    _stillTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _edgeController.forward();
      }
    });
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.icon,
    required this.onTap,
    this.darkForeground = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool darkForeground;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: darkForeground
            ? AppColors.surfaceVariant
            : AppColors.overlay.withValues(alpha: 0.42),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: darkForeground ? AppColors.textPrimary : AppColors.surface,
        ),
      ),
    );
  }
}

class _DocumentFramePainter extends CustomPainter {
  const _DocumentFramePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width * 0.75;
    final height = width * 0.75;
    final left = (size.width - width) / 2;
    final top = (size.height - height) / 2;
    const arm = 20.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(left, top, width, height);
    canvas.drawLine(rect.topLeft, Offset(rect.left + arm, rect.top), paint);
    canvas.drawLine(rect.topLeft, Offset(rect.left, rect.top + arm), paint);
    canvas.drawLine(rect.topRight, Offset(rect.right - arm, rect.top), paint);
    canvas.drawLine(rect.topRight, Offset(rect.right, rect.top + arm), paint);
    canvas.drawLine(
      rect.bottomLeft,
      Offset(rect.left + arm, rect.bottom),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      Offset(rect.left, rect.bottom - arm),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      Offset(rect.right - arm, rect.bottom),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      Offset(rect.right, rect.bottom - arm),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DocumentFramePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
