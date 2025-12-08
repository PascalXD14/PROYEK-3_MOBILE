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
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_filled,
              label: "Beranda",
            ),
            _buildNavItem(
              context,
              index: 1,
              icon: Icons.shopping_cart_outlined,
              activeIcon: Icons.shopping_cart,
              label: "Keranjang",
            ),
            _buildNavItem(
              context,
              index: 2,
              icon: Icons.build_outlined,
              activeIcon: Icons.build_circle_outlined,
              label: "Perbaikan",
            ),
            _buildNavItem(
              context,
              index: 3,
              icon: Icons.list_alt_outlined,
              activeIcon: Icons.list_alt,
              label: "Pesanan",
            ),
            _buildNavItem(
              context,
              index: 4,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: "Akun",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;
    final primaryColor = const Color(0xFF00C853);
    final greyColor = const Color(0xFF9E9E9E);

    return GestureDetector(
      onTap: () => _handleNavigation(context, index),
      child: Container(
        width: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? primaryColor.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primaryColor : Colors.transparent,
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 22,
                color: isSelected ? Colors.white : greyColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? primaryColor : greyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index == selectedIndex) return;

    // Tab yang hanya boleh diakses user login
    final restrictedTabs = [1, 3];
    if (restrictedTabs.contains(index) && userId == 0) {
      if (onRestrictedAccess != null) {
        onRestrictedAccess!();
      } else {
        _showLoginSnackbar(context);
      }
      return;
    }

    // Navigasi dengan animasi fade
    Widget page;
    switch (index) {
      case 0:
        page = HomePage(userData: {"id": userId});
        break;
      case 1:
        page = CartPage(userId: userId);
        break;
      case 2:
        page = ServiceStatusPage(userId: userId);
        break;
      case 3:
        page = OrderListPage(userId: userId);
        break;
      case 4:
        page = ProfilePage(userId: userId);
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _showLoginSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Silakan login untuk mengakses fitur ini",
          style: TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF424242),
        elevation: 6,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }
}
