import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AccessibilityUtils {
  static const double _minimumTapSize = 48.0;
  static const double _minimumTextSize = 14.0;

  static Widget makeAccessible({
    required Widget child,
    required String label,
    String? hint,
    VoidCallback? onTap,
    bool isButton = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      child: ExcludeSemantics(
        child: child,
      ),
    );
  }

  static Widget makeTappable({
    required Widget child,
    required String label,
    String? hint,
    VoidCallback? onTap,
    bool isButton = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: _minimumTapSize,
            minHeight: _minimumTapSize,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  static Widget makeScrollable({
    required Widget child,
    required String label,
    String? hint,
    ScrollController? controller,
    bool primary = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      scrollable: true,
      child: SingleChildScrollView(
        controller: controller,
        primary: primary,
        child: child,
      ),
    );
  }

  static Widget makeImageAccessible({
    required Widget child,
    required String label,
    String? hint,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      image: true,
      child: child,
    );
  }

  static Widget makeTextFieldAccessible({
    required Widget child,
    required String label,
    String? hint,
    TextEditingController? controller,
    FocusNode? focusNode,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onChanged,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onSubmitted,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      textField: true,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onEditingComplete: onEditingComplete,
        onSubmitted: onSubmitted,
        style: const TextStyle(fontSize: _minimumTextSize),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
      ),
    );
  }

  static Widget makeButtonAccessible({
    required Widget child,
    required String label,
    String? hint,
    VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: onPressed != null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: isPrimary
            ? ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
              )
            : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: _minimumTapSize,
            minHeight: _minimumTapSize,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  static Widget makeIconAccessible({
    required IconData icon,
    required String label,
    String? hint,
    VoidCallback? onTap,
    double size = 24.0,
    Color? color,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: _minimumTapSize,
            minHeight: _minimumTapSize,
          ),
          child: Center(
            child: Icon(
              icon,
              size: size,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  static Widget makeTextAccessible({
    required String text,
    required String label,
    String? hint,
    TextStyle? style,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      child: Text(
        text,
        style: style?.copyWith(fontSize: _minimumTextSize) ??
            const TextStyle(fontSize: _minimumTextSize),
      ),
    );
  }
} 