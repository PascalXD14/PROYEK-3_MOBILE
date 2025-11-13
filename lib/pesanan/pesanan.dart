import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/order_service.dart';
import '../services/api_config.dart';
import '../widgets/header.dart';
import '../widgets/navbar.dart';

class OrderListPage extends StatefulWidget {
  final int userId;
  const OrderListPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  final OrderService orderService = OrderService();
  List<dynamic> orders = [];
  bool isLoading = true;
  String activeFilter = 'Semua';

  final currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() => isLoading = true);
    try {
      final response = await orderService.getOrders();
      setState(() => orders = response);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat pesanan: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  String extractTransactionCode(Map<String, dynamic> order) {
    return order['transaction_code'] ??
        order['trx'] ??
        order['transaction'] ??
        '-';
  }

  String extractDate(Map<String, dynamic> order) {
    final raw = order['date'] ?? order['created_at'] ?? order['tanggal'] ?? '';
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw.toString());
      return DateFormat("d MMMM").format(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  String formatCurrency(dynamic amount) {
    if (amount == null) return currency.format(0);
    try {
      return currency.format(double.tryParse(amount.toString()) ?? 0);
    } catch (_) {
      return amount.toString();
    }
  }

  Widget buildStatusPill(String status) {
    Color bg = Colors.grey.shade300;
    Color fg = Colors.black87;
    IconData? icon;

    switch (status.toLowerCase()) {
      case 'diproses':
        bg = Colors.orange.shade400;
        fg = Colors.white;
        icon = Icons.autorenew;
        break;
      case 'dikemas':
        bg = Colors.amber.shade600;
        fg = Colors.white;
        icon = Icons.inventory_2_rounded;
        break;
      case 'dikirim':
        bg = Colors.blue.shade400;
        fg = Colors.white;
        icon = Icons.local_shipping;
        break;
      case 'diterima':
      case 'selesai':
        bg = Colors.green.shade500;
        fg = Colors.white;
        icon = Icons.check_circle;
        break;
      case 'batal':
        bg = Colors.red.shade400;
        fg = Colors.white;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 14, color: fg),
          if (icon != null) const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String resolveImageUrl(dynamic field) {
    if (field == null) return '';
    final s = field.toString();
    if (s.startsWith('http')) return s;
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api$'), '');
    return '$base/${s.replaceFirst(RegExp(r"^/"), "")}';
  }

  List<dynamic> getFilteredOrders() {
    if (activeFilter == 'Semua') return orders;
    return orders.where((o) {
      final st = (o['status'] ?? '').toString().toLowerCase();
      return st == activeFilter.toLowerCase();
    }).toList();
  }

  Widget buildOrderCard(Map<String, dynamic> order) {
    final details = (order['details'] is List) ? order['details'] as List : [];
    final firstDetail = details.isNotEmpty
        ? details[0] as Map<String, dynamic>
        : {};
    final product = firstDetail['product'] ?? {};
    final productName = product['name'] ?? 'Produk tidak diketahui';
    final imageUrl =
        product['image_url'] ??
        resolveImageUrl(product['image']) ??
        resolveImageUrl(product['photo']);
    final qty = details.fold<int>(
      0,
      (prev, d) => prev + (int.tryParse(d['qty'].toString()) ?? 0),
    );

    final trx = extractTransactionCode(order);
    final date = extractDate(order);
    final total = order['total'] ?? order['grand_total'] ?? 0;
    final status = (order['status'] ?? '-').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header tanggal + qty
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pesanan dari $date',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text('x$qty', style: const TextStyle(color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 10),

              // Gambar + Detail
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 88,
                      height: 88,
                      color: Colors.grey[200],
                      child: imageUrl.toString().isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.image_not_supported,
                                size: 36,
                                color: Colors.grey,
                              ),
                            )
                          : const Icon(
                              Icons.image_outlined,
                              size: 36,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Nomor Orderan:',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          trx,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total Keseluruhan:',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          formatCurrency(total),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  buildStatusPill(status),
                ],
              ),
              const SizedBox(height: 14),

              // Tombol Batalkan (kalau masih Diproses)
              if (status.toLowerCase() == 'diproses')
                OutlinedButton(
                  onPressed: () => _showCancelDialog(order['id']),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Batalkan Pesanan',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCancelDialog(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Batalkan pesanan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await orderService.cancelOrder(id);
      fetchOrders();
    }
  }

  Widget buildFilterChips() {
    final chips = [
      'Semua',
      'Diproses',
      'Dikemas',
      'Dikirim',
      'Diterima',
      'Batal',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: chips.map((c) {
          final active = c == activeFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => activeFilter = c),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: active ? Colors.green : Colors.white,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = getFilteredOrders();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeader(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black26, width: 2),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "Silahkan Cari Sparepart Anda",
                    hintStyle: TextStyle(
                      color: Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.black45),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            buildFilterChips(),
            const SizedBox(height: 8),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                  ? const Center(child: Text('Belum ada pesanan.'))
                  : RefreshIndicator(
                      onRefresh: fetchOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100, top: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, idx) {
                          final order = Map<String, dynamic>.from(
                            filtered[idx],
                          );
                          return buildOrderCard(order);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 3,
        userId: widget.userId,
      ),
    );
  }
}
