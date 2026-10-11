import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionStatusState {
  final bool isGranted;
  final bool isPermanentlyDenied;
  final String smsStatus;
  final String notifStatus;

  const PermissionStatusState({
    required this.isGranted,
    required this.isPermanentlyDenied,
    required this.smsStatus,
    required this.notifStatus,
  });
}

class PermissionService {
  static Future<PermissionStatusState> checkPermissions() async {
    if (kIsWeb) {
      return const PermissionStatusState(
        isGranted: true,
        isPermanentlyDenied: false,
        smsStatus: 'granted',
        notifStatus: 'granted',
      );
    }

    final smsStatus = await Permission.sms.status;
    final notifStatus = await Permission.notification.status;

    return PermissionStatusState(
      isGranted: smsStatus.isGranted,
      isPermanentlyDenied: smsStatus.isPermanentlyDenied,
      smsStatus: smsStatus.toString(),
      notifStatus: notifStatus.toString(),
    );
  }

  static Future<PermissionStatusState> requestPermissions() async {
    if (kIsWeb) {
      return const PermissionStatusState(
        isGranted: true,
        isPermanentlyDenied: false,
        smsStatus: 'granted',
        notifStatus: 'granted',
      );
    }

    final statuses = await [
      Permission.sms,
      Permission.notification,
    ].request();

    final smsStatus = statuses[Permission.sms] ?? PermissionStatus.denied;
    final notifStatus = statuses[Permission.notification] ?? PermissionStatus.denied;

    return PermissionStatusState(
      isGranted: smsStatus.isGranted,
      isPermanentlyDenied: smsStatus.isPermanentlyDenied,
      smsStatus: smsStatus.toString(),
      notifStatus: notifStatus.toString(),
    );
  }

  static Future<bool> openSettings() async {
    return openAppSettings();
  }
}
