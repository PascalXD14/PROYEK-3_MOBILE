// lib/cart/edit_cart.dart
import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import 'cart_content.dart';

class EditCartPage extends StatefulWidget {
  final int userId;
  const EditCartPage({super.key, required this.userId});

  @override
  State<EditCartPage> createState() => _EditCartPageState();
}

class _EditCartPageState extends State<EditCartPage> {
  final CartService cartService = CartService();
  List<dynamic> cartItems = [];
  Map<int, bool> selectedItems = {};

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
      });
    } catch (e) {
      debugPrint("❌ Gagal load cart: $e");
    }
  }

  Future<void> deleteSelected() async {
    final ids = selectedItems.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    for (final id in ids) {
      await cartService.removeCartItem(id);
    }
    await fetchCart();
  }

  Future<void> updateQty(int cartId, int newQty) async {
    try {
      final item = cartItems.firstWhere((item) => item['id'] == cartId);
      final stock = item['product']['stock'] ?? 0;

      if (newQty > stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Stok hanya tersedia $stock item"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final productId = item['product']['id'];
      await cartService.addToCart(
        userId: widget.userId,
        productId: productId,
        qty: newQty,
      );
      await fetchCart();
    } catch (e) {
      debugPrint("❌ Error update qty: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSelected =
        selectedItems.isNotEmpty &&
        selectedItems.values.every((v) => v == true);

    return Scaffold(
      backgroundColor: Colors.grey[100],

      // Header EditCartPage tetap ada panah kembali
      appBar: AppBar(
        title: const Text(
          "Edit Keranjang",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: CartContent(
        cartItems: cartItems,
        selectedItems: selectedItems,
        onSelectItem: (id, val) {
          setState(() => selectedItems[id] = val);
        },
        onUpdateQty: (id, qty) => updateQty(id, qty),
      ),

      bottomNavigationBar: Container(
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
                });
              },
            ),
            const Text(
              "Pilih Semua",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: selectedItems.containsValue(true)
                  ? () async {
                      await deleteSelected();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Hapus",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
