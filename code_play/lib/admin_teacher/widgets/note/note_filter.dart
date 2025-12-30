
/// Filters a list of note data based on the selected topic and search query.
List<Map<String, dynamic>> filterNotes({
  required List<Map<String, dynamic>> notes,
  required String selectedTopic,
  String? searchQuery,
}) {
  return notes.where((note) {
    // 1. Filter by Topic
    // We assume the note data contains a 'topic' key.
    // If 'All' is selected (optional), we return everything, 
    // otherwise we check for an exact match.
    final noteTopic = note['topic'] as String? ?? '';
    final bool matchesTopic = noteTopic.toLowerCase() == selectedTopic.toLowerCase();

    // 2. Filter by Search Query (if provided)
    final String title = note['title'] as String? ?? '';
    final bool matchesSearch = searchQuery == null ||
        searchQuery.isEmpty ||
        title.toLowerCase().contains(searchQuery.toLowerCase());

    return matchesTopic && matchesSearch;
  }).toList();
}
