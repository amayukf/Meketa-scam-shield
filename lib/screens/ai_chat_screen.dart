import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/gemini_service.dart';
import '../providers/scam_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

class _ChatMessage {
  final bool isUser;
  final String text;
  final DateTime timestamp;
  const _ChatMessage({
    required this.isUser,
    required this.text,
    required this.timestamp,
  });
}

class _QuickPrompt {
  final String label;
  final String prompt;
  final IconData icon;
  final Color color;
  const _QuickPrompt({
    required this.label,
    required this.prompt,
    required this.icon,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<_ChatMessage> _messages = [];
  final List<GeminiChatMessage> _history = [];
  bool _isLoading = false;

  static const _quickPrompts = [
    _QuickPrompt(
      label: 'Fake Telebirr SMS',
      prompt: 'How do I tell if a Telebirr transfer SMS is genuine or fake?',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF10B981),
    ),
    _QuickPrompt(
      label: 'Shared my OTP',
      prompt:
          'I accidentally gave my SMS verification OTP to someone. What exact steps should I take right now?',
      icon: Icons.lock_open_rounded,
      color: Color(0xFFEF4444),
    ),
    _QuickPrompt(
      label: 'Verify CBE credit',
      prompt:
          'How do I safely verify a Commercial Bank of Ethiopia (CBE) credited alert?',
      icon: Icons.account_balance_rounded,
      color: Color(0xFF3B82F6),
    ),
    _QuickPrompt(
      label: 'የቴሌብር ማጭበርበር',
      prompt: 'የቴሌብር የገንዘብ ማጭበርበር SMS መልዕክቶችን እንዴት መለየት እችላለሁ?',
      icon: Icons.language_rounded,
      color: Color(0xFFF59E0B),
    ),
    _QuickPrompt(
      label: 'Suspicious link',
      prompt: 'I received a link claiming to be from a bank. How do I check if it\'s safe?',
      icon: Icons.link_rounded,
      color: Color(0xFF8B5CF6),
    ),
    _QuickPrompt(
      label: 'USSD code danger',
      prompt: 'Someone sent me a USSD code to dial. Could it drain my airtime or forward my calls?',
      icon: Icons.dialpad_rounded,
      color: Color(0xFFF97316),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _addWelcome();
  }

  void _addWelcome() {
    _messages.add(_ChatMessage(
      isUser: false,
      text:
          'Hello! I\'m the **Meketa AI Security Assistant**, powered by Gemini.\n\nI can help you identify scam messages, verify suspicious bank alerts, and protect yourself from digital fraud in Ethiopia.\n\nAsk me anything in **English** or **አማርኛ**.',
      timestamp: _epoch,
    ));
  }

  static final _epoch = DateTime(2000);

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<bool> _showCloudConsentDialog() async {
    final lang = context.read<ScamProvider>().currentLanguage;
    final isAmharic = lang == 'Amharic';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF131D31),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_rounded, color: Color(0xFF3B82F6), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isAmharic ? 'የክላውድ AI ፈቃድ' : 'Cloud AI Consent',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAmharic
                  ? 'መከታ AI ከ Google Gemini ጋር ተገናኝቶ ለጥያቄዎችዎ መልስ ይሰጣል።\n\n• የጽሑፍ ጥያቄዎ ወደ Google Cloud AI ይላካል\n• የግል SMS ወይም ምስጢራዊ መረጃ አይቀመጥም\n• ይህን ፈቃድ በማንኛውም ጊዜ በቅንብሮች ማጥፋት ይችላሉ'
                  : 'Meketa AI connects to Google Gemini services to provide intelligent cybersecurity advice.\n\n• Your query text will be transmitted to Google Gemini AI\n• Personal SMS messages and credentials are never stored or sold\n• You can toggle this off anytime in Settings',
              style: GoogleFonts.inter(
                color: const Color(0xFFCBD5E1),
                fontSize: 13.5,
                height: 1.55,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              isAmharic ? 'ይቅር' : 'Keep Offline',
              style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isAmharic ? 'እፈቅዳለሁ' : 'Consent & Continue',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _send(String text) async {
    final msg = text.trim();
    if (msg.isEmpty || _isLoading) return;

    final provider = context.read<ScamProvider>();
    if (!provider.allowCloudAiAnalysis) {
      final consented = await _showCloudConsentDialog();
      if (!consented) {
        setState(() {
          _messages.add(_ChatMessage(
            isUser: false,
            text: provider.currentLanguage == 'Amharic'
                ? '🔒 **የክላውድ AI አገልግሎት ተዘግቷል**\n\nየእርስዎን ግላዊነት ለመጠበቅ ክላውድ AI በነባሪነት ጠፍቷል። የAI ረዳቱን ለመጠቀም ከፈለጉ በቅንብሮች ውስጥ ማብራት ይችላሉ።'
                : '🔒 **Cloud AI is disabled**\n\nTo preserve your privacy, external cloud AI queries are off by default. You can enable Cloud AI in Settings or grant consent when prompted.',
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
        return;
      }
      await provider.setAllowCloudAiAnalysis(true);
    }

    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: msg, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    final reply = await GeminiService.chatWithAssistant(_history, msg);
    if (!mounted) return;

    _history.add(GeminiChatMessage(role: 'user', text: msg));
    _history.add(GeminiChatMessage(role: 'model', text: reply));

    setState(() {
      _messages.add(_ChatMessage(isUser: false, text: reply, timestamp: DateTime.now()));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _history.clear();
      _messages.clear();
      _addWelcome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<ScamProvider>().currentLanguage;
    final hint = lang == 'Amharic'
        ? 'ጥያቄዎን ይጻፉ...'
        : 'Ask about scams, receipts, OTP safety...';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Column(
        children: [
          _buildHeader(),
          _buildMessages(),
          if (_isLoading) _buildTypingBubble(),
          if (_messages.length <= 1) _buildQuickPrompts(),
          _buildInput(hint),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1422),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          // Animated AI avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meketa AI',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Online • Ethiopian Cyber Security Expert',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_messages.length > 1)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white38, size: 20),
              tooltip: 'New conversation',
              onPressed: _clearChat,
            ),
        ],
      ),
    );
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  Widget _buildMessages() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        itemCount: _messages.length,
        itemBuilder: (ctx, i) => _MessageBubble(
          message: _messages[i],
          onCopy: (text) {
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Copied to clipboard',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
                ),
                backgroundColor: const Color(0xFF1E293B),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Typing indicator ───────────────────────────────────────────────────────

  Widget _buildTypingBubble() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF131929),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  // ── Quick Prompts ──────────────────────────────────────────────────────────

  Widget _buildQuickPrompts() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'SUGGESTED QUESTIONS',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white24,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickPrompts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final qp = _quickPrompts[i];
                return GestureDetector(
                  onTap: () => _send(qp.prompt),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: qp.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: qp.color.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(qp.icon, color: qp.color, size: 18),
                        Text(
                          qp.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Bar ──────────────────────────────────────────────────────────────

  Widget _buildInput(String hint) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1422),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFF131929),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 5,
                minLines: 1,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.white24,
                    fontSize: 13.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: (_controller.text.trim().isNotEmpty && !_isLoading)
                  ? const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: (_controller.text.trim().isEmpty || _isLoading)
                  ? Colors.white.withValues(alpha: 0.06)
                  : null,
              shape: BoxShape.circle,
              boxShadow: (_controller.text.trim().isNotEmpty && !_isLoading)
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: _isLoading ? null : () => _send(_controller.text),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white54,
                          ),
                        )
                      : const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message Bubble Widget
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final void Function(String) onCopy;

  const _MessageBubble({required this.message, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isWelcome = message.timestamp == DateTime(2000);
    final timeStr = isWelcome
        ? ''
        : '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // AI avatar
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 15),
            ),
          ],

          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.76,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser ? null : const Color(0xFF131929),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: Colors.white.withValues(alpha: 0.07)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: isUser
                      ? SelectableText(
                          message.text,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        )
                      : _FormattedMessage(text: message.text),
                ),

                // Footer: time + copy
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isUser && !isWelcome)
                      GestureDetector(
                        onTap: () => onCopy(message.text),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.copy_rounded, size: 10, color: Colors.white24),
                              const SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.white24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (timeStr.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        timeStr,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white24,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (isUser)
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(left: 8, bottom: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white38, size: 16),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formatted AI Message (markdown-like rendering)
// ─────────────────────────────────────────────────────────────────────────────

class _FormattedMessage extends StatelessWidget {
  final String text;
  const _FormattedMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Horizontal divider
      if (line == '---' || line == '***' || line == '___') {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: Colors.white12, height: 1),
        ));
        continue;
      }

      // Section Headings: ### Header
      if (line.startsWith('### ')) {
        final title = line.substring(4).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF818CF8),
            ),
          ),
        ));
        continue;
      }

      // Large Headings: # or ## Header
      if (line.startsWith('## ') || line.startsWith('# ')) {
        final title = line.replaceFirst(RegExp(r'^#+\s*'), '').trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ));
        continue;
      }

      // Bullet points (* , - , • )
      if (line.startsWith('* ') || line.startsWith('- ') || line.startsWith('• ')) {
        final content = line.substring(2).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 8),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B5CF6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(child: _RichLine(content)),
            ],
          ),
        ));
        continue;
      }

      // Numbered list: 1. 2. 3.
      final numMatch = RegExp(r'^(\d+)\.\s+(.*)').firstMatch(line);
      if (numMatch != null) {
        final num = numMatch.group(1)!;
        final content = numMatch.group(2)!;
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2, right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  num,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF818CF8),
                  ),
                ),
              ),
              Expanded(child: _RichLine(content)),
            ],
          ),
        ));
        continue;
      }

      // Default text line
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: _RichLine(line),
      ));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}

