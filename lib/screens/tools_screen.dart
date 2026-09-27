import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/virustotal_service.dart';
import '../widgets/education_hub_widget.dart';
import '../utils/app_theme.dart';
import 'ai_chat_screen.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _urlController = TextEditingController();
  LinkScanResult? _scanResult;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleScan() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isScanning = true;
    });

    final result = await VirusTotalService.scanLink(url);

    setState(() {
      _scanResult = result;
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Security Hub',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.link_rounded, size: 20),
              text: 'Link Checker',
            ),
            Tab(
              icon: Icon(Icons.school_rounded, size: 20),
              text: 'Education Hub',
            ),
            Tab(
              icon: Icon(Icons.auto_awesome_rounded, size: 20),
              text: 'AI Assistant',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Link Checker (VirusTotal API)
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_rounded,
                              color: AppColors.primary, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'VirusTotal Link Inspector',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Scan web links, Telegram links, or suspicious bank URLs for malware and typosquatting phishing domains.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _urlController,
                        style: GoogleFonts.robotoMono(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Paste URL (e.g., https://cbe-bonus.com)',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.6),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.divider),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isScanning ? null : _handleScan,
                          icon: _isScanning
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.travel_explore_rounded,
                                  size: 20),
                          label: Text(
                            _isScanning ? 'Scanning Link…' : 'Scan Link Safety',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Scan Results
                if (_scanResult != null) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _scanResult!.isMalicious
                            ? AppColors.danger.withValues(alpha: 0.5)
                            : AppColors.safe.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _scanResult!.isMalicious
                                  ? Icons.dangerous_rounded
                                  : Icons.verified_user_rounded,
                              color: _scanResult!.isMalicious
                                  ? AppColors.danger
                                  : AppColors.safe,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _scanResult!.verdict,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _scanResult!.isMalicious
                                          ? AppColors.danger
                                          : AppColors.safe,
                                    ),
                                  ),
                                  Text(
                                    _scanResult!.url,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Text(
                          _scanResult!.details,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        if (_scanResult!.detectedThreats.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ..._scanResult!.detectedThreats.map(
                            (threat) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      size: 16, color: AppColors.danger),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      threat,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Tab 2: Education Hub
          const EducationHubWidget(),

          // Tab 3: AI Security Assistant
          const AiChatScreen(),
        ],
      ),
    );
  }
}
