/// Utility functions for working with tags in notes
library;

/// Extracts hashtags from the given content
///
/// Returns a list of hashtags (including the # symbol)
List<String> extractTags(String content) {
  // Use RegExp to find all hashtags in the content
  // Match hashtags that start with # and are followed by letters, numbers, underscores, or hyphens
  final regex = RegExp(r'#([a-zA-Z0-9_-]+)');
  final matches = regex.allMatches(content);

  // Extract the tag names with the # symbol and return as a list of unique tags
  return matches.map((match) => '#${match.group(1)}').toSet().toList();
}
