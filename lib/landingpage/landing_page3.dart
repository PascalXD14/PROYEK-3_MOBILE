import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../home.dart';

class LandingPage3 extends StatelessWidget {
  const LandingPage3({super.key});

  Future<void> _loginAsGuest(BuildContext context) async {
    final authService = AuthService();
    try {
      final guestData = await authService.guestLogin();
      debugPrint("Guest login berhasil: $guestData");

      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage(userData: null)),
      );
    } catch (e) {
      debugPrint("Gagal login sebagai guest: $e");

      // di sini juga cek dulu
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal masuk sebagai tamu")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header Ombak
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              width: double.infinity,
              height: 150,
              color: Colors.greenAccent[400],
              padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
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
                    margin: const EdgeInsets.only(top: 2, bottom: 2),
                    height: 2,
                    width: 140,
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

          // Gambar utama
          Expanded(
            child: Center(
              child: Image.asset("assets/images/mobil.png", height: 200),
            ),
          ),

          const SizedBox(height: 20),

          // Tombol Masuk
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: GestureDetector(
              onTap: () => _loginAsGuest(context),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(
                    colors: [Colors.greenAccent, Colors.lightBlueAccent],
                  ),
                ),
                child: const Center(
                  child: Text(
                    "Masuk",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Indicator dot
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [buildDot(false), buildDot(false), buildDot(true)],
          ),

          const SizedBox(height: 30),
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
    path.lineTo(0, size.height - 40);

    var firstControlPoint = Offset(size.width / 4, size.height - 80);
    var firstEndPoint = Offset(size.width / 2, size.height - 40);
    var secondControlPoint = Offset(3 * size.width / 4, size.height);
    var secondEndPoint = Offset(size.width, size.height - 40);

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
