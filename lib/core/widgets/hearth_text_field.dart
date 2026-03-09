import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';

class HearthTextField extends StatefulWidget {
  const HearthTextField({
    required this.label,
    this.controller,
    this.focusNode,
    this.hintText,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.obscureText = false,
    this.maxLines = 1,
    this.prefix,
    this.suffix,
    this.readOnly = false,
    this.onTap,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final int maxLines;
  final Widget? prefix;
  final Widget? suffix;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  State<HearthTextField> createState() => _HearthTextFieldState();
}

class _HearthTextFieldState extends State<HearthTextField> {
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocus);
  }

  void _handleFocus() {
    setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final borderColor = _errorText != null
        ? AppColors.errorFor(brightness)
        : _focusNode.hasFocus
        ? AppColors.primaryLight
        : AppColors.dividerFor(brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AnimatedContainer(
          duration: AppAnimations.fast,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariantFor(brightness),
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
            border: Border.all(color: borderColor),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            validator: (String? value) {
              final result = widget.validator?.call(value);
              setState(() {
                _errorText = result;
              });
              return result;
            },
            onChanged: (_) {
              if (_errorText != null) {
                setState(() {
                  _errorText = null;
                });
              }
            },
            onTap: widget.onTap,
            readOnly: widget.readOnly,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimaryFor(brightness),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              labelText: widget.label,
              hintText: widget.hintText,
              prefixIcon: widget.prefix == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.md),
                      child: widget.prefix,
                    ),
              suffixIcon: widget.suffix == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: widget.suffix,
                    ),
            ),
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onSubmitted,
            obscureText: widget.obscureText,
            maxLines: widget.maxLines,
          ),
        ),
      ],
    );
  }
}
