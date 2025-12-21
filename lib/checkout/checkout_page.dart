import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/order_service.dart';
import '../Address/address.dart';
import '../pesanan/pesanan.dart';
import '../payment/snap_webview.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> userData;

  const CheckoutPage({super.key, required this.items, required this.userData});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final OrderService orderService = OrderService();

  bool isProcessing = false;
  String selectedPayment = "Transfer Bank";
  Map<String, dynamic>? selectedAddress;

  Future<void> pilihAlamat() async {
    if (widget.userData['role'] == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login terlebih dahulu")),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddressListPage()),
    );

    if (result != null && mounted) {
      setState(() => selectedAddress = result);
    }
  }

  String formatRupiah(num value) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(value);
  }

  double get totalHarga {
    double total = 0;
    for (final item in widget.items) {
      total += (item['price'] * item['qty']).toDouble();
    }
    return total;
  }

  double get biayaAdmin => 2000;
  double get totalTagihan => totalHarga + biayaAdmin;

  Future<void> bayarSekarang() async {
    if (widget.userData['role'] == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login terlebih dahulu")),
      );
      return;
    }

    if (selectedAddress == null) return;

    setState(() => isProcessing = true);

    try {
      final res = await orderService.payWithMidtransMulti(
        userId: widget.userData['id'],
        items: widget.items,
        total: totalTagihan.toInt(),
        recipientName: selectedAddress!['recipient_name'],
        shippingAddress: selectedAddress!['address'],
      );

      if (res['success'] == true && res['redirect_url'] != null) {
        final snapUrl = res['redirect_url'];

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SnapWebView(url: snapUrl, userId: widget.userData['id']),
          ),
        );

        if (result == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderListPage(userId: widget.userData['id']),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    }

    if (mounted) setState(() => isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ALAMAT
                  const Text(
                    "Alamat Pengiriman",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: pilihAlamat,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.lightGreenAccent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.lightGreenAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: selectedAddress == null
                                ? const Text(
                                    "Pilih alamat pengiriman",
                                    style: TextStyle(color: Colors.grey),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedAddress!['recipient_name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[800],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${selectedAddress!['phone']}\n${selectedAddress!['address']}",
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),

                  /// LIST PRODUK (MULTI + QTY CONTROL)
                  ...widget.items.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[50],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item['image'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Rp${formatRupiah(item['price'])}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: item['qty'] > 1
                                          ? () => setState(() => item['qty']--)
                                          : null,
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      color: Colors.green,
                                    ),
                                    Text(
                                      "${item['qty']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed:
                                          item['qty'] < (item['stock'] ?? 999)
                                          ? () => setState(() => item['qty']++)
                                          : null,
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      color: Colors.green,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const Divider(),
                  const SizedBox(height: 20),

                  /// METODE PEMBAYARAN
                  const Text(
                    "Metode Pembayaran",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        RadioListTile(
                          title: const Text("Transfer Bank"),
                          value: "Transfer Bank",
                          groupValue: selectedPayment,
                          onChanged: (val) =>
                              setState(() => selectedPayment = val!),
                          activeColor: Colors.green,
                        ),
                        Divider(height: 1, color: Colors.grey[300]),
                        RadioListTile(
                          title: const Text("COD"),
                          value: "COD",
                          groupValue: selectedPayment,
                          onChanged: (val) =>
                              setState(() => selectedPayment = val!),
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),

                  /// RINGKASAN
                  const Text(
                    "Ringkasan Belanja",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  summaryRow(
                    "Total Harga (${widget.items.length} Barang)",
                    totalHarga,
                  ),
                  summaryRow("Biaya Admin", biayaAdmin),
                  const Divider(),
                  summaryRow("Total Tagihan", totalTagihan, bold: true),
                ],
              ),
            ),
          ),

          /// BUTTON BAYAR
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isProcessing ? null : bayarSekarang,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Bayar Sekarang",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget summaryRow(String title, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "Rp${formatRupiah(value)}",
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
