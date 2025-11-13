import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import 'package:intl/intl.dart';
import '../Address/address.dart';
import '../pesanan/pesanan.dart';

class CheckoutPage extends StatefulWidget {
  final int productId;
  final Map<String, dynamic> userData;

  const CheckoutPage({
    super.key,
    required this.productId,
    required this.userData,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final OrderService orderService = OrderService();
  final ProductService productService = ProductService();

  Map<String, dynamic>? product;
  bool isLoading = true;
  bool isProcessing = false;
  int qty = 1;
  String selectedPayment = "Transfer Bank";
  Map<String, dynamic>? selectedAddress;

  @override
  void initState() {
    super.initState();
    loadProduct();
  }

  Future<void> loadProduct() async {
    try {
      final data = await productService.getProductDetail(widget.productId);
      setState(() {
        product = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat produk: $e')));
    }
  }

  Future<void> pilihAlamat() async {
    // 🔹 Batasi guest
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

    if (result != null) {
      setState(() {
        selectedAddress = result;
      });
    }
  }

  String formatRupiah(num value) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(value);
  }

  double get totalHarga => (product?['price'] ?? 0) * qty.toDouble();
  double get biayaAdmin => 2000;
  double get totalTagihan => totalHarga + biayaAdmin;

  Future<void> bayarSekarang() async {
    if (widget.userData['role'] == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login terlebih dahulu")),
      );
      return;
    }

    if (product == null || selectedAddress == null) return;

    setState(() => isProcessing = true);

    try {
      final response = await orderService.checkoutOrder(
        userId: widget.userData['id'],
        productId: product!['id'],
        qty: qty,
        price: product!['price'],
        total: totalTagihan.toInt(),
        paymentMethod: selectedPayment,
        shipping: 0,
        serviceFee: biayaAdmin.toInt(),
        recipientName: selectedAddress!['recipient_name'],
        addressId: selectedAddress!['id'],
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil dibuat!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderListPage(userId: widget.userData['id']),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal membuat pesanan'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (product == null) {
      return const Scaffold(
        body: Center(child: Text('Produk tidak ditemukan')),
      );
    }

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
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: selectedAddress == null
                                ? const Text(
                                    "Pilih alamat pengiriman",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
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
                                          fontSize: 14,
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
                  const Divider(height: 1),
                  // (UI asli tetap semua di bawah)
                  Container(
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
                            product!['image_url'],
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
                                product!['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Rp${formatRupiah(product!['price'])}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: qty > 1
                                        ? () => setState(() => qty--)
                                        : null,
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    color: Colors.green,
                                  ),
                                  Text(
                                    "$qty",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: qty < (product!['stock'] ?? 0)
                                        ? () => setState(() => qty++)
                                        : null,
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: Colors.green,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
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
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  const Text(
                    "Ringkasan Belanja",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Column(
                      children: [
                        summaryRow("Total Harga (${qty} Barang)", totalHarga),
                        const SizedBox(height: 8),
                        summaryRow("Biaya Admin", biayaAdmin),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        summaryRow("Total Tagihan", totalTagihan, bold: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? Colors.green[800] : Colors.black87,
          ),
        ),
        Text(
          "Rp${formatRupiah(value)}",
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? Colors.green[800] : Colors.black87,
          ),
        ),
      ],
    );
  }
}
