import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../models/scam_model.dart';
import '../providers/scam_provider.dart';
import '../screens/scam_alert_screen.dart';

/// Decoupled native SMS channel listener and alert dispatcher
class SmsChannelService {
  static const MethodChannel _channel = MethodChannel('sms_channel');
  static bool _isInitialized = false;

  /// Initialize listener with navigator key and notification plugin
  static void initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    required FlutterLocalNotificationsPlugin notificationsPlugin,
  }) {
    if (_isInitialized) return;
    _isInitialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSmsReceived') {
        try {
          final args = call.arguments as Map?;
          if (args == null) return;
          final sender = (args['sender'] as String?) ?? '';
          final body = (args['body'] as String?) ?? '';

          if (body.isEmpty) return;

          final context = navigatorKey.currentContext;
          if (context == null) {
            debugPrint('[SmsChannelService] Navigator context not available');
            return;
          }

          final provider = Provider.of<ScamProvider>(context, listen: false);
          final alert = await provider.analyzeAndSave(body, sender);

          if (alert.shouldNotify) {
            await _dispatchNotification(notificationsPlugin, alert);

            // Navigate safely without unmounted context risks
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => ScamAlertScreen(alert: alert),
              ),
            );
          }
        } catch (e) {
          debugPrint('[SmsChannelService] Error handling incoming SMS: $e');
        }
      }
    });
  }

  static Future<void> _dispatchNotification(
    FlutterLocalNotificationsPlugin plugin,
    ScamModel alert,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'scam_alerts',
      'Scam Alerts',
      channelDescription: 'High precision alerts for detected scam messages',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFD32F2F),
    );
    const details = NotificationDetails(android: androidDetails);
    await plugin.show(
      alert.id ?? 0,
      '🚨 POSSIBLE SCAM DETECTED',
      '${alert.claimedOrganization ?? "Suspicious Sender"}: Possible fraud attempt detected',
      details,
    );
  }
}
