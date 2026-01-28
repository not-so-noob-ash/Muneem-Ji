class Group {
  final int id;
  final String name;
  final int createdById;

  Group({
    required this.id,
    required this.name,
    required this.createdById,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      createdById: json['created_by_id'] ?? json['created_by_user_id'] ?? 0, // Handle variations
    );
  }
}