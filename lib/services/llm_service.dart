import 'dart:convert';
import 'dart:io';

// ─── ChatMessage model ────────────────────────────────────────────────────────

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

// ─── LlmService ───────────────────────────────────────────────────────────────

class LlmService {
  static const _ollamaHost = 'localhost';
  static const _ollamaPort = 11434;
  static const _ollamaPath = '/api/chat';

  // Preferred models in priority order
  static const _models = ['llama3.2:1b', 'phi3:mini'];

  // ── System prompt builder ──────────────────────────────────────────────────

  String buildSystemPrompt({
    required double totalSpent,
    required double totalIncome,
    required Map<String, double> categoryTotals,
    required String topCategory,
    required int transactionCount,
    double savings = 0,
  }) {
    final savingsValue = savings != 0 ? savings : totalIncome - totalSpent;
    final categoryBreakdown = categoryTotals.entries
        .map((e) => '  • ${e.key}: ₹${e.value.toStringAsFixed(0)}')
        .join('\n');

    return '''You are an AI Money Coach embedded in SpendLens, a personal finance app.
You have access to the user's real spending data for this month.

CURRENT MONTH STATS:
- Total spent: ₹${totalSpent.toStringAsFixed(0)}
- Total income: ₹${totalIncome.toStringAsFixed(0)}
- Savings so far: ₹${savingsValue.toStringAsFixed(0)}
- Transactions: $transactionCount
- Top spending category: $topCategory

CATEGORY BREAKDOWN:
$categoryBreakdown

INSTRUCTIONS:
- Be concise, friendly, and specific to their actual numbers
- Always use ₹ for amounts (Indian Rupees)
- Give actionable advice, not generic tips
- Keep responses under 100 words unless explaining something complex
- If you don't know something, be honest about it
- You are NOT a financial advisor — always add that caveat for investment advice''';
  }

  // ── Main chat method ───────────────────────────────────────────────────────

  Future<String> chat({
    required String userMessage,
    required List<ChatMessage> history,
    required String systemPrompt,
    Map<String, double> categoryTotals = const {},
    double totalSpent = 0,
  }) async {
    // Try Ollama first
    try {
      final result = await _callOllama(
        userMessage: userMessage,
        history: history,
        systemPrompt: systemPrompt,
      );
      if (result != null) return result;
    } catch (_) {
      // Ollama unavailable — fall through to templates
    }

    // Template fallback
    return _templateResponse(userMessage, categoryTotals, totalSpent);
  }

  // ── Ollama HTTP call ───────────────────────────────────────────────────────