class _RichLine extends StatelessWidget {
  final String line;
  const _RichLine(this.line);

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(\*\*[^*]+\*\*|`[^`]+`)');
    int last = 0;

    for (final m in regex.allMatches(line)) {
      if (m.start > last) {
        spans.add(TextSpan(
          text: line.substring(last, m.start),
          style: _base,
        ));
      }
      final t = m.group(0)!;
      if (t.startsWith('**')) {
        spans.add(TextSpan(
          text: t.substring(2, t.length - 2),
          style: _base.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
        ));
      } else {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Text(
              t.substring(1, t.length - 1),
              style: GoogleFonts.robotoMono(
                color: const Color(0xFF818CF8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ));
      }
      last = m.end;
    }

    if (last < line.length) {
      spans.add(TextSpan(text: line.substring(last), style: _base));
    }

    return SelectableText.rich(TextSpan(children: spans));
  }

  static final _base = GoogleFonts.poppins(
    color: const Color(0xFFCBD5E1),
    fontSize: 13.5,
    height: 1.55,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Typing Dots
// ─────────────────────────────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final opacity = (phase < 0.5 ? phase * 2 : (1 - phase) * 2).clamp(0.2, 1.0);
            return Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: opacity),
              ),
            );
          }),
        );
      },
    );
  }
}
