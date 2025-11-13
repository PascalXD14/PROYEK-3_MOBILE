import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../entry/login.dart';
import '../../widgets/navbar.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? me;
  bool loading = true;
  ProfileService? service;

  Future<void> _loadFromCache() async {
    final p = await SharedPreferences.getInstance();
    final cached = {
      'id': widget.userId,
      'username': p.getString('username') ?? '',
      'email': p.getString('email') ?? '',
      'name': p.getString('name'),
      'role': p.getString('role'),
      'avatar_url': p.getString('avatar_url'),
    };
    if ((cached['username'] as String).isNotEmpty ||
        (cached['email'] as String).isNotEmpty) {
      setState(() => me = UserProfile.fromJson(cached));
    }
  }

  Future<void> _init() async {
    await _loadFromCache();

    final token = await AuthService().getToken();
    if (token == null) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login terlebih dahulu')),
        );
      }
      return;
    }

    service = ProfileService(token);

    try {
      final data = await service!.getMe();
      if (!mounted) return;
      setState(() {
        me = data;
        loading = false;
      });

      final p = await SharedPreferences.getInstance();
      await p.setString('name', data.name ?? '');
      await p.setString('username', data.username);
      await p.setString('email', data.email);
      await p.setString('role', data.role ?? '');
      if (data.avatarUrl != null) {
        await p.setString('avatar_url', data.avatarUrl!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat profil: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _changeAvatar() async {
    if (service == null) return;
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;

    try {
      final url = await service!.uploadAvatar(File(x.path));
      if (!mounted) return;

      setState(() {
        me = UserProfile(
          id: me!.id,
          username: me!.username,
          email: me!.email,
          name: me!.name,
          role: me!.role,
          avatarUrl: '${url}?t=${DateTime.now().millisecondsSinceEpoch}',
        );
      });

      await AuthService().setCachedAvatar(url);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Foto profil diperbarui')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading && me == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFBFEFC2),
        body: Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                strokeWidth: 3,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFBFEFC2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        automaticallyImplyLeading: false, // no back, no more-vert
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + kBottomNavigationBarHeight,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // avatar card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _changeAvatar,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              // outer glow ring
                              Container(
                                width: 120,
                                height: 120,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF22C55E),
                                      Color(0xFF3B82F6),
                                    ],
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: CircleAvatar(
                                    radius: 56,
                                    backgroundColor: Colors.white,
                                    backgroundImage:
                                        (me?.avatarUrl != null &&
                                            me!.avatarUrl!.isNotEmpty)
                                        ? NetworkImage(me!.avatarUrl!)
                                        : null,
                                    child:
                                        (me?.avatarUrl == null ||
                                            me!.avatarUrl!.isEmpty)
                                        ? const Icon(
                                            Icons.person,
                                            size: 48,
                                            color: Color(0xFF9CA3AF),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              // camera badge
                              Container(
                                width: 36,
                                height: 36,
                                margin: const EdgeInsets.only(
                                  right: 4,
                                  bottom: 4,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Color(0xFF22C55E),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          (me?.name?.isNotEmpty ?? false)
                              ? me!.name!
                              : (me?.username ?? '-'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          me?.email ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // tombol keluar
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await AuthService().logout();

                          if (!mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        },

                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF22C55E), Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Keluar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // menu items
                  _Menu(
                    icon: Icons.person_outline_rounded,
                    text: 'Edit Profil',
                    color: const Color(0xFF22C55E),
                    onTap: () {},
                  ),
                  _Menu(
                    icon: Icons.settings_outlined,
                    text: 'Pengaturan Akun',
                    color: const Color(0xFF3B82F6),
                    onTap: () {},
                  ),
                  _Menu(
                    icon: Icons.location_on_outlined,
                    text: 'Alamat Saya',
                    color: const Color(0xFF8B5CF6),
                    onTap: () {},
                  ),
                  _Menu(
                    icon: Icons.delete_outline_rounded,
                    text: 'Hapus Akun',
                    color: const Color(0xFFEF4444),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 4,
        userId: widget.userId,
        onRestrictedAccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Silakan login untuk mengakses fitur ini'),
            ),
          );
        },
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _Menu({
    required this.icon,
    required this.text,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.45),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black.withOpacity(0.45),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
