import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'providers/scam_provider.dart';
import 'utils/app_theme.dart';
import 'utils/app_translations.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/receipt_check_screen.dart';
import 'screens/tools_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/welcome_briefing_dialog.dart';

import 'services/sms_channel_service.dart';
import 'services/permission_service.dart';

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

    // Decoupled native SMS listener
    SmsChannelService.initialize(
      navigatorKey: navigatorKey,
      notificationsPlugin: flutterLocalNotificationsPlugin,
    );
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
      title: 'Meketa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _permissionsGranted = false;
  bool _permissionChecked = false;
  bool _isPermanentlyDenied = false;
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
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        WelcomeBriefingDialog.checkAndShow(context);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Automatically re-verify permissions when user returns from Settings
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final status = await PermissionService.checkPermissions();
    if (!mounted) return;

    setState(() {
      _smsPermStatus = status.smsStatus;
      _notifPermStatus = status.notifStatus;
      _permissionsGranted = status.isGranted;
      _isPermanentlyDenied = status.isPermanentlyDenied;
      _permissionChecked = true;
    });
  }

  Future<void> _requestPermissions() async {
    if (_isPermanentlyDenied) {
      await PermissionService.openSettings();
      return;
    }

    final status = await PermissionService.requestPermissions();
    if (!mounted) return;

    setState(() {
      _smsPermStatus = status.smsStatus;
      _notifPermStatus = status.notifStatus;
      _permissionsGranted = status.isGranted;
      _isPermanentlyDenied = status.isPermanentlyDenied;
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
                if (_isPermanentlyDenied) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.danger, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'SMS permission is permanently disabled. Please tap below to open Android App Settings and grant permission.',
                            style: TextStyle(fontSize: 12.5, color: AppColors.danger, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                      _isPermanentlyDenied ? 'Open App Settings' : 'Grant Permission',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (_isPermanentlyDenied) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _checkPermissions,
                    child: const Text('Check Status Again'),
                  ),
                ],
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
