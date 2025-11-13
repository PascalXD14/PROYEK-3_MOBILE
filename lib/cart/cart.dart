// lib/cart/cart_page.dart
import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import 'cart_content.dart';
import 'package:intl/intl.dart';
import 'edit_cart.dart';
import '../widgets/navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../checkout/checkout_page.dart';

class CartPage extends StatefulWidget {
  final int userId;
  const CartPage({super.key, required this.userId});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService cartService = CartService();
  List<dynamic> cartItems = [];
  Map<int, bool> selectedItems = {};
  double totalPrice = 0;

  @override
  void initState() {
    super.initState();
    fetchCart();
  }

  Future<void> fetchCart() async {
    try {
      final data = await cartService.getCart(widget.userId);
      setState(() {
        cartItems = data;
        selectedItems.clear();
        totalPrice = 0;
      });
    } catch (e) {
      debugPrint("Error load cart: $e");
    }
  }

  void calculateTotal() {
    double total = 0;
    for (var item in cartItems) {
      if (selectedItems[item['id']] ?? false) {
        final price =
            double.tryParse(item['product']['price'].toString()) ?? 0.0;
        total += price * (item['qty'] ?? 0);
      }
    }
    setState(() => totalPrice = total);
  }

  Future<void> updateQty(int cartId, int newQty) async {
    try {
      final item = cartItems.firstWhere(
        (element) => element['id'] == cartId,
        orElse: () => null,
      );

      if (item == null) return;

      final stock = int.tryParse(item['product']['stock'].toString()) ?? 0;

      if (newQty > stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Stok hanya tersedia $stock item."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (newQty < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Jumlah minimal 1 item."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await cartService.updateCart(cartId, newQty);
      await fetchCart();
    } catch (e) {
      debugPrint("Error update qty: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal memperbarui jumlah produk."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSelected =
        selectedItems.isNotEmpty &&
        selectedItems.values.every((v) => v == true);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Keranjang",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditCartPage(userId: widget.userId),
                  ),
                );
                await fetchCart();
              },
              child: const Center(
                child: Text(
                  "Edit",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: CartContent(
        cartItems: cartItems,
        selectedItems: selectedItems,
        onSelectItem: (id, val) {
          setState(() {
            selectedItems[id] = val;
            calculateTotal();
          });
        },
        onUpdateQty: (id, qty) => updateQty(id, qty),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Checkbox(
                  value: allSelected,
                  onChanged: (val) {
                    setState(() {
                      final newVal = val ?? false;
                      for (var item in cartItems) {
                        selectedItems[item['id']] = newVal;
                      }
                      calculateTotal();
                    });
                  },
                ),
                const Text(
                  "Semua",
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  "Rp${NumberFormat('#,###', 'id_ID').format(totalPrice)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: totalPrice > 0
                      ? () async {
                          try {
                            final selected = cartItems
                                .where((i) => selectedItems[i['id']] == true)
                                .toList();

                            if (selected.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Pilih minimal satu item untuk checkout.',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            final first = selected.first;
                            final productId = first['product']?['id'];

                            if (productId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Produk tidak valid.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final prefs = await SharedPreferences.getInstance();
                            final role = prefs.getString('role') ?? 'guest';
                            final userId =
                                prefs.getInt('user_id') ?? widget.userId;

                            if (role == 'guest' || userId == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Silakan login terlebih dahulu.',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CheckoutPage(
                                  productId: productId,
                                  userData: {'id': userId, 'role': role},
                                ),
                              ),
                            );
                          } catch (e) {
                            debugPrint('Error saat checkout: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal memproses checkout: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Checkout",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          CustomBottomNavBar(selectedIndex: 1, userId: widget.userId),
        ],
      ),
    );
  }
}
