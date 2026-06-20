import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

/// Classifies whether a name/phone belongs to a Family or Friends contact.
///
/// Usage:
///   1. Call [ContactClassifier.initialize()] once at app startup
///      (after SMS permission grant, before cashflow classification).
///   2. Call [ContactClassifier.classify(nameOrPhone)] in the cashflow
///      provider to tag P2P transfers as "Friends", "Family", or "Transfer".
class ContactClassifier {
  static final ContactClassifier _instance = ContactClassifier._();
  factory ContactClassifier() => _instance;
  ContactClassifier._();

  bool _loaded = false;

  // name (lowercase) → ContactRelation
  final Map<String, ContactRelation> _nameMap = {};

  // normalized phone (10-digit) → ContactRelation
  final Map<String, ContactRelation> _phoneMap = {};

  // First names only for fuzzy matching
  final Map<String, ContactRelation> _firstNameMap = {};

  // ── Public API ─────────────────────────────────────────────────────────────

  bool get isLoaded => _loaded;

  /// Load contacts from device. Must be called after permission is granted.
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_loaded) return;
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) return;

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withGroups: true,
      );

      for (final contact in contacts) {
        final displayName = contact.displayName.toLowerCase().trim();
        if (displayName.isEmpty) continue;

        // Determine relation from contact groups
        final groups = contact.groups.map((g) => g.name.toLowerCase()).toList();
        final relation = _classifyGroup(groups);

        _nameMap[displayName] = relation;

        // Index first name for fuzzy matching
        final firstName = displayName.split(' ').first;
        if (firstName.length > 2 && !_firstNameMap.containsKey(firstName)) {
          _firstNameMap[firstName] = relation;
        }

        // Index all phone numbers
        for (final phone in contact.phones) {
          final normalized = _normalizePhone(phone.number);
          if (normalized.isNotEmpty) {
            _phoneMap[normalized] = relation;
          }
        }
      }
      _loaded = true;
    } catch (e) {
      debugPrint('[ContactClassifier] init error: $e');
    }
  }

  /// Classify a name or phone number from SMS.
  /// Returns [ContactRelation.unknown] if not found in contacts.
  ContactRelation classify(String nameOrPhone) {
    if (!_loaded) return ContactRelation.unknown;

    final input = nameOrPhone.toLowerCase().trim();

    // Try as phone number
    final phone = _normalizePhone(nameOrPhone);
    if (phone.isNotEmpty && _phoneMap.containsKey(phone)) {
      return _phoneMap[phone]!;
    }

    // Exact name match
    if (_nameMap.containsKey(input)) return _nameMap[input]!;

    // First-name fuzzy match (handles "Rahul" matching "Rahul Sharma")
    final firstName = input.split(' ').first;
    if (firstName.length > 2 && _firstNameMap.containsKey(firstName)) {
      return _firstNameMap[firstName]!;
    }

    // Partial: does any contact name start with this input?
    for (final entry in _nameMap.entries) {
      if (entry.key.startsWith(input) && input.length >= 4) {
        return entry.value;
      }
    }

    return ContactRelation.unknown;
  }

  /// Whether the given name/phone is in the device contacts at all.
  bool isKnownContact(String nameOrPhone) =>
      classify(nameOrPhone) != ContactRelation.unknown;

  // ── Internals ──────────────────────────────────────────────────────────────

  ContactRelation _classifyGroup(List<String> groups) {
    const familyWords = [
      'family', 'relatives', 'parents', 'siblings', 'spouse',
      'परिवार', 'पारिवारिक',  // Hindi family labels
    ];
    const friendWords = [
      'friends', 'college', 'school', 'work', 'colleagues',
      'office', 'gym', 'club',
    ];

    for (final g in groups) {
      if (familyWords.any((w) => g.contains(w))) return ContactRelation.family;
      if (friendWords.any((w) => g.contains(w))) return ContactRelation.friends;
    }
    // In contacts but no group label → default to friends
    return ContactRelation.friends;
  }

  String _normalizePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    // Strip country code +91
    if (digits.startsWith('91') && digits.length == 12) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    return digits.length == 10 ? digits : '';
  }
}

enum ContactRelation {
  family,
  friends,
  unknown,
}
