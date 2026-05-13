class ServicePackage {
  final int id;
  final int creativeId;
  final String title;
  final String description;
  final double price;
  final String deliveryTime;

  ServicePackage({
    required this.id,
    required this.creativeId,
    required this.title,
    required this.description,
    required this.price,
    required this.deliveryTime,
  });

  factory ServicePackage.fromJson(Map<String, dynamic> json) {
    return ServicePackage(
      id: json['id'],
      creativeId: json['creative'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: _parseSafeDouble(json['price']),
      deliveryTime: json['delivery_time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creative': creativeId,
      'title': title,
      'description': description,
      'price': price.toString(),
      'delivery_time': deliveryTime,
    };
  }

  static double _parseSafeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
