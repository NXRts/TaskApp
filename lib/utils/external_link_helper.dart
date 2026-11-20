import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Launches external HTTP/HTTPS URLs cleanly with platform channels / OS commands
/// and falls back to copying to clipboard when no browser handler is available.
class ExternalLinkHelper {
  static const MethodChannel _channel = MethodChannel('com.taskapp.taskapp/settings');

  /// Validates that [url] is an HTTP or HTTPS URI.
  static bool isValidHttpUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  /// Opens [url] externally, falling back to clipboard copy with feedback on failure.
  static Future<bool> openUrl(
    BuildContext context,
    String url, {
    String? label,
    Future<bool> Function(String url)? launcherOverride,
  }) async {
    final trimmed = url.trim();
    if (!isValidHttpUrl(trimmed)) return false;

    bool launched = false;
    try {
      if (launcherOverride != null) {
        launched = await launcherOverride(trimmed);
      } else {
        launched = await _launchPlatformUrl(trimmed);
      }
    } catch (_) {
      launched = false;
    }

    if (!launched && context.mounted) {
      await copyUrl(
        context,
        trimmed,
        message: 'Tidak dapat membuka browser. Tautan ${label ?? ''} disalin ke clipboard.',
      );
    }
    return launched;
  }

  /// Copies [url] to the system clipboard and displays a confirmation snackbar.
  static Future<void> copyUrl(
    BuildContext context,
    String url, {
    String? label,
    String? message,
  }) async {
    await Clipboard.setData(ClipboardData(text: url.trim()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ?? 'Tautan ${label != null ? '$label ' : ''}disalin ke clipboard!',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Future<bool> _launchPlatformUrl(String url) async {
    if (Platform.isAndroid) {
      final result = await _channel.invokeMethod<bool>('openExternalUrl', {'url': url});
      return result == true;
    }
    if (Platform.isLinux) {
      await Process.start('xdg-open', [url], mode: ProcessStartMode.detached);
      return true;
    }
    if (Platform.isMacOS) {
      await Process.start('open', [url], mode: ProcessStartMode.detached);
      return true;
    }
    if (Platform.isWindows) {
      await Process.start('cmd', ['/c', 'start', '', url], mode: ProcessStartMode.detached);
      return true;
    }
    return false;
  }
}
