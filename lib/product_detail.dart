import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import 'review_list_page.dart';
import '../checkout/checkout_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;
  final Map<String, dynamic>? userData;
  const ProductDetailPage({Key? key, required this.productId, this.userData})
    : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ProductService productService = ProductService();
  final CartService cartService = CartService();

  late Future<Map<String, dynamic>> _product;
  int? _userId;
  String? _role;

  late VoidCallback _productDetailRefreshListener;

  @override
  void initState() {
    super.initState();
    _product = productService.getProductDetail(widget.productId);
    _loadUserData();

    _productDetailRefreshListener = () {
      if (!mounted) return;
      setState(() {
        _product = productService.getProductDetail(widget.productId);
      });
    };
    ProductService.refreshNotifier.addListener(_productDetailRefreshListener);
  }

  @override
  void dispose() {
    ProductService.refreshNotifier.removeListener(
      _productDetailRefreshListener,
    );
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getInt('user_id');
    final savedRole = prefs.getString('role');
    setState(() {
      _userId = savedId ?? widget.userData?['id'];
      _role = savedRole ?? widget.userData?['role'] ?? 'guest';
    });
  }

  // ========================= CHAT OPTIONS ========================= //

  Widget _chatOptionSheet(Map<String, dynamic> product) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Pilih Pertanyaan",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _chatOption("Apakah produk ini tersedia?", product),
          _chatOption("Apakah bisa dikirim hari ini?", product),
          _chatOption("Saya ingin bertanya lebih lanjut", product),
        ],
      ),
    );
  }

  Widget _chatOption(String text, Map<String, dynamic> product) {
    return ListTile(
      title: Text(text),
      leading: const Icon(Icons.help_outline),
      onTap: () async {
        await ChatService().sendMessage(
          text,
          productId: widget.productId,
          productName: product['name'],
          productPrice: product['price'],
          productImage: product['image_url'],
        );

        if (!mounted) return;
        Navigator.pop(context);
        Navigator.pushNamed(context, '/chat');
      },
    );
  }

  // ========================= BUILD UI ========================= //

  @override
  Widget build(BuildContext context) {
    final formatRupiah = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _product,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData) {
              return const Center(child: Text("Produk tidak ditemukan"));
            }

            final product = snapshot.data!;
            final harga = product['price'] is int
                ? product['price']
                : int.tryParse(product['price'].toString()) ?? 0;

            final List reviews = product['reviews_preview'] is List
                ? (product['reviews_preview'] as List)
                : [];

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === HEADER ===
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.shopping_cart_outlined,
                            size: 26,
                            color: Colors.black87,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  // === GAMBAR PRODUK ===
                  Image.network(
                    product['image_url'] ?? '',
                    width: double.infinity,
                    height: 240,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(height: 200, color: Colors.grey[300]),
                  ),

                  // === NAMA & HARGA ===
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "${product['reviews_avg_rating'] ?? 0} • ${product['sold'] ?? 0} terjual",
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        Text(
                          formatRupiah.format(harga),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // === DESKRIPSI ===
                  Container(
                    width: double.infinity,
                    color: Colors.grey[100],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Deskripsi Produk",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product['description'] ?? 'Tidak ada deskripsi',
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  // === ULASAN PELANGGAN ===
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ReviewListPage(productId: widget.productId),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                "Ulasan Pelanggan",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 18,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (reviews.isNotEmpty)
                            ...reviews.take(2).map<Widget>((r) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          r['user'] ?? 'Pengguna',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(5, (i) {
                                            return Icon(
                                              i < (r['rating'] ?? 0)
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Colors.amber,
                                              size: 16,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      r['comment'] ?? "",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      r['created_at'] ?? "",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),

      // === BOTTOM BAR ===
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12)),
        ),
        child: Row(
          children: [
            // ========== CHAT BUTTON ========== //
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.green,
                ),
                onPressed: () async {
                  if (_role == 'guest' || _userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Silakan login terlebih dahulu."),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  final product = await _product;

                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (context) {
                      return _chatOptionSheet(product);
                    },
                  );
                },
              ),
            ),

            const SizedBox(width: 8),

            // ========== BELI SEKARANG ==========
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () async {
                  if (_role == 'guest' || _userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Silakan login terlebih dahulu.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  final product = await _product;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutPage(
                        items: [
                          {
                            'product_id': widget.productId,
                            'name': product['name'],
                            'price': product['price'],
                            'qty': 1,
                            'image': product['image_url'],
                          },
                        ],
                        userData:
                            widget.userData ?? {'id': _userId, 'role': _role},
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Beli Langsung",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // ========== TAMBAH KERANJANG ==========
            Expanded(
              flex: 1,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_role == 'guest' || _userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Silakan login terlebih dahulu.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  try {
                    final result = await cartService.addToCart(
                      userId: _userId!,
                      productId: widget.productId,
                      qty: 1,
                    );

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result['message'] ??
                              'Produk berhasil ditambahkan ke keranjang ',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menambahkan ke keranjang: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Keranjang",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
