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
  List<dynamic> filteredOrders = [];

  bool isLoading = true;
  String activeFilter = 'Semua';

  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

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
      setState(() {
        orders = response;
        filteredOrders = response;
      });
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

  // ============================
  // SEARCH BAR FUNCTION (DARI KODE PERTAMA)
  // ============================
  void applySearchFilter() {
    final q = searchQuery.toLowerCase();

    List<dynamic> baseList = orders;

    // apply status filter
    if (activeFilter != 'Semua') {
      baseList = baseList.where((order) {
        final status = (order['status'] ?? "").toString().toLowerCase();
        return status == activeFilter.toLowerCase();
      }).toList();
    }

    // apply search query
    setState(() {
      filteredOrders = baseList.where((order) {
        final details = order['details'] as List<dynamic>? ?? [];
        final firstDetail = details.isNotEmpty
            ? details[0] as Map<String, dynamic>
            : {};
        final product = firstDetail['product'] ?? {};

        final productName = (product['name'] ?? "").toString().toLowerCase();
        final trx = extractTransactionCode(order).toLowerCase();
        final total = formatCurrency(
          order['total'] ?? order['grand_total'] ?? 0,
        ).toLowerCase();
        final status = (order['status'] ?? "").toString().toLowerCase();
        final date = extractDate(order).toLowerCase();

        return productName.contains(q) ||
            trx.contains(q) ||
            total.contains(q) ||
            status.contains(q) ||
            date.contains(q);
      }).toList();
    });
  }

  // ============================
  // HELPER METHODS (DARI KODE PERTAMA)
  // ============================

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

  String resolveImageUrl(dynamic field) {
    if (field == null) return '';
    final s = field.toString();
    if (s.startsWith('http')) return s;
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api$'), '');
    return '$base/${s.replaceFirst(RegExp(r"^/"), "")}';
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

  // ============================
  // CARD UI (DARI KODE KEDUA - UI YANG DIMINTA)
  // ============================

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
                          ? Image.network(imageUrl, fit: BoxFit.cover)
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Nomor Orderan:',
                          style: TextStyle(color: Colors.black54),
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
                          style: TextStyle(color: Colors.black54),
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

              // BUTTON LOGIKA (DARI KODE PERTAMA)
              if (status.toLowerCase() == 'diproses')
                OutlinedButton(
                  onPressed: () => _showCancelDialog(order['id']),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                  ),
                  child: const Text(
                    'Batalkan Pesanan',
                    style: TextStyle(color: Colors.green),
                  ),
                ),

              if ((status.toLowerCase() == 'diterima' ||
                      status.toLowerCase() == 'selesai') &&
                  !hasReview)
                OutlinedButton(
                  onPressed: () =>
                      _showReviewDialog(product['id'], order['id']),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
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

  // ============================
  // REVIEW DIALOG (DARI KODE PERTAMA - ORIGINAL WORKING)
  // ============================

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

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (i) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        rating = (i + 1).toDouble();
                                      });
                                    },
                                    child: Icon(
                                      i < rating
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: i < rating
                                          ? Colors.amber
                                          : Colors.grey[400],
                                      size: 40,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: commentCtrl,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText:
                                    "Bagikan pengalaman Anda dengan produk ini...",
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text("Nanti Saja"),
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
                                child: const Text("Kirim Ulasan"),
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

  // ============================
  // CANCEL ORDER (DARI KODE PERTAMA)
  // ============================

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

  // ============================
  // FILTER CHIPS (DARI KODE PERTAMA)
  // ============================

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
              onTap: () {
                setState(() => activeFilter = c);
                applySearchFilter();
              },
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

  // ============================
  // MAIN UI (DARI KODE KEDUA - UI YANG DIMINTA)
  // ============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeader(),
            const SizedBox(height: 8),

            // SEARCH BAR (DARI KODE KEDUA)
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
                child: TextField(
                  controller: searchController,
                  onChanged: (value) {
                    searchQuery = value;
                    applySearchFilter();
                  },
                  decoration: const InputDecoration(
                    hintText: "Cari pesanan Anda...",
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

            // ORDER LIST (DENGAN LOGIKA DARI KODE PERTAMA)
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredOrders.isEmpty
                  ? const Center(child: Text('Belum ada pesanan.'))
                  : RefreshIndicator(
                      onRefresh: fetchOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100, top: 8),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, idx) {
                          final order = Map<String, dynamic>.from(
                            filteredOrders[idx],
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
