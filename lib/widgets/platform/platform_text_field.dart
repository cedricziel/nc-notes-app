import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'platform_service.dart';

/// A platform-aware text field widget that uses either a [CupertinoTextField]
/// or a [TextField] based on the platform.
class PlatformTextField extends StatelessWidget {
  /// The controller for the text field.
  final TextEditingController? controller;

  /// The focus node for the text field.
  final FocusNode? focusNode;

  /// The decoration for the text field.
  final InputDecoration? decoration;

  /// The placeholder text for the text field.
  final String? placeholder;

  /// The style of the text in the text field.
  final TextStyle? style;

  /// The style of the placeholder text.
  final TextStyle? placeholderStyle;

  /// The keyboard type for the text field.
  final TextInputType? keyboardType;

  /// Whether the text field is obscured.
  final bool obscureText;

  /// Whether the text field is enabled.
  final bool enabled;

  /// The maximum number of lines for the text field.
  final int? maxLines;

  /// The minimum number of lines for the text field.
  final int? minLines;

  /// The maximum length of the text field.
  final int? maxLength;

  /// The callback that is called when the text field's text changes.
  final ValueChanged<String>? onChanged;

  /// The callback that is called when the text field is submitted.
  final ValueChanged<String>? onSubmitted;

  /// The callback that is called when the text field gains or loses focus.
  final ValueChanged<bool>? onFocusChange;

  /// Whether the text field should be focused when first displayed.
  final bool autofocus;

  /// Creates a platform-aware text field.
  const PlatformTextField({
    Key? key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.placeholder,
    this.style,
    this.placeholderStyle,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.onFocusChange,
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (PlatformService.useCupertino) {
      // iOS-style text field
      return Focus(
        onFocusChange: onFocusChange,
        child: CupertinoTextField(
          controller: controller,
          focusNode: focusNode,
          placeholder: placeholder,
          style: style,
          placeholderStyle: placeholderStyle ??
              TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          autofocus: autofocus,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            border: Border.all(
              color: CupertinoColors.systemGrey4.resolveFrom(context),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else {
      // Android-style text field
      // Wrap in Material to provide MaterialLocalizations
      return Material(
        // Use transparent type to not affect the visual appearance
        type: MaterialType.transparency,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: decoration ??
              InputDecoration(
                hintText: placeholder,
                hintStyle: placeholderStyle,
                border: const OutlineInputBorder(),
              ),
          style: style,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          autofocus: autofocus,
        ),
      );
    }
  }
}
