import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../services/api_config.dart';

class EditProfilePage extends StatefulWidget {
  final int userId;
  const EditProfilePage({super.key, required this.userId});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  UserProfile? me;
  ProfileService? service;

  final TextEditingController nameC = TextEditingController();
  final TextEditingController usernameC = TextEditingController();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController phoneC = TextEditingController();
  final TextEditingController addressC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => loading = true);
    final cached = await AuthService().getCachedUserInfo();
    if ((cached['username'] ?? '').isNotEmpty ||
        (cached['email'] ?? '').isNotEmpty) {
      setState(() {
        nameC.text = cached['name'] ?? '';
        usernameC.text = cached['username'] ?? '';
        emailC.text = cached['email'] ?? '';
        phoneC.text = cached['phone'] ?? '';
        addressC.text = cached['address'] ?? '';
      });
    }

    final token = await AuthService().getToken();
    if (token == null) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login terlebih dahulu')),
        );
        Navigator.of(context).pop();
      }
      return;
    }
    service = ProfileService(token);
    try {
      final data = await service!.getMe();
      if (!mounted) return;
      setState(() {
        me = data;
        nameC.text = data.name ?? '';
        usernameC.text = data.username;
        emailC.text = data.email;
        phoneC.text = data.phone ?? '';
        addressC.text = data.address ?? '';
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat profil: $e')));
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat mengunggah: user belum terautentikasi'),
        ),
      );
      return;
    }
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    try {
      final url = await service!.uploadAvatar(File(x.path));
      if (!mounted) return;

      final displayUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      setState(() {
        me = UserProfile(
          id: me!.id,
          username: me!.username,
          email: me!.email,
          name: me!.name,
          role: me!.role,
          avatarUrl: displayUrl,
          phone: me!.phone,
          address: me!.address,
          gender: me!.gender,
        );
      });

      await AuthService().setCachedAvatar(url);

      final absolute = ApiConfig.toAbsolute(url);
      final p = await SharedPreferences.getInstance();
      if (absolute.isNotEmpty) {
        await p.setString('avatar_url', absolute);
      } else {
        await p.remove('avatar_url');
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Foto profil diperbarui')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload gagal: $e')));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periksa isian form terlebih dahulu')),
      );
      return;
    }
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat menyimpan: user belum terautentikasi'),
        ),
      );
      debugPrint('ProfileService is null — token mungkin kosong');
      return;
    }
    setState(() => loading = true);
    try {
      final payload = {
        'name': nameC.text.trim(),
        'username': usernameC.text.trim(),
        'email': emailC.text.trim(),
        'phone': phoneC.text.trim(),
        'address': addressC.text.trim(),
      };

      debugPrint('Sending update profile payload: $payload');

      final updated = await service!.updateProfile(payload);
      if (!mounted) return;
      setState(() {
        me = updated;
        loading = false;
      });

      final authSvc = AuthService();
      await authSvc.setCachedUserInfo({
        'id': updated.id,
        'name': updated.name ?? '',
        'username': updated.username,
        'email': updated.email,
        'phone': updated.phone ?? '',
        'address': updated.address ?? '',
        'avatar_url': updated.avatarUrl ?? '',
        'role': updated.role ?? '',
      });

      final p = await SharedPreferences.getInstance();
      await p.setString('name', updated.name ?? '');
      await p.setString('username', updated.username);
      await p.setString('email', updated.email);
      if (updated.avatarUrl != null && updated.avatarUrl!.isNotEmpty) {
        final raw = updated.avatarUrl!;
        final withoutQuery = raw.split('?').first;
        final absolute = ApiConfig.toAbsolute(withoutQuery);
        await p.setString('avatar_url', absolute);
      }
      if (updated.phone != null) await p.setString('phone', updated.phone!);
      if (updated.address != null)
        await p.setString('address', updated.address!);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil disimpan')));

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan profil: $e')));
      debugPrint('Error saat updateProfile: $e');
    }
  }

  @override
  void dispose() {
    nameC.dispose();
    usernameC.dispose();
    emailC.dispose();
    phoneC.dispose();
    addressC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF64748B)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: loading && me == null
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF10B981)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Avatar Section
                    Container(
                      margin: const EdgeInsets.only(bottom: 32),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child:
                                  (me?.avatarUrl != null &&
                                      me!.avatarUrl!.isNotEmpty)
                                  ? Image.network(
                                      me!.avatarUrl!,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: const Color(0xFFF1F5F9),
                                              child: const Icon(
                                                Icons.person,
                                                color: Color(0xFF94A3B8),
                                                size: 40,
                                              ),
                                            );
                                          },
                                    )
                                  : Container(
                                      color: const Color(0xFFF1F5F9),
                                      child: const Icon(
                                        Icons.person,
                                        color: Color(0xFF94A3B8),
                                        size: 40,
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickAndUploadAvatar,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form Section
                    Column(
                      children: [
                        _buildFormField(
                          controller: nameC,
                          label: 'Nama Lengkap',
                          icon: Icons.person_outline_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Name is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: usernameC,
                          label: 'Username',
                          icon: Icons.alternate_email_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Username is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: emailC,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Email is required';
                            if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(v.trim()))
                              return 'Please enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: phoneC,
                          label: 'Nomor Telepon',
                          icon: Icons.phone_iphone_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: addressC,
                          label: 'Alamat',
                          icon: Icons.location_on_outlined,
                          maxLines: 2,
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: loading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Simpan Perubahan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          floatingLabelStyle: const TextStyle(color: Color(0xFF10B981)),
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
