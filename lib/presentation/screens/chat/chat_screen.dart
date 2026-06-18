import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/subscription_tier.dart';
import '../../providers/chat_provider.dart';
import '../../providers/subscription_provider.dart';

// ─── Paywall ──────────────────────────────────────────────────────────────────

/// Inline paywall shown to free/plus users when trying to access Pro features.
class _ProPaywallScreen extends StatelessWidget {
  final String featureName;
  const _ProPaywallScreen({required this.featureName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: context.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientMid],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                'Pro Feature',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                '$featureName is available on the Pro plan.\nUpgrade to unlock AI-powered financial coaching and personalised savings opportunities.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: context.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientMid,
                          AppColors.gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      context.push('/paywall');
                    },
                    child: const Text(
                      'Upgrade to Pro',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text('Maybe later',
                    style: TextStyle(color: context.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tier check ───────────────────────────────────────────────────────────────

/// Returns true if the user has Pro tier access.
// Tier check is done inside build() via ref.watch — see ChatScreen.build()

// ─── Chat screen ──────────────────────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;

  static const _suggestedQuestions = [
    'Why did I overspend?',
    'How much can I save?',
    'What\'s my biggest expense?',
    'Predict next month spend',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping) return;
    _controller.clear();
    setState(() => _isTyping = true);

    Map<String, double> categoryTotals = {};
    double totalSpent = 0;
    double totalIncome = 0;

    try {
      final ctx = await ref.read(chatContextProvider.future);
      categoryTotals = ctx.categoryTotals;
      totalSpent = ctx.totalSpent;
      totalIncome = ctx.totalIncome;
    } catch (_) {
      // proceed with zero context — template fallback handles it
    }

    _scrollToBottom();

    await ref.read(chatProvider.notifier).sendMessage(
          text,
          categoryTotals,
          totalSpent,
          totalIncome,
        );

    if (mounted) setState(() => _isTyping = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isProUser = ref.watch(isFeatureAvailableProvider('chatbot'));
    if (!isProUser) {
      return const _ProPaywallScreen(featureName: 'AI Money Coach');
    }

    final messages = ref.watch(chatProvider);

    // Auto-scroll when messages update
    ref.listen(chatProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(context, messages),
          ),
          _buildInputRow(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.surfaceColor,
      elevation: 0,
      leading: BackButton(color: context.textPrimary),
      titleSpacing: 0,
      title: Row(
        children: [
          Text(
            'Money Coach',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientMid],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'AI',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: context.textSecondary),
          tooltip: 'Clear chat',
          onPressed: () {
            ref.read(chatProvider.notifier).clear();
            setState(() => _isTyping = false);
          },
        ),
      ],
    );
  }

  Widget _buildMessageList(BuildContext context, List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator at end
        if (_isTyping && index == messages.length) {
          return _TypingIndicator();
        }

        final msg = messages[index];

        // Show suggested questions below the first (welcome) message
        if (index == 0 && messages.length == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChatBubble(message: msg),
              const SizedBox(height: 12),
              _buildSuggestedQuestions(context),
              const SizedBox(height: 4),
            ],
          );
        }

        return _ChatBubble(message: msg);
      },
    );
  }

  Widget _buildSuggestedQuestions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _suggestedQuestions.map((q) {
        return GestureDetector(
          onTap: () => _sendMessage(q),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3), width: 1),
            ),
            child: Text(
              q,
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInputRow(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          top: BorderSide(color: context.cardBorderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.cardBorderColor),
              ),
              child: TextField(
                controller: _controller,
                style: TextStyle(color: context.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Ask your money coach...',
                  hintStyle: TextStyle(color: context.textMuted, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chat bubble ──────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final timeStr = DateFormat('h:mm a').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Text(
                '🤖 AI Coach',
                style: TextStyle(
                  fontSize: 11,
                  color: context.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) const SizedBox(width: 4),
              Flexible(
                child: isUser
                    ? _UserBubble(text: message.content)
                    : _AiBubble(context: context, text: message.content),
              ),
              if (isUser) const SizedBox(width: 4),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(
                left: isUser ? 0 : 8, right: isUser ? 8 : 0),
            child: Text(
              timeStr,
              style: TextStyle(fontSize: 10, color: context.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 14, height: 1.4),
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final String text;
  final BuildContext context;
  const _AiBubble({required this.text, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(ctx).size.width * 0.78),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ctx.cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(color: ctx.cardBorderColor),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: ctx.textPrimary, fontSize: 14, height: 1.5),
      ),
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 3; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true, period: Duration(milliseconds: 600 + i * 150));
      _controllers.add(ctrl);
      _animations.add(Tween<double>(begin: 0, end: 6).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
      ));
    }
    // Stagger start
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🤖 ', style: TextStyle(fontSize: 12, color: context.textMuted)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: context.cardBorderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _animations[i],
                  builder: (context, _) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 7,
                    height: 7,
                    transform: Matrix4.translationValues(
                        0, -_animations[i].value, 0),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
