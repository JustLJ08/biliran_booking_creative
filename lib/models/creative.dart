import 'sub_category.dart';

class Creative {
  final int id;
  final User user; // This fixes "The getter 'user' isn't defined"
  final SubCategory subCategory;
  final String bio;
  final double hourlyRate;
  final double rating;
  final String? portfolioUrl;
  final String? profileImageUrl; // This fixes "The getter 'profileImageUrl' isn't defined"

  Creative({
    required this.id,
    required this.user,
    required this.subCategory,
    required this.bio,
    required this.hourlyRate,
    required this.rating,
    this.portfolioUrl,
    this.profileImageUrl,
  });

  factory Creative.fromJson(Map<String, dynamic> json) {
    return Creative(
      id: json['id'],
      // We parse the nested 'user' object here
      user: User.fromJson(json['user'] ?? {}),
      subCategory: SubCategory.fromJson(json['sub_category'] ?? {}),
      bio: json['bio'] ?? '',
      
      // Safe parsing to prevent "String is not a subtype of double" crashes
      hourlyRate: _parseSafeDouble(json['hourly_rate']),
      rating: _parseSafeDouble(json['rating']),
      
      portfolioUrl: json['portfolio_url'],
      profileImageUrl: json['profile_image_url'],
    );
  }

  static double _parseSafeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}

// Nested User Class
class User {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;

  User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}