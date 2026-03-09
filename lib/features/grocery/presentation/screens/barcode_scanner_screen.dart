import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/animated/hearth_list_item_entry.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/features/grocery/data/open_food_facts_service.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';
import 'package:hearth/features/grocery/presentation/widgets/grocery_visuals.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  static const String routePath = '/grocery/scan';

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

enum _ScannerPanelState { idle, loading, found, notFound, error }

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen>
    with TickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late final AnimationController _scanLineController;

  _ScannerPanelState _panelState = _ScannerPanelState.idle;
  OpenFoodProduct? _product;
  String? _barcodeValue;
  String? _errorMessage;
  bool _hasDetectedCode = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scanWindow = Rect.fromCenter(
            center: constraints.biggest.center(Offset.zero),
            width: constraints.maxWidth * 0.7,
            height: constraints.maxHeight * 0.4,
          );
          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: MobileScanner(
                  controller: _scannerController,
                  scanWindow: scanWindow,
                  onDetect: _handleDetection,
                  errorBuilder: (context, error, child) {
                    return ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: Text(
                          error.errorDetails?.message ?? 'Camera unavailable',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                    );
                  },
                  overlayBuilder: (context, overlayConstraints) {
                    final overlayRect = Rect.fromCenter(
                      center: overlayConstraints.biggest.center(Offset.zero),
                      width: overlayConstraints.maxWidth * 0.7,
                      height: overlayConstraints.maxHeight * 0.4,
                    );
                    return AnimatedBuilder(
                      animation: _scanLineController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _ScannerReticlePainter(
                            rect: overlayRect,
                            lineProgress: _scanLineController.value,
                            lineColor: AppColors.primaryFor(brightness),
                            borderColor: _hasDetectedCode
                                ? AppColors.accentFor(brightness)
                                : AppColors.surface.withValues(alpha: 0.8),
                          ),
                          child: const SizedBox.expand(),
                        );
                      },
                    );
                  },
                ),
              ),
              Positioned(
                top: AppSpacing.xl + AppSpacing.md,
                left: AppSpacing.md,
                right: AppSpacing.md,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      _OverlayActionButton(
                        icon: HugeIcons.strokeRoundedCancel01,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Point camera at barcode',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.surface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _OverlayActionButton(
                        icon:
                            _scannerController.value.torchState == TorchState.on
                            ? HugeIcons.strokeRoundedFlash
                            : HugeIcons.strokeRoundedFlashOff,
                        onTap: () => _scannerController.toggleTorch(),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: AppAnimations.medium,
                  curve: AppAnimations.easeInOut,
                  height: _panelHeight,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceFor(brightness),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.radiusLg),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _panelHeight == 0
                      ? const SizedBox.shrink()
                      : _ScannerBottomPanel(
                          state: _panelState,
                          barcodeValue: _barcodeValue,
                          product: _product,
                          errorMessage: _errorMessage,
                          onUseProduct: _product == null
                              ? null
                              : () => Navigator.of(context).pop(_product),
                          onScanAgain: _resetScanner,
                          onRetry: _retryLookup,
                          onEnterManually: () => Navigator.of(context).pop(),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double get _panelHeight {
    return switch (_panelState) {
      _ScannerPanelState.idle => 0,
      _ScannerPanelState.loading => 140,
      _ScannerPanelState.found => 220,
      _ScannerPanelState.notFound => 180,
      _ScannerPanelState.error => 180,
    };
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_hasDetectedCode || capture.barcodes.isEmpty) {
      return;
    }
    final value = capture.barcodes.first.rawValue?.trim();
    if (value == null || value.isEmpty) {
      return;
    }
    _hasDetectedCode = true;
    HapticFeedback.mediumImpact();
    setState(() {
      _barcodeValue = value;
      _panelState = _ScannerPanelState.loading;
      _product = null;
      _errorMessage = null;
    });
    await _scannerController.stop();
    await _lookupProduct(value);
  }

  Future<void> _lookupProduct(String barcode) async {
    try {
      final product = await ref
          .read(openFoodFactsServiceProvider)
          .lookupBarcode(barcode);
      if (!mounted) {
        return;
      }
      setState(() {
        _product = product;
        _panelState = product == null
            ? _ScannerPanelState.notFound
            : _ScannerPanelState.found;
      });
    } on OpenFoodFactsException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _panelState = _ScannerPanelState.error;
        _errorMessage = error.message;
      });
    }
  }

  Future<void> _retryLookup() async {
    final barcode = _barcodeValue;
    if (barcode == null || barcode.isEmpty) {
      return;
    }
    setState(() {
      _panelState = _ScannerPanelState.loading;
      _errorMessage = null;
    });
    await _lookupProduct(barcode);
  }

  Future<void> _resetScanner() async {
    _hasDetectedCode = false;
    setState(() {
      _barcodeValue = null;
      _product = null;
      _errorMessage = null;
      _panelState = _ScannerPanelState.idle;
    });
    await _scannerController.start();
  }
}

