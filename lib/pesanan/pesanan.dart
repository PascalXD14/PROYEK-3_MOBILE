import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/order_service.dart';
import '../widgets/header.dart';
import '../widgets/navbar.dart';
import '../services/api_config.dart';
import '../services/review_service.dart';

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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat pesanan: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
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

  /// 🌟 === DIALOG REVIEW ===
  Future<void> _showReviewDialog(int productId, int transactionId) async {
    double rating = 0;
    final TextEditingController commentCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.white,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade300,
                                    Colors.amber.shade500,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.star_rate_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Beri Ulasan",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Bagikan pengalaman Anda",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // RATING SECTION
                        Center(
                          child: Column(
                            children: [
                              Text(
                                "Bagaimana pengalaman Anda?",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(5, (i) {
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              rating = (i + 1).toDouble();
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            child: Icon(
                                              i < rating
                                                  ? Icons.star_rounded
                                                  : Icons.star_outline_rounded,
                                              color: i < rating
                                                  ? Colors.amber
                                                  : Colors.grey[400],
                                              size: 40,
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      rating == 0
                                          ? "Pilih rating"
                                          : rating == 1
                                          ? "Buruk"
                                          : rating == 2
                                          ? "Kurang"
                                          : rating == 3
                                          ? "Cukup"
                                          : rating == 4
                                          ? "Baik"
                                          : "Sangat Baik",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: rating == 0
                                            ? Colors.grey[500]
                                            : Colors.grey[800],
                                      ),
                                    ),
                                    if (rating > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          "$rating / 5",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // COMMENT
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Tambah komentar",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TextField(
                                  controller: commentCtrl,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    hintText:
                                        "Bagikan pengalaman Anda dengan produk ini...",
                                    hintStyle: TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // BUTTONS
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  "Nanti Saja",
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: rating == 0
                                    ? null
                                    : () async {
                                        await ReviewService().submitReview(
                                          productId: productId,
                                          transactionId: transactionId,
                                          rating: rating,
                                          comment: commentCtrl.text,
                                        );

                                        await fetchOrders();
                                        if (mounted) {
                                          Navigator.pop(dialogContext);
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  backgroundColor: rating == 0
                                      ? Colors.grey[300]
                                      : const Color(0xFF00C853),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.send_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Kirim Ulasan",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// === UI CARD PESANAN + TOMBOL REVIEW ===
  Widget buildOrderCard(Map<String, dynamic> order) {
    final details = (order['details'] is List) ? order['details'] as List : [];
    final firstDetail = details.isNotEmpty
        ? details[0] as Map<String, dynamic>
        : {};
    final product = firstDetail['product'] ?? {};
    final hasReview = firstDetail['has_review'] == true;

    final productName = product['name'] ?? 'Produk tidak diketahui';
    final imageUrl =
        product['image_url'] ??
        resolveImageUrl(product['image']) ??
        resolveImageUrl(product['photo']);
    final trx = extractTransactionCode(order);
    final date = extractDate(order);
    final total = order['total'] ?? order['grand_total'] ?? 0;
    final status = (order['status'] ?? '-').toString();
    final qty = details.fold<int>(
      0,
      (prev, d) => prev + (int.tryParse(d['qty'].toString()) ?? 0),
    );

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
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              /// IMAGE + DETAIL PRODUK
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl.toString().isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.image_not_supported,
                                size: 36,
                                color: Colors.grey,
                              ),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
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
                        const Text(
                          'Nomor Orderan:',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                        Text(
                          trx,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Total Keseluruhan:',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
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

              /// 🌟 TOMBOL REVIEW (MUNCUL SEKALI SAJA)
              if ((status.toLowerCase() == 'diterima' ||
                      status.toLowerCase() == 'selesai') &&
                  !hasReview)
                OutlinedButton(
                  onPressed: () =>
                      _showReviewDialog(product['id'], order['id']),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Beri Ulasan',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// KONFIRMASI CANCEL
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

  /// CATEGORY FILTER CHIP
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
                      offset: Offset(0, 3),
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
