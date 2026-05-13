import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../models/booking.dart';
import '../../services/api_service.dart'; 
import 'chat_screen.dart';
import '../../widgets/upload_proof_bottom_sheet.dart';

class BookingDetailScreen extends StatefulWidget {
  final Booking booking;
  final bool isProvider; 

  const BookingDetailScreen({
    super.key, 
    required this.booking, 
    this.isProvider = false, 
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late String _currentStatus;
  String? _paymentProofUrl;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.booking.status ?? 'pending';
    _paymentProofUrl = widget.booking.paymentProofUrl;
  }

  void _showUploadProofModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UploadProofBottomSheet(
        bookingId: widget.booking.id!,
        onUploadSuccess: (newUrl) {
          setState(() {
            _currentStatus = 'deposit_uploaded';
            _paymentProofUrl = newUrl;
          });
        },
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    final success = await ApiService.updateBookingStatus(widget.booking.id!, newStatus);
    if (success) {
      setState(() => _currentStatus = newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Booking marked as $newStatus"),
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return Colors.redAccent;
      case 'completed':
        return Colors.blueAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  // Updated _buildDetailRow to accept icon or symbol
  Widget _buildDetailRow({IconData? icon, String? symbol, required String label, required String value}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: icon != null
              ? Icon(icon, size: 22, color: Colors.grey.shade600)
              : Text(
                  symbol ?? '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.grey[500], fontSize: 12)),
            Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF111827))),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine target info based on role
    String targetName;
    String targetLabel;
    String buttonText;

    if (widget.isProvider) {
      targetName = widget.booking.clientName ?? "Client #${widget.booking.clientId ?? '?'}";
      targetLabel = "Client";
      buttonText = "Message Client";
    } else {
      targetName = widget.booking.creativeName ?? "Provider #${widget.booking.creativeId}";
      targetLabel = "Service Provider";
      buttonText = "Message Provider";
    }

    // Price display — use package price if available, otherwise fallback
    final double rawPrice = widget.booking.packagePrice ?? widget.booking.price ?? 1500.00;
    final String displayCost = rawPrice.toStringAsFixed(2);
    final String depositCost = (rawPrice * 0.3).toStringAsFixed(2);
    final String balanceCost = (rawPrice * 0.7).toStringAsFixed(2);
    final bool hasPackage = widget.booking.packageTitle != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          "Booking Details",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- STATUS CARD ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_currentStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _currentStatus.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        color: _getStatusColor(_currentStatus),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.booking.creativeRole ?? "Creative Service", 
                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text("#${widget.booking.id}", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  _buildDetailRow(icon: Icons.calendar_today_rounded, label: "Date", value: widget.booking.date),
                  const SizedBox(height: 16),
                  _buildDetailRow(icon: Icons.access_time_rounded, label: "Time", value: widget.booking.time),
                  if (hasPackage) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(icon: Icons.inventory_2_rounded, label: "Package", value: widget.booking.packageTitle!),
                  ],
                  const SizedBox(height: 16),
                  _buildDetailRow(symbol: '₱', label: hasPackage ? "Package Price" : "Total Cost", value: displayCost),
                  const SizedBox(height: 16),
                  _buildDetailRow(symbol: '₱', label: "30% Down Payment (Due Now)", value: depositCost),
                  const SizedBox(height: 16),
                  _buildDetailRow(symbol: '₱', label: "70% Balance (On Spot)", value: balanceCost),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- PROFILE SECTION ---
            Text(targetLabel, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: widget.isProvider ? Colors.orange.shade50 : Colors.indigo.shade50,
                    child: Text(
                      targetName.isNotEmpty ? targetName[0].toUpperCase() : "?",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold, 
                        color: widget.isProvider ? Colors.orange : Colors.indigo,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(targetName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(targetLabel, style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            if (widget.isProvider) ...[
              if (_currentStatus == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateStatus('cancelled'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          foregroundColor: Colors.redAccent,
                        ),
                        child: const Text("Decline Request"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateStatus('accepted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text("Accept Request", style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              if (_currentStatus == 'accepted')
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text("Waiting for the client to upload their 30% deposit proof.", style: GoogleFonts.plusJakartaSans(color: Colors.orange.shade900, fontSize: 13, height: 1.5)),
                      ),
                    ],
                  ),
                ),
              if (_currentStatus == 'deposit_uploaded') ...[
                if (_paymentProofUrl != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(image: NetworkImage(_paymentProofUrl!), fit: BoxFit.cover),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateStatus('accepted'), // send back to accepted
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          foregroundColor: Colors.redAccent,
                        ),
                        child: const Text("Reject Proof"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateStatus('confirmed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text("Confirm 30% Received", style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
              if (_currentStatus == 'confirmed')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateStatus('cancelled'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          foregroundColor: Colors.redAccent,
                        ),
                        child: const Text("Cancel Booking"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateStatus('completed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text("Complete (70% Received)", style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
            ] else ...[
              // Client View
              if (_currentStatus == 'pending') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_empty_rounded, color: Colors.grey.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text("Waiting for the provider to accept your request.", style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade900, fontSize: 13, height: 1.5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _updateStatus('cancelled'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      foregroundColor: Colors.redAccent,
                    ),
                    child: const Text("Cancel Booking"),
                  ),
                ),
              ],
              if (_currentStatus == 'accepted') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text("Provider accepted! Please upload your 30% down payment receipt (₱ $depositCost) to secure your slot.", style: GoogleFonts.plusJakartaSans(color: Colors.orange.shade900, fontSize: 13, height: 1.5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showUploadProofModal,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text("Upload Proof of Payment"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
              if (_currentStatus == 'deposit_uploaded') ...[
                if (_paymentProofUrl != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(image: NetworkImage(_paymentProofUrl!), fit: BoxFit.cover),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text("Deposit receipt uploaded. Awaiting provider verification to confirm your booking.", style: GoogleFonts.plusJakartaSans(color: Colors.blue.shade900, fontSize: 13, height: 1.5)),
                      ),
                    ],
                  ),
                ),
              ],
              if (_currentStatus == 'confirmed') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text("Booking Confirmed! Your slot is secured. Please prepare the remaining 70% balance (₱ $balanceCost) to be paid on the spot.", style: GoogleFonts.plusJakartaSans(color: Colors.green.shade900, fontSize: 13, height: 1.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
        child: ElevatedButton.icon(
          onPressed: () {
            final clientId = widget.booking.clientId ?? 0;
            final creativeUserId = widget.booking.creativeUserId ?? 0;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  providerName: targetName,
                  clientId: clientId,
                  creativeUserId: creativeUserId,
                ),
              ),
            );
          },
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: Text(buttonText),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
