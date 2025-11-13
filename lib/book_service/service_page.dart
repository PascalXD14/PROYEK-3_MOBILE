import 'package:flutter/material.dart';
import 'form_service.dart';
import '../services/service_booking_service.dart';
import 'resume_service.dart';
import '../widgets/navbar.dart';
import '../widgets/header.dart';

class ServiceStatusPage extends StatefulWidget {
  final int userId;
  const ServiceStatusPage({super.key, required this.userId});

  @override
  State<ServiceStatusPage> createState() => _ServiceStatusPageState();
}

class _ServiceStatusPageState extends State<ServiceStatusPage> {
  final ServiceBookingService serviceBookingService = ServiceBookingService();
  List<dynamic> bookings = [];
  bool loading = true;

  int selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final result = await serviceBookingService.getUserServiceBookings(widget.userId);

      if (!mounted) return;

      setState(() {
        bookings = List<dynamic>.from(result);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    }
  }

  void onNavTapped(int index) {
    setState(() => selectedIndex = index);
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case "selesai":
        return const Color(0xFF10B981);
      case "diproses":
        return const Color(0xFFF59E0B);
      case "dibatalkan":
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color statusTextColor(String status) {
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Cari pesanan service...",
                    filled: true,
                    fillColor: Colors.white,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF10B981),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF6B7280),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                  onChanged: (q) {
                    // opsional: implement search lokal nanti
                  },
                ),
              ),
            ),

            Expanded(
              child: loading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                          ),
                          SizedBox(height: 16),
                          Text("Memuat data pesanan...", style: TextStyle(color: Color(0xFF6B7280))),
                        ],
                      ),
                    )
                  : bookings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.car_repair, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text(
                                "Belum ada pesanan service",
                                style: TextStyle(fontSize: 18, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Text("Tekan tombol + untuk membuat pesanan pertama", style: TextStyle(fontSize: 14, color: Colors.grey[500]), textAlign: TextAlign.center),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              ...bookings.asMap().entries.map((entry) {
                                final item = entry.value as Map<String, dynamic>;
                                final isLast = entry.key == bookings.length - 1;

                                final queueNumber = item['queue_number']?.toString() ?? '-';
                                final date = item['date']?.toString() ?? '-';
                                final time = item['time']?.toString() ?? '-';

                                return Container(
                                  margin: EdgeInsets.only(bottom: isLast ? 20 : 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item["name"] ?? "-",
                                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: statusColor((item["status"] ?? "Diproses").toString()),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                item["status"] ?? "Diproses",
                                                style: TextStyle(
                                                  color: statusTextColor((item["status"] ?? "Diproses").toString()),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        _buildDetailRow(Icons.confirmation_number, "Nomor Antrian", queueNumber),
                                        const SizedBox(height: 8),
                                        _buildDetailRow(Icons.category, "Jenis Service", item["type"]?.toString() ?? "-"),
                                        const SizedBox(height: 8),
                                        _buildDetailRow(Icons.calendar_today, "Tanggal", date),
                                        const SizedBox(height: 8),
                                        _buildDetailRow(Icons.access_time, "Jam", time),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ServiceResumePage(serviceId: int.parse(item["id"].toString())),
                                                ),
                                              );
                                              if (mounted) await loadData();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF10B981),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              elevation: 0,
                                            ),
                                            child: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.description, size: 18),
                                                SizedBox(width: 8),
                                                Text("Lihat Resume", style: TextStyle(fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF10B981),
        elevation: 4,
        child: const Icon(Icons.add, size: 35),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceFormPage(userId: widget.userId)));
          if (mounted) await loadData();
        },
      ),

      bottomNavigationBar: CustomBottomNavBar(selectedIndex: selectedIndex, userId: widget.userId),
    );
  }

  // HELPER METHOD UNTUK DETAIL ROW
  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Text("$title: ", style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w400), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
