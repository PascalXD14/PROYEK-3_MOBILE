import 'package:flutter/material.dart';
import '../services/api_config.dart';
import 'package:intl/intl.dart';

class CartContent extends StatelessWidget {
  final List<dynamic> cartItems;
  final Map<int, bool> selectedItems;
  final Function(int, bool) onSelectItem;
  final Function(int, int) onUpdateQty;

  const CartContent({
    super.key,
    required this.cartItems,
    required this.selectedItems,
    required this.onSelectItem,
    required this.onUpdateQty,
  });

  String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return "";
    return "${ApiConfig.baseUrl.replaceFirst('/api', '')}/$imagePath";
  }

  @override
  Widget build(BuildContext context) {
    if (cartItems.isEmpty) {
      return const Center(child: Text("Keranjang kosong"));
    }

    return ListView.builder(
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final item = cartItems[index];
        final product = item['product'];
        final imageUrl =
            product['image_url'] ?? getFullImageUrl(product['image'] ?? '');
        final stock = product['stock'] ?? 0;
        final qty = item['qty'] ?? 1;

        return Container(
          key: ValueKey(item['id']),
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: Colors.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                shape: const CircleBorder(),
                value: selectedItems[item['id']] ?? false,
                onChanged: (val) => onSelectItem(item['id'], val ?? false),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Rp${NumberFormat('#,###', 'id_ID').format(product['price'])}",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green, width: 1),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Tombol Kurang (-)
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove,
                                    color: Colors.green,
                                  ),
                                  onPressed: () {
                                    if (qty > 1) {
                                      onUpdateQty(item['id'], qty - 1);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Jumlah minimal adalah 1",
                                          ),
                                          backgroundColor: Colors.orange,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),

                                // Jumlah Qty
                                Text(
                                  "$qty",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                // Tombol Tambah (+)
                                IconButton(
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.green,
                                  ),
                                  onPressed: () {
                                    if (qty < stock) {
                                      onUpdateQty(item['id'], qty + 1);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Stok ${product['name']} hanya tersisa $stock item",
                                          ),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
