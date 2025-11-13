import 'package:flutter/material.dart';
import '../services/service_booking_service.dart';
import 'service_page.dart';

class ServiceFormPage extends StatefulWidget {
  final int userId;
  const ServiceFormPage({super.key, required this.userId});

  @override
  _ServiceFormPageState createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends State<ServiceFormPage> {
  final ServiceBookingService serviceBookingService = ServiceBookingService();

  final TextEditingController namaC = TextEditingController();
  final TextEditingController alamatC = TextEditingController();
  final TextEditingController hpC = TextEditingController();
  final TextEditingController motorC = TextEditingController();
  final TextEditingController jenisC = TextEditingController();
  DateTime? tanggal;
  TimeOfDay? jam;

  bool loading = false;

  Future<void> submit() async {
    if (tanggal == null || jam == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tanggal & Jam belum diisi")));
      return;
    }

    setState(() => loading = true);

    try {
      final result = await serviceBookingService.bookService(
        name: namaC.text,
        address: alamatC.text,
        phone: hpC.text,
        vehicle: motorC.text,
        type: jenisC.text,
        date: tanggal.toString().substring(0, 10),
        time: "${jam!.hour}:${jam!.minute.toString().padLeft(2, '0')}",
      );

      // result sudah berupa object booking (sesuai service_booking_service)
      final booking = Map<String, dynamic>.from(result);
      final queueNumber = booking['queue_number']?.toString() ?? '-';

      int uid = widget.userId;
      try {
        if (booking.containsKey('user_id')) {
          uid = int.parse(booking['user_id'].toString());
        } else if (booking.containsKey('user') && booking['user'] is Map && booking['user']['id'] != null) {
          uid = int.parse(booking['user']['id'].toString());
        }
      } catch (_) {
        // fallback ke widget.userId
      }

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Booking Berhasil"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Nomor Antrian kamu:"),
              const SizedBox(height: 8),
              Text("#$queueNumber", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              const SizedBox(height: 12),
              const Text("Simpan nomor ini & datang sesuai jadwal."),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Tutup"))],
        ),
      );

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ServiceStatusPage(userId: uid)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal submit: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    namaC.dispose();
    alamatC.dispose();
    hpC.dispose();
    motorC.dispose();
    jenisC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Form Registrasi Service', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(margin: const EdgeInsets.only(bottom: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Booking Service', style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              const Text('Isi formulir di bawah untuk melakukan booking service kendaraan', style: TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
            ])),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: Offset(0, 4))]),
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                _input(namaC, "Nama Lengkap", Icons.person),
                const SizedBox(height: 16),
                _input(jenisC, "Jenis Service", Icons.build),
                const SizedBox(height: 16),
                _input(alamatC, "Alamat Lengkap", Icons.location_on),
                const SizedBox(height: 16),
                _input(hpC, "No. HP/WhatsApp", Icons.phone, keyboard: TextInputType.phone),
                const SizedBox(height: 16),
                _input(motorC, "Varian Motor", Icons.two_wheeler),
                const SizedBox(height: 24),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Pilih Jadwal', style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Row(children: [Expanded(child: _datePicker()), const SizedBox(width: 12), Expanded(child: _timePicker())]),
                ]),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : submit,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.send, size: 18), SizedBox(width: 8), Text("Kirim Booking", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String label, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return Container(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextField(controller: c, keyboardType: keyboard, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20))),
    ]));
  }

  Widget _datePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2030), initialDate: DateTime.now());
        if (picked != null) setState(() => tanggal = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12), color: Colors.white),
        child: Row(children: [Icon(Icons.calendar_today, color: const Color(0xFF6B7280), size: 20), const SizedBox(width: 12), Expanded(child: Text(tanggal == null ? "Pilih Tanggal" : "Tanggal: ${tanggal.toString().substring(0, 10)}", style: TextStyle(color: tanggal == null ? const Color(0xFF9CA3AF) : const Color(0xFF1E293B))))]),
      ),
    );
  }

  Widget _timePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
        if (picked != null) setState(() => jam = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12), color: Colors.white),
        child: Row(children: [Icon(Icons.access_time, color: const Color(0xFF6B7280), size: 20), const SizedBox(width: 12), Expanded(child: Text(jam == null ? "Pilih Jam" : "Jam: ${jam!.hour}:${jam!.minute.toString().padLeft(2, '0')}", style: TextStyle(color: jam == null ? const Color(0xFF9CA3AF) : const Color(0xFF1E293B))))]),
      ),
    );
  }
}