  Future<String?> _callOllama({
    required String userMessage,
    required List<ChatMessage> history,
    required String systemPrompt,
  }) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 3);

      final messages = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
        for (final msg in history)
          {'role': msg.isUser ? 'user' : 'assistant', 'content': msg.content},
        {'role': 'user', 'content': userMessage},
      ];

      // Try each model until one works
      for (final model in _models) {
        final body = jsonEncode({
          'model': model,
          'messages': messages,
          'stream': false,
          'options': {'temperature': 0.7, 'num_predict': 200},
        });

        final request = await client.post(_ollamaHost, _ollamaPort, _ollamaPath);
        request.headers.contentType = ContentType.json;
        request.write(body);

        final response = await request.close().timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final responseBody = await response.transform(utf8.decoder).join();
          final json = jsonDecode(responseBody) as Map<String, dynamic>;
          final content = (json['message'] as Map<String, dynamic>?)?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            return content.trim();
          }
        }
      }
      return null;
    } on SocketException {
      return null;
    } on HttpException {
      return null;
    } catch (_) {
      return null;
    } finally {
      client?.close();
    }
  }

  // ── Template-based fallback ────────────────────────────────────────────────

  String _templateResponse(
    String userMessage,
    Map<String, double> categoryTotals,
    double totalSpent,
  ) {
    final lower = userMessage.toLowerCase();

    // Find top category
    String topCat = 'General';
    double topAmount = 0;
    for (final entry in categoryTotals.entries) {
      if (entry.value > topAmount) {
        topAmount = entry.value;
        topCat = entry.key;
      }
    }

    final foodTotal = _sumCategories(categoryTotals, ['food', 'dining', 'restaurant', 'swiggy', 'zomato']);
    final totalTxns = categoryTotals.length;

    // Overspend / biggest expense pattern
    if (_matches(lower, ['overspend', 'biggest expense', 'most spent', 'where did my money go'])) {
      return 'Your biggest expense category is $topCat at ₹${topAmount.toStringAsFixed(0)} this month. '
          'That\'s ${totalSpent > 0 ? ((topAmount / totalSpent) * 100).toStringAsFixed(0) : 0}% of your total spend. '
          'Try setting a budget limit for $topCat to stay on track.';
    }

    // Savings / how much to save
    if (_matches(lower, ['save', 'saving', 'savings', 'how much can'])) {
      final twentyPct = totalSpent * 0.20;
      return 'Based on the 50/30/20 rule, you should aim to save 20% of your income. '
          'Right now you\'re spending ₹${totalSpent.toStringAsFixed(0)}. '
          'Cutting discretionary spend by ₹${twentyPct.toStringAsFixed(0)}/month could boost your savings significantly.';
    }

    // Food / delivery / Swiggy / Zomato
    if (_matches(lower, ['swiggy', 'zomato', 'food', 'delivery', 'eating'])) {
      if (foodTotal > 0) {
        final daily = foodTotal / 30;
        return 'You\'ve spent ₹${foodTotal.toStringAsFixed(0)} on food this month — about ₹${daily.toStringAsFixed(0)}/day. '
            'Cooking at home 2–3 days a week could save you ₹${(foodTotal * 0.3).toStringAsFixed(0)}/month.';
      }
      return 'I don\'t see significant food delivery spending this month. Keep it up!';
    }

    // Budget
    if (_matches(lower, ['budget', 'limit', 'over budget'])) {
      if (topAmount > totalSpent * 0.40) {
        return '$topCat is eating up ${((topAmount / totalSpent) * 100).toStringAsFixed(0)}% of your budget. '
            'Consider setting a monthly cap of ₹${(topAmount * 0.80).toStringAsFixed(0)} for $topCat — a 20% reduction.';
      }
      return 'Your spending looks reasonably distributed across $totalTxns categories. '
          'Set category budgets in the Budget tab to stay on track each month.';
    }

    // Prediction / next month
    if (_matches(lower, ['predict', 'next month', 'forecast', 'estimate'])) {
      final projected = totalSpent * 1.05; // slight inflation buffer
      return 'Based on your current pace, you\'ll likely spend about ₹${projected.toStringAsFixed(0)} next month '
          '(assuming similar habits). Your top category $topCat will continue to be the biggest driver.';
    }

    // Subscription / cancel
    if (_matches(lower, ['subscription', 'cancel', 'recurring', 'ott', 'netflix', 'spotify'])) {
      return 'Check the Subscriptions tab for a full list of your recurring charges. '
          'Cancelling unused subscriptions is one of the fastest ways to free up money each month.';
    }

    // Generic helpful response
    return 'Based on ₹${totalSpent.toStringAsFixed(0)} spent this month across $totalTxns categories, '
        'your top spend is $topCat at ₹${topAmount.toStringAsFixed(0)}. '
        'Try asking me: "Why did I overspend?", "How much can I save?", or "Predict next month spend".';
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool _matches(String lower, List<String> keywords) =>
      keywords.any((k) => lower.contains(k));

  double _sumCategories(Map<String, double> totals, List<String> keywords) {
    double sum = 0;
    for (final entry in totals.entries) {
      if (keywords.any((k) => entry.key.toLowerCase().contains(k))) {
        sum += entry.value;
      }
    }
    return sum;
  }
}
