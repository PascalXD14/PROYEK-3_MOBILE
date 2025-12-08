import 'package:flutter/material.dart';
import 'services/review_service.dart';
import 'package:intl/intl.dart';

class ReviewListPage extends StatefulWidget {
  final int productId;

  const ReviewListPage({super.key, required this.productId});

  @override
  State<ReviewListPage> createState() => _ReviewListPageState();
}

class _ReviewListPageState extends State<ReviewListPage> {
  final ReviewService reviewService = ReviewService();
  late Future<List<dynamic>> _reviewsFuture;

  int? _activeStar; // ⭐ null = semua, 1..5 = filter rating tertentu

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _loadReviews();

    ReviewService.refreshNotifier.addListener(() {
      if (mounted) {
        setState(() {
          _reviewsFuture = _loadReviews();
        });
      }
    });
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

  /// 🔎 Filter ulasan berdasarkan _activeStar
  List<dynamic> _getFilteredReviews(List<dynamic> reviews) {
    if (_activeStar == null) return reviews;

    return reviews.where((review) {
      if (review is! Map) return false;
      final raw = review['rating'];
      double rating;

      if (raw is num) {
        rating = raw.toDouble();
      } else {
        rating = double.tryParse(raw?.toString() ?? '0') ?? 0;
      }

      return rating.round() == _activeStar;
    }).toList();
  }

  /// 🔘 Chip filter bintang 1 - 5 (mirip filter status di OrderListPage)
  Widget _buildRatingFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Chip "Semua"
            FilterChip(
              selected: _activeStar == null,
              onSelected: (_) => setState(() => _activeStar = null),
              label: Text(
                "Semua Ulasan",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _activeStar == null ? Colors.white : Colors.grey[700],
                ),
              ),
              selectedColor: Colors.green,
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            const SizedBox(width: 8),

            // Chip bintang 1..5
            ...List.generate(5, (i) {
              final star = i + 1;
              final bool active = _activeStar == star;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: active,
                  onSelected: (_) => setState(() => _activeStar = star),
                  label: Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: active ? Colors.white : Colors.amber,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$star",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  selectedColor: Colors.green,
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Ulasan Pelanggan",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Column(
        children: [
          // Header dengan statistik
          FutureBuilder<List<dynamic>>(
            future: _reviewsFuture,
            builder: (context, snapshot) {
              final allReviews = snapshot.data ?? [];
              final totalReviews = allReviews.length;
              final avgRating = totalReviews > 0
                  ? allReviews
                            .map(
                              (r) => (r is Map && r['rating'] is num)
                                  ? (r['rating'] as num).toDouble()
                                  : 0.0,
                            )
                            .reduce((a, b) => a + b) /
                        totalReviews
                  : 0.0;

              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF64DD17)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < avgRating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Rating Rata-rata",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Column(
                      children: [
                        Text(
                          totalReviews.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Total Ulasan",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Filter chips
          _buildRatingFilterChips(),

          // List ulasan
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _reviewsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.green,
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Memuat ulasan...",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red[300],
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Terjadi kesalahan",
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            "${snapshot.error}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allReviews = snapshot.data ?? [];
                final reviews = _getFilteredReviews(allReviews);

                if (allReviews.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.reviews_outlined,
                          color: Colors.grey[300],
                          size: 80,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Belum ada ulasan",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Jadilah yang pertama memberikan ulasan",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (reviews.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_outline_rounded,
                          color: Colors.grey[300],
                          size: 80,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Tidak ada ulasan dengan rating ini",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Coba pilih filter rating lain",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: reviews.length,
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final review = reviews[index];

                    // Ambil nama user
                    String userName = 'Pengguna';
                    if (review is Map && review.containsKey('user')) {
                      final u = review['user'];
                      if (u is Map && u.containsKey('username')) {
                        userName = u['username']?.toString() ?? userName;
                      }
                    }

                    // Ambil rating
                    final rating = (review is Map && review['rating'] is num)
                        ? (review['rating'] as num).toDouble()
                        : 0.0;

                    // Ambil komentar
                    final comment = (review is Map && review['comment'] != null)
                        ? review['comment'].toString()
                        : '';

                    // Formatting tanggal
                    String formattedDate = '';
                    if (review is Map && review['created_at'] != null) {
                      try {
                        final dt = DateTime.parse(
                          review['created_at'],
                        ).toLocal();
                        formattedDate = DateFormat(
                          "d MMM yyyy, HH:mm",
                          "id_ID",
                        ).format(dt);
                      } catch (_) {
                        final str = review['created_at'].toString();
                        formattedDate = str
                            .replaceAll("T", " ")
                            .replaceAll(".000000Z", "");
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header dengan avatar dan nama
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF00C853),
                                            Color(0xFF64DD17),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          userName.isNotEmpty
                                              ? userName[0].toUpperCase()
                                              : "U",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              ...List.generate(
                                                5,
                                                (star) => Icon(
                                                  star < rating.round()
                                                      ? Icons.star_rounded
                                                      : Icons
                                                            .star_border_rounded,
                                                  color: Colors.amber,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                rating.toStringAsFixed(1),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Komentar
                                if (comment.isNotEmpty)
                                  Text(
                                    comment,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                // Tanggal
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      color: Colors.grey[400],
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 13,
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
            ),
          ),
        ],
      ),
    );
  }
}
