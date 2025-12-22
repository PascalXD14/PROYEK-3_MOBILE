import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';

class ChangePasswordPage extends StatefulWidget {
  final int userId;
  const ChangePasswordPage({super.key, required this.userId});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController currentC = TextEditingController();
  final TextEditingController newC = TextEditingController();
  final TextEditingController confirmC = TextEditingController();

  bool loading = false;
  ProfileService? service;

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    final token = await AuthService().getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login terlebih dahulu')),
        );
        Navigator.of(context).pop();
      }
      return;
    }
    service = ProfileService(token);
  }

  Future<void> _changePassword() async {
    if (newC.text != confirmC.text) {
      _showSnackbar('Password baru tidak cocok', isError: true);
      return;
    }

    if (newC.text.length < 8) {
      _showSnackbar('Password minimal 8 karakter', isError: true);
      return;
    }

    if (service == null) {
      _showSnackbar('Service belum siap, coba lagi', isError: true);
      return;
    }

    setState(() => loading = true);

    try {
      await service!.changePassword(currentC.text.trim(), newC.text.trim());
      if (!mounted) return;

      setState(() => loading = false);
      currentC.clear();
      newC.clear();
      confirmC.clear();

      _showSnackbar('Password berhasil diubah', isError: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _showSnackbar(e.toString(), isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    currentC.dispose();
    newC.dispose();
    confirmC.dispose();
    super.dispose();
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    required bool obscure,
    required VoidCallback toggle,
    required bool show,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: 'Masukkan $label',
            prefixIcon: Icon(prefixIcon, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                show ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: toggle,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Ganti Kata Sandi',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Amankan Akun Anda',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Pastikan password baru Anda sulit ditebak dan mengandung kombinasi angka.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 32),

              _buildPasswordField(
                controller: currentC,
                label: 'Password saat ini',
                prefixIcon: Icons.lock_outline,
                obscure: !_showCurrent,
                toggle: () => setState(() => _showCurrent = !_showCurrent),
                show: _showCurrent,
              ),
              const SizedBox(height: 20),

              _buildPasswordField(
                controller: newC,
                label: 'Password baru',
                prefixIcon: Icons.vpn_key_outlined,
                obscure: !_showNew,
                toggle: () => setState(() => _showNew = !_showNew),
                show: _showNew,
              ),
              const SizedBox(height: 20),

              _buildPasswordField(
                controller: confirmC,
                label: 'Konfirmasi password baru',
                prefixIcon: Icons.check_circle_outline,
                obscure: !_showConfirm,
                toggle: () => setState(() => _showConfirm = !_showConfirm),
                show: _showConfirm,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: loading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 68, 255, 115),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
