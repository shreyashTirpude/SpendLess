import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/llm_service.dart';
import 'transaction_provider.dart';

// Re-export ChatMessage so screens only import this file
export '../../services/llm_service.dart' show ChatMessage;

// ─── LlmService provider ──────────────────────────────────────────────────────

final llmServiceProvider = Provider<LlmService>((ref) => LlmService());

// ─── Chat state notifier ──────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final LlmService _llmService;

  ChatNotifier(this._llmService) : super([]) {
    state = [
      ChatMessage(
        content: _welcomeMessage(),
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }

  String _welcomeMessage() =>
      'Hi! I\'m your AI Money Coach. I can see your spending this month. '
      'Ask me anything — "Why did I overspend?", "How can I save more?", '
      '"What\'s my biggest expense?"';

  Future<void> sendMessage(
    String text,
    Map<String, double> categoryTotals,
    double totalSpent,
    double totalIncome,
  ) async {
    if (text.trim().isEmpty) return;

    // Find top category
    String topCategory = 'General';
    double topAmount = 0;
    for (final entry in categoryTotals.entries) {
      if (entry.value > topAmount) {
        topAmount = entry.value;
        topCategory = entry.key;
      }
    }

    final systemPrompt = _llmService.buildSystemPrompt(
      totalSpent: totalSpent,
      totalIncome: totalIncome,
      categoryTotals: categoryTotals,
      topCategory: topCategory,
      transactionCount: categoryTotals.length,
      savings: totalIncome - totalSpent,
    );

    // Add user message
    final userMsg = ChatMessage(
      content: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = [...state, userMsg];

    // Get response — history excludes the welcome message for cleaner context
    final historyForLlm = state
        .skip(1) // skip welcome
        .where((m) => !m.isUser || m != userMsg) // exclude current msg (sent separately)
        .toList();

    final response = await _llmService.chat(
      userMessage: text.trim(),
      history: historyForLlm,
      systemPrompt: systemPrompt,
      categoryTotals: categoryTotals,
      totalSpent: totalSpent,
    );

    final aiMsg = ChatMessage(
      content: response,
      isUser: false,
      timestamp: DateTime.now(),
    );
    state = [...state, aiMsg];
  }

  void clear() {
    state = [
      ChatMessage(
        content: _welcomeMessage(),
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  final llm = ref.watch(llmServiceProvider);
  return ChatNotifier(llm);
});

// ─── Typing indicator provider ────────────────────────────────────────────────

final chatIsTypingProvider = StateProvider<bool>((ref) => false);

// ─── Convenience: category totals + spend for chat context ───────────────────

final chatContextProvider = FutureProvider<({
  Map<String, double> categoryTotals,
  double totalSpent,
  double totalIncome,
})>((ref) async {
  final stats = await ref.watch(homeStatsProvider.future);
  return (
    categoryTotals: stats.categoryTotals,
    totalSpent: stats.totalSpent,
    totalIncome: stats.totalIncome,
  );
});
