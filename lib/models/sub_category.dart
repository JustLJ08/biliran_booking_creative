class SubCategory {
  final int id;
  final String name;
  final int industryId;

  SubCategory({
    required this.id,
    required this.name,
    required this.industryId,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'],
      name: json['name'],
      // Map 'industry' from Django to 'industryId' in Flutter
      industryId: json['industry'], 
    );
  }
}