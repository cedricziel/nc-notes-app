import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'platform_service.dart';

/// A platform-aware text field widget that uses either a [CupertinoTextField]
/// or a [TextField] based on the platform.
///
/// This is a wrapper around flutter_platform_widgets' PlatformTextField that
/// adds support for additional parameters like decoration and placeholder.
class PlatformTextField extends StatelessWidget {
  /// The controller for this text field.
  final TextEditingController? controller;

  /// The decoration to show around the text field.
  final InputDecoration? decoration;

  /// The placeholder text to show when the text field is empty.
  final String? placeholder;

  /// The style to use for the text being edited.
  final TextStyle? style;

  /// The type of keyboard to use for editing the text.
  final TextInputType? keyboardType;

  /// Whether the text field is obscured.
  final bool obscureText;

  /// Called when the user submits editable content.
  final ValueChanged<String>? onSubmitted;

  /// Called when the user changes the text in the text field.
  final ValueChanged<String>? onChanged;

  /// Whether the text field is enabled.
  final bool enabled;

  /// Whether the text field should be focused initially.
  final bool autofocus;

  /// The padding around the text field.
  final EdgeInsetsGeometry? padding;

  /// Creates a platform-aware text field.
  const PlatformTextField({
    super.key,
    this.controller,
    this.decoration,
    this.placeholder,
    this.style,
    this.keyboardType,
    this.obscureText = false,
    this.onSubmitted,
    this.onChanged,
    this.enabled = true,
    this.autofocus = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformService.useCupertino) {
      // iOS-style text field
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder ?? decoration?.hintText,
        style: style,
        keyboardType: keyboardType,
        obscureText: obscureText ?? false,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        enabled: enabled,
        padding: padding ?? const EdgeInsets.all(12),
        prefix: decoration?.prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: decoration!.prefixIcon,
              )
            : null,
        suffix: decoration?.suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: decoration!.suffixIcon,
              )
            : null,
        decoration: BoxDecoration(
          border: Border.all(
            color: CupertinoColors.systemGrey4,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    } else {
      // Android-style text field
      return TextField(
        controller: controller,
        decoration: decoration ??
            InputDecoration(
              hintText: placeholder,
              border: const OutlineInputBorder(),
            ),
        style: style,
        keyboardType: keyboardType,
        obscureText: obscureText ?? false,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        enabled: enabled,
      );
    }
  }
}
