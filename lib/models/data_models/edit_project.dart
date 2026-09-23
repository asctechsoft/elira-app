class EditProject {
  final String id;
  final String name;
  final String imagePath;
  final DateTime updatedAt;

  const EditProject({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.updatedAt,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inHours < 24) return 'Edited ${diff.inHours} hours ago';
    return 'Edited ${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }
}
