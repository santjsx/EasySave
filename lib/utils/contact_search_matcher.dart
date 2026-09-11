import 'dart:math' as math;
import '../models/contact_model.dart';

/// Represents categorized and ranked search results.
class SearchMatchResult {
  /// Direct, exact, prefix, token, and phone substring matches.
  final List<ContactModel> exactMatches;

  /// Fuzzy, phonetic, or typo-tolerant similar matches.
  final List<ContactModel> similarMatches;

  const SearchMatchResult({
    this.exactMatches = const [],
    this.similarMatches = const [],
  });

  bool get isEmpty => exactMatches.isEmpty && similarMatches.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

/// Intelligent search and ranking engine for contacts with Telugu and phone support.
class ContactSearchMatcher {
  /// Evaluates a list of contacts against a search query.
  static SearchMatchResult evaluate(List<ContactModel> contacts, String query) {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return SearchMatchResult(
        exactMatches: List.unmodifiable(contacts),
        similarMatches: const [],
      );
    }

    final queryLower = cleanQuery.toLowerCase();
    final queryDigits = cleanQuery.replaceAll(RegExp(r'\D'), '');

    final List<ContactModel> tier1Exact = [];
    final List<ContactModel> tier2PrefixOrToken = [];
    final List<ContactModel> tier3Contains = [];
    final List<ContactModel> tier4Similar = [];
    final Set<String> matchedIds = {};

    // Generate transliteration equivalent if query contains Latin characters
    final String? teluguTranslit = _transliterateLatinToTelugu(queryLower);

    for (final contact in contacts) {
      final nameLower = contact.name.trim().toLowerCase();
      final phoneDigits = contact.phone.replaceAll(RegExp(r'\D'), '');

      // 1. Phone number matching
      if (queryDigits.isNotEmpty) {
        if (phoneDigits == queryDigits ||
            (phoneDigits.length >= 10 &&
                phoneDigits.endsWith(queryDigits) &&
                queryDigits.length >= 4)) {
          tier1Exact.add(contact);
          matchedIds.add(contact.id);
          continue;
        } else if (phoneDigits.contains(queryDigits) && queryDigits.length >= 3) {
          tier3Contains.add(contact);
          matchedIds.add(contact.id);
          continue;
        }
      }

      // 2. Exact match on name
      if (nameLower == queryLower ||
          (teluguTranslit != null && nameLower == teluguTranslit)) {
        tier1Exact.add(contact);
        matchedIds.add(contact.id);
        continue;
      }

      // 3. Prefix match on full name
      if (nameLower.startsWith(queryLower) ||
          (teluguTranslit != null && nameLower.startsWith(teluguTranslit))) {
        tier2PrefixOrToken.add(contact);
        matchedIds.add(contact.id);
        continue;
      }

      // 4. Token / Word prefix match (e.g., "రమేష్ రావు" matches "రావు")
      final tokens = nameLower.split(RegExp(r'[\s,._-]+'));
      bool tokenMatched = false;
      for (final token in tokens) {
        if (token.startsWith(queryLower) ||
            (teluguTranslit != null && token.startsWith(teluguTranslit))) {
          tier2PrefixOrToken.add(contact);
          matchedIds.add(contact.id);
          tokenMatched = true;
          break;
        }
      }
      if (tokenMatched) continue;

      // 5. Contains substring match
      if (nameLower.contains(queryLower) ||
          (teluguTranslit != null && nameLower.contains(teluguTranslit))) {
        tier3Contains.add(contact);
        matchedIds.add(contact.id);
        continue;
      }
    }

    // Combine exact, prefix, and contains into primary list
    final List<ContactModel> primaryMatches = [
      ...tier1Exact,
      ...tier2PrefixOrToken,
      ...tier3Contains,
    ];

    // 6. Fuzzy / Similar Contact Discovery (only evaluate unmatched contacts)
    for (final contact in contacts) {
      if (matchedIds.contains(contact.id)) continue;

      final nameLower = contact.name.trim().toLowerCase();
      if (_isSimilar(nameLower, queryLower, teluguTranslit)) {
        tier4Similar.add(contact);
      }
    }

    return SearchMatchResult(
      exactMatches: List.unmodifiable(primaryMatches),
      similarMatches: List.unmodifiable(tier4Similar),
    );
  }

  /// Determines if [target] is phonetically or orthographically similar to [query].
  static bool _isSimilar(String target, String query, String? teluguTranslit) {
    if (query.isEmpty || target.isEmpty) return false;

    // Check Levenshtein distance on full name
    final dist = levenshtein(target, query);
    final maxAllowedDist = query.length <= 4 ? 1 : 2;
    if (dist <= maxAllowedDist) return true;

    // Check Levenshtein with transliterated query if available
    if (teluguTranslit != null) {
      final translitDist = levenshtein(target, teluguTranslit);
      if (translitDist <= maxAllowedDist) return true;
    }

    // Check token-level distance (e.g. searching "రాము" matches token "రాముడు")
    final tokens = target.split(RegExp(r'[\s,._-]+'));
    for (final token in tokens) {
      final tokenDist = levenshtein(token, query);
      if (tokenDist <= maxAllowedDist) return true;

      if (teluguTranslit != null) {
        final tokenTranslitDist = levenshtein(token, teluguTranslit);
        if (tokenTranslitDist <= maxAllowedDist) return true;
      }

      // Check common Telugu suffix extensions (e.g., "రాము" -> "రాముడు", "రమేష్" -> "రమేష్ గారు")
      if (token.startsWith(query) || (token.length >= 3 && query.startsWith(token.substring(0, 3)))) {
        return true;
      }
    }

    // Check normalized consonant overlap (e.g. interchangeable "శ", "ష", "స")
    final normTarget = _normalizeTeluguConsonants(target);
    final normQuery = _normalizeTeluguConsonants(query);
    if (normTarget.contains(normQuery) || normQuery.contains(normTarget)) {
      return true;
    }

    return false;
  }

  /// Calculates classic Levenshtein distance between two strings.
  static int levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s.codeUnitAt(i) == t.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = math.min(
          v1[j] + 1, // insertion
          math.min(v0[j + 1] + 1, v0[j] + cost), // deletion & substitution
        );
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[t.length];
  }

  /// Normalizes commonly confused Telugu characters for phonetic comparison.
  static String _normalizeTeluguConsonants(String input) {
    return input
        .replaceAll('శ', 'స')
        .replaceAll('ష', 'స')
        .replaceAll('ణ', 'న')
        .replaceAll('ఱ', 'ర')
        .replaceAll('ళ', 'ల');
  }

  /// Transliterates common English names/relationships to Telugu script equivalents.
  static String? _transliterateLatinToTelugu(String latin) {
    final clean = latin.trim().toLowerCase();
    if (clean.isEmpty) return null;

    const Map<String, String> commonWords = {
      'amma': 'అమ్మ',
      'nanna': 'నాన్న',
      'anna': 'అన్న',
      'akka': 'అక్క',
      'chelli': 'చెల్లి',
      'thammudu': 'తమ్ముడు',
      'ramesh': 'రమేష్',
      'suresh': 'సురేష్',
      'mahesh': 'మహేష్',
      'anil': 'అనిల్',
      'sunil': 'సునీల్',
      'santosh': 'సంతోష్',
      'ramu': 'రాము',
      'raju': 'రాజు',
      'ravi': 'రవి',
      'kumar': 'కుమార్',
      'reddy': 'రెడ్డి',
      'rao': 'రావు',
    };

    if (commonWords.containsKey(clean)) {
      return commonWords[clean];
    }

    for (final entry in commonWords.entries) {
      if (clean.startsWith(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }
}
