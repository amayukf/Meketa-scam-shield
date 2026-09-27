import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'providers/scam_provider.dart';
import 'utils/app_theme.dart';
import 'utils/app_translations.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/receipt_check_screen.dart';
import 'screens/tools_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/scam_alert_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications on supported platforms
  if (!kIsWeb) {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await flutterLocalNotificationsPlugin.initialize(initSettings);
    } catch (e) {
      debugPrint('[ScamShield] Notification init error: $e');
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ScamProvider()..initialize(),
      child: const ScamShieldApp(),
    ),
  );
}

class ScamShieldApp extends StatelessWidget {
  const ScamShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'መከታ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      navigatorKey: navigatorKey,
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  static const _channel = MethodChannel('sms_channel');
  bool _permissionsGranted = false;
  bool _permissionChecked = false;
  String _smsPermStatus = '…';
  String _notifPermStatus = '…';

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    ReceiptCheckScreen(),
    ToolsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _setupSmsChannel();
  }

  Future<void> _checkPermissions() async {
    if (kIsWeb) {
      setState(() {
        _smsPermStatus = 'granted';
        _notifPermStatus = 'granted';
        _permissionsGranted = true;
        _permissionChecked = true;
      });
      return;
    }

    final smsStatus = await Permission.sms.status;
    final notifStatus = await Permission.notification.status;

    setState(() {
      _smsPermStatus = smsStatus.toString();
      _notifPermStatus = notifStatus.toString();
      _permissionsGranted = smsStatus.isGranted;
      _permissionChecked = true;
    });

    debugPrint('[ScamShield] SMS permission: $smsStatus');
    debugPrint('[ScamShield] Notification permission: $notifStatus');
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      setState(() {
        _permissionsGranted = true;
      });
      return;
    }
    final statuses = await [
      Permission.sms,
      Permission.notification,
    ].request();

    final smsGranted = statuses[Permission.sms]?.isGranted ?? false;

    setState(() {
      _smsPermStatus = statuses[Permission.sms].toString();
      _notifPermStatus = statuses[Permission.notification].toString();
      _permissionsGranted = smsGranted;
    });

    debugPrint('[ScamShield] After request — SMS: ${statuses[Permission.sms]}, Notification: ${statuses[Permission.notification]}');
  }

  void _setupSmsChannel() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSmsReceived') {
        final args = call.arguments as Map;
        final sender = args['sender'] as String;
        final body = args['body'] as String;

        debugPrint('[ScamShield] SMS received from: $sender');

        final provider = Provider.of<ScamProvider>(context, listen: false);
        final alert = await provider.analyzeAndSave(body, sender);

        debugPrint('[ScamShield] Analysis result: confidence=${alert.confidence}, isScam=${alert.isScam}, notify=${alert.shouldNotify}');

        if (alert.shouldNotify) {
          // Show high precision notification
          const androidDetails = AndroidNotificationDetails(
            'scam_alerts',
            'Scam Alerts',
            channelDescription: 'High precision alerts for detected scam messages',
            importance: Importance.high,
            priority: Priority.high,
            color: Color(0xFFD32F2F),
          );
          const details = NotificationDetails(android: androidDetails);
          await flutterLocalNotificationsPlugin.show(
            alert.id ?? 0,
            '🚨 POSSIBLE SCAM DETECTED',
            '${alert.claimedOrganization ?? "Unknown Sender"} (${alert.sender}): ${alert.message}',
            details,
          );

          // Navigate to alert screen
          if (mounted) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => ScamAlertScreen(alert: alert),
              ),
            );
          }
        }
      }
    });
  }

  void onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show permission request screen if not granted
    if (_permissionChecked && !_permissionsGranted) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Scam Shield needs\nSMS access',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'To protect you from scam messages, we need permission to read incoming SMS. Your data stays on your device — nothing is sent to any server.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                // Permission status indicator
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      _PermissionRow(
                        label: 'SMS',
                        status: _smsPermStatus,
                      ),
                      const Divider(height: 16),
                      _PermissionRow(
                        label: 'Notifications',
                        status: _notifPermStatus,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _requestPermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Grant Permission',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentLang = context.watch<ScamProvider>().currentLanguage;

    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: onItemTapped,
                selectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_rounded),
                    activeIcon: const Icon(Icons.home_rounded),
                    label: AppTranslations.get(currentLang, 'nav_home'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.history_rounded),
                    activeIcon: const Icon(Icons.history_rounded),
                    label: AppTranslations.get(currentLang, 'nav_history'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.receipt_long_rounded),
                    activeIcon: const Icon(Icons.receipt_long_rounded),
                    label: AppTranslations.get(currentLang, 'nav_receipt_checker'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.shield_rounded),
                    activeIcon: const Icon(Icons.shield_rounded),
                    label: AppTranslations.get(currentLang, 'nav_tools'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.settings_rounded),
                    activeIcon: const Icon(Icons.settings_rounded),
                    label: AppTranslations.get(currentLang, 'nav_settings'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
}
}

class _PermissionRow extends StatelessWidget {
  final String label;
  final String status;

  const _PermissionRow({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final isGranted = status.contains('granted');
    return Row(
      children: [
        Icon(
          isGranted ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isGranted ? AppColors.safe : AppColors.danger,
          size: 18,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          isGranted ? 'Granted' : 'Not granted',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isGranted ? AppColors.safe : AppColors.danger,
          ),
        ),
      ],
    );
  }
}
