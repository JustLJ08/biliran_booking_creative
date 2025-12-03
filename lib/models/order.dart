class Order {
  final int id;
  final String productName;
  final int quantity;
  final double totalPrice;
  final String status;
  final String clientName;
  final String date;

  Order({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.clientName,
    required this.date,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Handle client name safely if nested or missing
    // The backend might return client name directly or nested under 'client' object
    // Adjust based on your actual Django serializer output.
    // Here we assume the serializer sends 'client_name' as a flat field based on previous steps.
    String client = "Unknown Client";
    if (json['client_name'] != null) {
      client = json['client_name']; 
    }
    
    return Order(
      id: json['id'],
      productName: json['product_name'] ?? 'Unknown Product',
      quantity: json['quantity'] ?? 0,
      // Ensure numeric values are parsed correctly even if they come as strings
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      status: json['status'] ?? 'pending',
      clientName: client,
      // Format date string if present
      date: json['created_at'] != null 
          ? json['created_at'].toString().substring(0, 10) 
          : '',
    );
  }
}