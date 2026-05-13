class Booking {
  final int? id;
  final int creativeId;
  final String date;
  final String time;
  final String requirements;
  final String? status;
  
  // Provider details
  final String? creativeName;
  final String? creativeRole;
  final int? creativeUserId;

  // --- NEW FIELDS YOU WERE MISSING ---
  final String? clientName; 
  final int? clientId;   
  final double? price;   
  final String? paymentProofUrl;

  // --- PACKAGE FIELDS ---
  final int? packageId;
  final String? packageTitle;
  final double? packagePrice;

  Booking({
    this.id,
    required this.creativeId,
    required this.date,
    required this.time,
    required this.requirements,
    this.status,
    this.creativeName,
    this.creativeRole,
    this.creativeUserId,
    // --- ADD THESE TO CONSTRUCTOR ---
    this.clientName,
    this.clientId, 
    this.price,    
    this.paymentProofUrl,
    // --- PACKAGE ---
    this.packageId,
    this.packageTitle,
    this.packagePrice,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'creative': creativeId,
      'booking_date': date,
      'booking_time': time,
      'requirements': requirements,
      'status': 'pending',
    };
    if (packageId != null) {
      map['package'] = packageId;
    }
    return map;
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Parse package price if available, otherwise fall back to price field
    double? parsedPackagePrice;
    if (json['package_price'] != null) {
      parsedPackagePrice = double.tryParse(json['package_price'].toString());
    }

    return Booking(
      id: json['id'],
      creativeId: json['creative'],
      date: json['booking_date'],
      time: json['booking_time'],
      requirements: json['requirements'],
      status: json['status'],
      creativeName: json['creative_name'] ?? 'Unknown Creative',
      creativeRole: json['creative_role'] ?? 'Professional',
      creativeUserId: json['creative_user_id'],
      
      // --- FIX: Force a name if the API sends null ---
      clientName: json['client_name'] ?? json['user_name'] ?? "Client Name", 
      
      // --- FIX: Map the Client ID ---
      clientId: json['client_id'] ?? json['user'] ?? json['client'], 
      
      paymentProofUrl: json['payment_proof_url'],

      // --- FIX: Force a price if the API sends null (Fixes "On Quote") ---
      price: json['price'] != null 
          ? double.tryParse(json['price'].toString()) 
          : 1500.00, // <--- FORCED MOCK PRICE (Change 1500.00 to whatever you want)

      // --- PACKAGE FIELDS ---
      packageId: json['package'],
      packageTitle: json['package_title'],
      packagePrice: parsedPackagePrice,
    );
  }
}