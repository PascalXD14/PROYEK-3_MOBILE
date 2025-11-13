import 'package:flutter/material.dart';
import '../services/service_booking_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ServiceResumePage extends StatefulWidget {
  final int serviceId;
  const ServiceResumePage({super.key, required this.serviceId});

  @override
  State<ServiceResumePage> createState() => _ServiceResumePageState();
}

class _ServiceResumePageState extends State<ServiceResumePage> {
  final ServiceBookingService serviceBookingService = ServiceBookingService();
  Map<String, dynamic>? data;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadResume();
  }

  Future<void> loadResume() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      // terima result sebagai dynamic / nullable — lebih fleksibel
      final dynamic raw = await serviceBookingService.getResumeById(
        widget.serviceId,
      );

      // normalisasi: jika raw adalah Map (bisa langsung data atau { data: {...} })
      Map<String, dynamic>? resolved;
      if (raw == null) {
        resolved = null;
      } else if (raw is Map && raw.containsKey('data') && raw['data'] is Map) {
        resolved = Map<String, dynamic>.from(raw['data'] as Map);
      } else if (raw is Map) {
        resolved = Map<String, dynamic>.from(raw);
      } else {
        // bentuk lain -> treat as not found
        resolved = null;
      }

      if (!mounted) return;
      setState(() {
        data = resolved; // data bertipe Map<String,dynamic>?
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat resume: $e')));
    }
  }

  Future<void> generatePDF() async {
    if (data == null) return;
    final pdf = pw.Document();
    final d = data!;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    "RESUME LAYANAN SERVICE",
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 25),
                pw.Text("No. Antrian     : ${d['queue_number'] ?? '-'}"),
                pw.Text("Nama            : ${d['name'] ?? '-'}"),
                pw.Text("Alamat          : ${d['address'] ?? '-'}"),
                pw.Text("No. HP          : ${d['phone'] ?? '-'}"),
                pw.Text("Motor           : ${d['vehicle'] ?? '-'}"),
                pw.Text("Jenis Service   : ${d['type'] ?? '-'}"),
                pw.Text("Tanggal         : ${d['date'] ?? '-'}"),
                pw.Text("Jam             : ${d['time'] ?? '-'}"),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Resume Layanan",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!loading && data != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.picture_as_pdf, size: 24),
                onPressed: generatePDF,
                tooltip: "Export PDF",
              ),
            ),
        ],
      ),
      body: loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF10B981),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Memuat data resume...",
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            )
          : (data == null)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    "Data tidak ditemukan",
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Silakan coba lagi nanti",
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.assignment_turned_in,
                          size: 50,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "RESUME LAYANAN SERVICE",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "No. Antrian: ${data!['queue_number'] ?? '-'}",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Detail Layanan",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: Color(0xFFE5E7EB)),
                        const SizedBox(height: 16),
                        _detailItem(
                          Icons.person,
                          "Nama Lengkap",
                          data!['name'] ?? '-',
                        ),
                        _detailItem(
                          Icons.location_on,
                          "Alamat",
                          data!['address'] ?? '-',
                        ),
                        _detailItem(
                          Icons.phone,
                          "No. HP/WhatsApp",
                          data!['phone'] ?? '-',
                        ),
                        _detailItem(
                          Icons.two_wheeler,
                          "Varian Motor",
                          data!['vehicle'] ?? '-',
                        ),
                        _detailItem(
                          Icons.build,
                          "Jenis Service",
                          data!['type'] ?? '-',
                        ),
                        _detailItem(
                          Icons.calendar_today,
                          "Tanggal Service",
                          data!['date'] ?? '-',
                        ),
                        _detailItem(
                          Icons.access_time,
                          "Jam Service",
                          data!['time'] ?? '-',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: generatePDF,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Export PDF",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: const Color(0xFF0EA5E9),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Bawa resume ini saat datang ke bengkel untuk proses service motor anda",
                            style: TextStyle(
                              color: const Color(0xFF0C4A6E),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD1FAE5)),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF10B981)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
