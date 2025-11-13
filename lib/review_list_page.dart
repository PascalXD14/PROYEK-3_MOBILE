import 'package:flutter/material.dart';
import 'services/review_service.dart';

class ReviewListPage extends StatefulWidget {
  final int productId;

  const ReviewListPage({super.key, required this.productId});

  @override
  State<ReviewListPage> createState() => _ReviewListPageState();
}

class _ReviewListPageState extends State<ReviewListPage> {
  final ReviewService reviewService = ReviewService();
  late Future<List<dynamic>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _loadReviews();
  }

  // Memuat data ulasan dari API
  Future<List<dynamic>> _loadReviews() async {
    try {
      final List<dynamic> response = await reviewService.getReviews(
        widget.productId,
      );
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching reviews: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text(
          "Ulasan Pelanggan",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Terjadi kesalahan: ${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final reviews = snapshot.data ?? [];

          if (reviews.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada ulasan untuk produk ini.",
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
            );
          }

          return ListView.builder(
            itemCount: reviews.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final review = reviews[index];

              // Ambil nama user
              String userName = 'Pengguna';
              if (review is Map && review.containsKey('user')) {
                final u = review['user'];
                if (u is Map && u.containsKey('name')) {
                  userName = u['name']?.toString() ?? userName;
                } else if (u is String) {
                  userName = u;
                }
              } else if (review is Map && review.containsKey('user_name')) {
                userName = (review['user_name'] ?? userName).toString();
              }

              // Ambil rating
              final rating = (review is Map && review['rating'] is num)
                  ? (review['rating'] as num).toDouble()
                  : 0.0;

              // Ambil komentar
              final comment = (review is Map && review['comment'] != null)
                  ? review['comment'].toString()
                  : '';

              // Ambil tanggal
              final createdAt = (review is Map && review['created_at'] != null)
                  ? review['created_at'].toString()
                  : '';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama + rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (star) => Icon(
                                star < rating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Komentar
                      Text(
                        comment,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tanggal dibuat
                      Text(
                        createdAt,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
