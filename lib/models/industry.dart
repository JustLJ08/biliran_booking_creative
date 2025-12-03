class Industry {
  final int id;
  final String name;
  final String iconCode;
  final String description;

  Industry({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.description,
  });

  factory Industry.fromJson(Map<String, dynamic> json) {
    return Industry(
      id: json['id'],
      name: json['name'],
      // Fallback to 'circle' if icon_code is missing or null
      iconCode: json['icon_code'] ?? 'circle', 
      description: json['description'] ?? '',
    );
  }
}