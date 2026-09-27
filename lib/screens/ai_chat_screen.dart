import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/gemini_service.dart';
import '../providers/scam_provider.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final List<GeminiChatMessage> _history = [];
  bool _isLoading = false;

  static const List<_QuickPrompt> _quickPrompts = [
    _QuickPrompt(
      title: 'Fake Telebirr SMS',
      subtitle: 'How to verify real vs fake transfer',
      icon: Icons.account_balance_wallet_outlined,
      prompt: 'How do I tell if a Telebirr transfer SMS is genuine or fake?',
    ),
    _QuickPrompt(
      title: 'CBE Account Credit',
      subtitle: 'Check bank transaction alerts',
      icon: Icons.account_balance_outlined,
      prompt: 'How do I safely verify a Commercial Bank of Ethiopia (CBE) credited alert?',
    ),
    _QuickPrompt(
      title: 'Shared My OTP',
      subtitle: 'Immediate containment steps',
      icon: Icons.security_outlined,
      prompt: 'I accidentally gave my SMS verification OTP to someone. What exact steps should I take right now?',
    ),
    _QuickPrompt(
      title: 'የቴሌብር ማጭበርበር',
      subtitle: 'በአማርኛ ማብራሪያ',
      icon: Icons.language_outlined,
      prompt: 'የቴሌብር የገንዘብ ማጭበርበር SMS መልዕክቶችን እንዴት መለየት እችላለሁ?',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      isUser: false,
      text:
          'Welcome to Meketa AI Security Assistant.\n\nI provide concise, verified guidance on Ethiopian digital scams, fake bank transfers (Telebirr, CBE, BoA), and suspicious messages. Ask any question in English or Amharic.',
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final msg = text.trim();
    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(
        isUser: true,
        text: msg,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _scrollToBottom();

    final reply = await GeminiService.chatWithAssistant(_history, msg);
    if (!mounted) return;

    _history.add(GeminiChatMessage(role: 'user', text: msg));
    _history.add(GeminiChatMessage(role: 'model', text: reply));

    setState(() {
      _messages.add(_ChatMessage(
        isUser: false,
        text: reply,
        timestamp: DateTime.now(),
      ));
      _isLoading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<ScamProvider>().currentLanguage;
    const bgPrimary = Color(0xFF090D16);
    const bgCard = Color(0xFF131B2E);
    const borderColor = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Security Assistant',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Gemini 3.5 Active • Concise Mode',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_messages.length > 1)
            IconButton(
              tooltip: 'Clear conversation',
              icon: const Icon(Icons.cleaning_services_outlined, color: Color(0xFF94A3B8), size: 20),
              onPressed: () {
                setState(() {
                  _history.clear();
                  _messages.clear();
                  _messages.add(_ChatMessage(
                    isUser: false,
                    text: 'Conversation cleared. How can I assist you with Ethiopian digital security?',
                    timestamp: DateTime.now(),
                  ));
                });
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: borderColor,
          ),
        ),
      ),
      body: Column(
        children: [
          // Security disclaimer notice
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF0F172A),
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined, color: Color(0xFF38BDF8), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Advisory only. Always verify bank accounts via official USSD (*889#, *127#).',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageItem(msg);
              },
            ),
          ),

          // Typing indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _DotPulse(),
                        const SizedBox(width: 4),
                        const _DotPulse(delay: 200),
                        const SizedBox(width: 4),
                        const _DotPulse(delay: 400),
                        const SizedBox(width: 10),
                        Text(
                          'Analyzing...',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Quick prompt cards (visible on initial screen)
          if (_messages.length <= 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COMMON SECURITY QUERIES',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.3,
                    children: _quickPrompts.map((qp) {
                      return InkWell(
                        onTap: () => _sendMessage(qp.prompt),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(qp.icon, color: const Color(0xFF60A5FA), size: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      qp.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      qp.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Input control container
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            decoration: const BoxDecoration(
              color: bgPrimary,
              border: Border(
                top: BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF131B2E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF64748B), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: lang == 'Amharic'
                                  ? 'ጥያቄዎን እዚህ ይጻፉ...'
                                  : 'Ask security question or paste text...',
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            maxLines: 4,
                            minLines: 1,
                            onSubmitted: _sendMessage,
                          ),
                        ),
                        if (_controller.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Color(0xFF64748B), size: 18),
                            onPressed: () => setState(() => _controller.clear()),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isLoading ? null : () => _sendMessage(_controller.text),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: _isLoading
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: _isLoading ? const Color(0xFF334155) : null,
                      shape: BoxShape.circle,
                      boxShadow: _isLoading
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Icon(
                      _isLoading ? Icons.hourglass_top_rounded : Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(_ChatMessage msg) {
    final isUser = msg.isUser;
    final timeStr =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Header (Avatar + Name + Time)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isUser) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.shield_outlined, size: 12, color: Color(0xFF60A5FA)),
                ),
                const SizedBox(width: 6),
                Text(
                  'Meketa AI',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                timeStr,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF64748B),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64748B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.person_outline, size: 12, color: Color(0xFFCBD5E1)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // Message Card
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.78 : 0.88),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isUser
                  ? const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isUser ? null : const Color(0xFF131B2E),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: isUser ? null : Border.all(color: const Color(0xFF1E293B)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FormattedAiMessage(text: msg.text, isUser: isUser),
                if (!isUser) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: msg.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Response copied to clipboard'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFF1E293B),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.copy_rounded, size: 11, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormattedAiMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const _FormattedAiMessage({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return SelectableText(
        text,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 13.5,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
      );
    }

    final rawLines = text.split('\n');
    final List<Widget> children = [];

    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i].trim();
      if (line.isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }

      // Bullet points: * or - or •
      if (line.startsWith('* ') || line.startsWith('- ') || line.startsWith('• ')) {
        final content = line.substring(2).trim();
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF38BDF8),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: _buildRichLine(content),
                ),
              ],
            ),
          ),
        );
      }
      // Numbered items: 1. 2. 3.
      else if (RegExp(r'^\d+\.\s+').hasMatch(line)) {
        final match = RegExp(r'^(\d+)\.\s+(.*)').firstMatch(line);
        final numStr = match?.group(1) ?? '1';
        final content = match?.group(2) ?? line;

        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2, right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    numStr,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF60A5FA),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildRichLine(content),
                ),
              ],
            ),
          ),
        );
      }
      // Standard line
      else {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _buildRichLine(line),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildRichLine(String line) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(\*\*[^*]+\*\*|`[^`]+`)');
    int lastIndex = 0;

    for (final match in regex.allMatches(line)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: line.substring(lastIndex, match.start),
          style: GoogleFonts.inter(
            color: const Color(0xFFE2E8F0),
            fontSize: 13.5,
            height: 1.5,
          ),
        ));
      }

      final matchedText = match.group(0)!;
      if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            height: 1.5,
          ),
        ));
      } else if (matchedText.startsWith('`') && matchedText.endsWith('`')) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Text(
              matchedText.substring(1, matchedText.length - 1),
              style: GoogleFonts.robotoMono(
                color: const Color(0xFF38BDF8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < line.length) {
      spans.add(TextSpan(
        text: line.substring(lastIndex),
        style: GoogleFonts.inter(
          color: const Color(0xFFE2E8F0),
          fontSize: 13.5,
          height: 1.5,
        ),
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }
}

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
  final String title;
  final String subtitle;
  final IconData icon;
  final String prompt;

  const _QuickPrompt({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.prompt,
  });
}

class _DotPulse extends StatefulWidget {
  final int delay;
  const _DotPulse({this.delay = 0});

  @override
  State<_DotPulse> createState() => _DotPulseState();
}

class _DotPulseState extends State<_DotPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF38BDF8),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
