import 'package:flutter/material.dart';
import 'landing_page3.dart';

class LandingPage2 extends StatelessWidget {
  const LandingPage2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header Ombak dengan logo di tengah
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              width: double.infinity,
              height: 150,
              color: Colors.greenAccent[400],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Arif",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: "Motor",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    height: 2,
                    width: 150,
                    color: Colors.white,
                  ),
                  const Text(
                    "Sahabat Setia Kendaraan Anda.",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: Center(
              child: Image.asset(
                "assets/images/shop.png", // ganti dengan gambar toko/sparepart Anda
                height: 250,
              ),
            ),
          ),

          const Text(
            "Beli Online Saja !!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Cari SparePart Anda !!",
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),

          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Skip",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Row(
                  children: [buildDot(false), buildDot(true), buildDot(false)],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LandingPage3(),
                      ),
                    );
                  },
                  child: Text(
                    "Next",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.green.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);

    // Satu lengkungan besar
    var controlPoint = Offset(size.width / 2, size.height + 40);
    var endPoint = Offset(size.width, size.height - 50);

    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
