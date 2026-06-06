class DataManifest {
  static const List<String> onDeviceOnly = [
    'Raw SMS message text — read once, parsed, immediately discarded',
    'SHA-256 hash of SMS (for deduplication only)',
    'All transaction amounts, merchants, categories',
    'Budget limits and progress',
    'Biometric authentication data',
    'App usage preferences',
    'Dismissed partner suggestions',
    'Partner click count (local analytics only)',
  ];

  static const List<String> cloudSynced = [
    'User phone number or email (login only)',
    'Parsed transaction: amount, merchant, category, date',
    'Budget settings per category',
    'Profile name (optional)',
    'Email notification preferences',
  ];

  static const List<String> neverCollected = [
    'Raw SMS text — ever',
    'Bank account numbers or passwords',
    'UPI PIN or any authentication credentials',
    'Device location',
    'Contact list',
    'Browsing history',
    'Any data sold to third parties',
    'Any data shared with advertisers',
    'Spending patterns sent to ad networks',
  ];

  static const String suggestionExplanation =
    'Suggestions are matched to your spending categories entirely on your '
    'device. The matching logic runs in your phone memory. No spending '
    'data is transmitted to any partner or ad network. When you tap a '
    'suggestion, only a standard web link is opened.';
}
