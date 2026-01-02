/// Fuzzy search utility for matching text with typos and partial matches
class FuzzySearch {
  /// Calculate Levenshtein distance between two strings
  /// Returns the minimum number of single-character edits needed to transform one string into another
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final len1 = s1.length;
    final len2 = s2.length;

    // Create a 2D array to store distances
    final matrix = List.generate(
      len1 + 1,
      (i) => List.filled(len2 + 1, 0),
    );

    // Initialize first row and column
    for (var i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    // Calculate distances
    for (var i = 1; i <= len1; i++) {
      for (var j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[len1][len2];
  }

  /// Calculate similarity score between 0 and 1
  /// Higher score means more similar
  static double similarityScore(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = levenshteinDistance(s1.toLowerCase(), s2.toLowerCase());
    final maxLen = s1.length > s2.length ? s1.length : s2.length;

    return 1.0 - (distance / maxLen);
  }

  /// Check if query fuzzy matches text with a given threshold (0-1)
  /// Returns true if similarity is above threshold
  static bool fuzzyMatch(String text, String query, {double threshold = 0.6}) {
    if (query.isEmpty) return true;
    if (text.isEmpty) return false;

    final textLower = text.toLowerCase();
    final queryLower = query.toLowerCase();

    // Exact substring match gets highest score
    if (textLower.contains(queryLower)) return true;

    // Check if query words are all present (in any order)
    final queryWords = queryLower.split(' ').where((w) => w.isNotEmpty);
    final allWordsPresent = queryWords.every(
      (word) => textLower.contains(word),
    );
    if (allWordsPresent) return true;

    // Use Levenshtein distance for fuzzy matching
    final score = similarityScore(textLower, queryLower);
    return score >= threshold;
  }

  /// Search a list of items and return matches with scores
  /// T is the type of items, getText extracts searchable text from each item
  static List<ScoredMatch<T>> search<T>({
    required List<T> items,
    required String query,
    required String Function(T) getText,
    double threshold = 0.3,
    int maxResults = 50,
  }) {
    if (query.trim().isEmpty) {
      return items
          .take(maxResults)
          .map((item) => ScoredMatch(item: item, score: 1.0))
          .toList();
    }

    final queryLower = query.toLowerCase().trim();
    final results = <ScoredMatch<T>>[];

    for (final item in items) {
      final text = getText(item);
      final textLower = text.toLowerCase();

      double score = 0.0;

      // Exact match gets highest score
      if (textLower == queryLower) {
        score = 1.0;
      }
      // Starts with query gets very high score
      else if (textLower.startsWith(queryLower)) {
        score = 0.9;
      }
      // Contains query as substring
      else if (textLower.contains(queryLower)) {
        score = 0.8;
      }
      // Check if all query words are present
      else {
        final queryWords = queryLower.split(' ').where((w) => w.isNotEmpty);
        final matchedWords = queryWords.where(
          (word) => textLower.contains(word),
        ).length;

        if (matchedWords > 0) {
          score = 0.5 + (matchedWords / queryWords.length) * 0.3;
        } else {
          // Use Levenshtein distance for fuzzy matching
          score = similarityScore(textLower, queryLower);
        }
      }

      if (score >= threshold) {
        results.add(ScoredMatch(item: item, score: score));
      }
    }

    // Sort by score (highest first)
    results.sort((a, b) => b.score.compareTo(a.score));

    return results.take(maxResults).toList();
  }
}

/// A search match with a relevance score
class ScoredMatch<T> {
  final T item;
  final double score;

  ScoredMatch({required this.item, required this.score});
}
