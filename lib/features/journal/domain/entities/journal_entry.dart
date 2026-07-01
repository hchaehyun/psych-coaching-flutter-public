class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.userId,
    required this.content,
    required this.imagePaths,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String userId;
  final String content;
  final List<String> imagePaths;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
