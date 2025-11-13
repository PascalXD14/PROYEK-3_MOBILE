import 'package:flutter/material.dart';
import '../home.dart';
import '../cart/cart.dart';
import '../book_service/service_page.dart';
import '../pesanan/pesanan.dart';
import '../profile/profil.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final int userId;
  final VoidCallback? onRestrictedAccess;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.userId,
    this.onRestrictedAccess,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: "Keranjang",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.build), label: "Perbaikan"),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Pesanan"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Akun"),
      ],
      onTap: (index) {
        if (index == selectedIndex) return;

        // Tab yang hanya boleh diakses user login
        final restrictedTabs = [1, 3];
        if (restrictedTabs.contains(index) && userId == 0) {
          if (onRestrictedAccess != null) {
            onRestrictedAccess!();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Silakan login untuk mengakses fitur ini"),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return; // hentikan navigasi
        }

        // Navigasi ke halaman sesuai tab
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HomePage(userData: {"id": userId}),
              ),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => CartPage(userId: userId)),
            );
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ServiceStatusPage(userId: userId),
              ),
            );
            break;
          case 3:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => OrderListPage(userId: userId)),
            );
            break;
          case 4:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ProfilePage(userId: userId)),
            );
            break;
        }
      },
    );
  }
}
