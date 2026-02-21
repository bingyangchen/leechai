class Category {
  const Category({
    required this.id,
    required this.name,
    this.icon,
    this.parentId,
  });

  final String id;
  final String name;
  final String? icon;
  final String? parentId;
}
