import 'dart:io';
import 'package:flutter/foundation.dart';

/// Lightweight, best-effort device-integrity (root/jailbreak) check.
///
/// Rooted devices can bypass sandboxing, FLAG_SECURE and keystore protections,
/// so we surface a non-blocking warning for a financial app. Deliberately
/// advisory (not a hard block) to avoid false positives on legitimate devices,
/// and skipped entirely on non-mobile / debug to keep the demo + emulators
/// usable.
class IntegrityService {
  /// Common su binaries / root-management app paths.
  static const _rootPaths = [
    '/system/app/Superuser.apk',
    '/sbin/su',
    '/system/bin/su',
    '/system/xbin/su',
    '/data/local/xbin/su',
    '/data/local/bin/su',
    '/system/sd/xbin/su',
    '/system/bin/failsafe/su',
    '/data/local/su',
    '/su/bin/su',
    '/system/bin/.ext/.su',
    '/system/xbin/daemonsu',
    '/data/adb/magisk',
    '/sbin/.magisk',
  ];

  /// Returns true if the device shows signs of being rooted. Android only;
  /// returns false in debug, on iOS, web, desktop.
  static bool get isCompromised {
    if (kDebugMode) return false;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      for (final p in _rootPaths) {
        if (File(p).existsSync()) return true;
      }
      // Root-managed builds often expose busybox or test-keys.
      if (File('/system/xbin/busybox').existsSync()) return true;
    } catch (_) {
      // File access denied is the normal, non-rooted case.
    }
    return false;
  }
}
