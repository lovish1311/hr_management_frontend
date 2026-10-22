import 'dart:convert';
import 'package:flutter/material.dart';

enum ToastType {
  success,
  error,
  warning,
  info,
}

/// Unified, production-grade notification toast component for the entire HR Management system.
/// Enforces semantic consistency, responsive floating geometry, proper auto-dismiss intervals,
/// and defensive message sanitization to prevent raw developer exceptions or JSON from leaking to users.
class AppToast {
  AppToast._();

  /// Displays a success toast with an emerald badge and icon.
  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      type: ToastType.success,
      duration: duration,
      action: action,
    );
  }

  /// Displays an error toast with automatic sanitization of raw exceptions,
  /// HTTP status codes, or network errors into user-friendly copy.
  static void error(
    BuildContext context,
    dynamic errorOrMessage, {
    dynamic rawError,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    String msg = sanitizeErrorMessage(errorOrMessage);
    if (rawError != null) {
      final sanitizedDetail = sanitizeErrorMessage(rawError);
      if (sanitizedDetail.isNotEmpty &&
          sanitizedDetail != 'An unexpected error occurred. Please try again.') {
        msg = '$msg: $sanitizedDetail';
      }
    }
    show(
      context,
      message: msg,
      type: ToastType.error,
      duration: duration,
      action: action,
    );
  }

  /// Displays a warning toast with an amber badge and icon.
  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      type: ToastType.warning,
      duration: duration,
      action: action,
    );
  }

  /// Displays an informational toast with a primary/indigo badge and icon.
  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      type: ToastType.info,
      duration: duration,
      action: action,
    );
  }

  /// Master method for dispatching a styled floating SnackBar.
  static void show(
    BuildContext context, {
    required String message,
    required ToastType type,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    // Remove any currently displayed snackbar to prevent stacking queues
    messenger.hideCurrentSnackBar();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Semantic tokens
    Color iconColor;
    Color borderColor;
    Color backgroundColor;
    IconData iconData;

    switch (type) {
      case ToastType.success:
        iconColor = const Color(0xFF10B981);
        borderColor = const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.45);
        backgroundColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
        iconData = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        iconColor = const Color(0xFFEF4444);
        borderColor = const Color(0xFFEF4444).withValues(alpha: isDark ? 0.35 : 0.45);
        backgroundColor = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2);
        iconData = Icons.error_rounded;
        break;
      case ToastType.warning:
        iconColor = const Color(0xFFF59E0B);
        borderColor = const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.35 : 0.45);
        backgroundColor = isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB);
        iconData = Icons.warning_amber_rounded;
        break;
      case ToastType.info:
        iconColor = const Color(0xFF6366F1);
        borderColor = const Color(0xFF6366F1).withValues(alpha: isDark ? 0.35 : 0.45);
        backgroundColor = isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF);
        iconData = Icons.info_outline_rounded;
        break;
    }

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    messenger.showSnackBar(
      SnackBar(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        backgroundColor: backgroundColor,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
        action: action,
        content: Row(
          children: [
            Icon(iconData, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Defensively translates raw developer exceptions, HTTP statuses, or API JSON bodies into
  /// friendly, production-grade user messages.
  static String sanitizeErrorMessage(dynamic raw) {
    if (raw == null) {
      return 'Something went wrong. Please try again.';
    }

    String text = raw.toString().trim();

    // Check for empty string
    if (text.isEmpty) {
      return 'An unexpected error occurred. Please try again.';
    }

    // Try extracting message from JSON structure if backend returned raw JSON body
    if (text.startsWith('{') && text.endsWith('}')) {
      try {
        final decoded = json.decode(text);
        if (decoded is Map) {
          final candidate = decoded['message'] ?? decoded['error'] ?? decoded['details'];
          if (candidate != null && candidate.toString().trim().isNotEmpty) {
            text = candidate.toString().trim();
          }
        }
      } catch (_) {
        // Fall through to regex-based sanitization
      }
    }

    // Strip common Dart exception wrappers
    if (text.startsWith('Exception:')) {
      text = text.replaceFirst('Exception:', '').trim();
    }
    if (text.startsWith('ClientException:')) {
      text = text.replaceFirst('ClientException:', '').trim();
    }

    final lower = text.toLowerCase();

    // Network / Connectivity errors
    if (lower.contains('socketexception') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('network error') ||
        lower.contains('failed to connect') ||
        lower.contains('xmlhttprequest error') ||
        lower.contains('network is unreachable')) {
      return 'Network connection issue. Please check your internet and try again.';
    }

    // Timeout errors
    if (lower.contains('timeoutexception') || lower.contains('timed out')) {
      return 'Connection timed out. Please try again.';
    }

    // Auth / Session expiry
    if (lower.contains('401') || lower.contains('session expired') || lower.contains('unauthorized')) {
      return 'Your session has expired. Please log in again to continue.';
    }

    // Forbidden / Permissions
    if (lower.contains('403') || lower.contains('forbidden') || lower.contains('access denied')) {
      return 'You do not have permission to perform this action.';
    }

    // Not found
    if (lower.contains('404') || lower.contains('not found')) {
      return 'The requested resource was not found.';
    }

    // Internal Server Error
    if (lower.contains('500') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('internal server error') ||
        lower.contains('nullpointerexception')) {
      return 'Server is temporarily unavailable. Please try again later.';
    }

    // Raw HTTP status code prefixes e.g. "Failed to clear: 500 {..."
    if (RegExp(r'\b\d{3}\b').hasMatch(text) && (text.contains('{') || text.contains('}'))) {
      return 'Operation failed. Please try again.';
    }

    // Capitalize first letter if needed
    if (text.isNotEmpty) {
      text = text[0].toUpperCase() + text.substring(1);
    }

    // Ensure ending punctuation
    if (!text.endsWith('.') && !text.endsWith('!') && !text.endsWith('?')) {
      text = '$text.';
    }

    return text;
  }
}