class _OverlayActionButton extends StatelessWidget {
  const _OverlayActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.surface),
      ),
    );
  }
}

class _ScannerBottomPanel extends StatelessWidget {
  const _ScannerBottomPanel({
    required this.state,
    required this.barcodeValue,
    required this.product,
    required this.errorMessage,
    required this.onUseProduct,
    required this.onScanAgain,
    required this.onRetry,
    required this.onEnterManually,
  });

  final _ScannerPanelState state;
  final String? barcodeValue;
  final OpenFoodProduct? product;
  final String? errorMessage;
  final VoidCallback? onUseProduct;
  final VoidCallback onScanAgain;
  final VoidCallback onRetry;
  final VoidCallback onEnterManually;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return switch (state) {
      _ScannerPanelState.loading => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            barcodeValue ?? '',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiaryFor(brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Looking up product...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryFor(brightness),
            ),
          ),
        ],
      ),
      _ScannerPanelState.found => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            barcodeValue ?? '',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiaryFor(brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          HearthListItemEntry(
            child: Text(
              product?.name ?? '',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimaryFor(brightness),
              ),
            ),
          ),
          if ((product?.brand ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              product!.brand,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryFor(brightness),
              ),
            ),
          ],
          if ((product?.quantityString ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              product!.quantityString,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiaryFor(brightness),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryContainerFor(brightness),
              borderRadius: BorderRadius.circular(AppRadius.radiusFull),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    shoppingSectionIcon(product!.inferredSection),
                    size: 18,
                    color: AppColors.primaryFor(brightness),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    product!.inferredSection.label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primaryFor(brightness),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: <Widget>[
              Expanded(
                child: HearthButton(
                  label: 'Use This Product',
                  onPressed: onUseProduct,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: HearthButton(
                  label: 'Scan Again',
                  variant: HearthButtonVariant.ghost,
                  onPressed: onScanAgain,
                ),
              ),
            ],
          ),
        ],
      ),
      _ScannerPanelState.notFound => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Product not found', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Try a different barcode or enter manually.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiaryFor(brightness),
            ),
          ),
          const Spacer(),
          Row(
            children: <Widget>[
              Expanded(
                child: HearthButton(
                  label: 'Enter Manually',
                  variant: HearthButtonVariant.secondary,
                  onPressed: onEnterManually,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: HearthButton(
                  label: 'Scan Again',
                  variant: HearthButtonVariant.ghost,
                  onPressed: onScanAgain,
                ),
              ),
            ],
          ),
        ],
      ),
      _ScannerPanelState.error => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "Couldn't connect to product database.",
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorMessage ?? 'Try again in a moment.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiaryFor(brightness),
            ),
          ),
          const Spacer(),
          Row(
            children: <Widget>[
              Expanded(
                child: HearthButton(label: 'Try Again', onPressed: onRetry),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: HearthButton(
                  label: 'Scan Again',
                  variant: HearthButtonVariant.ghost,
                  onPressed: onScanAgain,
                ),
              ),
            ],
          ),
        ],
      ),
      _ScannerPanelState.idle => const SizedBox.shrink(),
    };
  }
}

class _ScannerReticlePainter extends CustomPainter {
  const _ScannerReticlePainter({
    required this.rect,
    required this.lineProgress,
    required this.lineColor,
    required this.borderColor,
  });

  final Rect rect;
  final double lineProgress;
  final Color lineColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    const double arm = 20;
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      rect.topLeft,
      Offset(rect.left + arm, rect.top),
      borderPaint,
    );
    canvas.drawLine(
      rect.topLeft,
      Offset(rect.left, rect.top + arm),
      borderPaint,
    );
    canvas.drawLine(
      rect.topRight,
      Offset(rect.right - arm, rect.top),
      borderPaint,
    );
    canvas.drawLine(
      rect.topRight,
      Offset(rect.right, rect.top + arm),
      borderPaint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      Offset(rect.left + arm, rect.bottom),
      borderPaint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      Offset(rect.left, rect.bottom - arm),
      borderPaint,
    );
    canvas.drawLine(
      rect.bottomRight,
      Offset(rect.right - arm, rect.bottom),
      borderPaint,
    );
    canvas.drawLine(
      rect.bottomRight,
      Offset(rect.right, rect.bottom - arm),
      borderPaint,
    );

    final y = rect.top + (rect.height * lineProgress);
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(rect.left + AppSpacing.sm, y),
      Offset(rect.right - AppSpacing.sm, y),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerReticlePainter oldDelegate) {
    return oldDelegate.rect != rect ||
        oldDelegate.lineProgress != lineProgress ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.borderColor != borderColor;
  }
}
