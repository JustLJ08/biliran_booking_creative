class Booking {
  final int? id;
  final int creativeId;
  final String date;
  final String time;
  final String requirements;
  final String? status;
  final String? creativeName;
  final String? creativeRole;

  Booking({
    this.id,
    required this.creativeId,
    required this.date,
    required this.time,
    required this.requirements,
    this.status,
    this.creativeName,
    this.creativeRole,
  });

  // Converts a Booking object into a JSON map (for sending to API)
  Map<String, dynamic> toJson() {
    return {
      'creative': creativeId,
      'booking_date': date,
      'booking_time': time,
      'requirements': requirements,
      'status': 'pending',
    };
  }

  // Creates a Booking object from a JSON map (received from API)
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      creativeId: json['creative'],
      date: json['booking_date'],
      time: json['booking_time'],
      requirements: json['requirements'],
      status: json['status'],
      creativeName: json['creative_name'] ?? 'Unknown Creative',
      creativeRole: json['creative_role'] ?? 'Professional',
    );
  }
}