import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import 'dart:convert';

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

  // toggle visibility
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
    debugPrint('ChangePasswordPage: token: ${token ?? "NULL"}');
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
    // basic client-side checks
    if (newC.text != confirmC.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password baru tidak cocok')),
      );
      return;
    }

    if (newC.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 8 karakter')),
      );
      return;
    }

    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service belum siap, coba lagi')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      debugPrint(
        'ChangePasswordPage: request changePassword (sending current/new)',
      );
      await service!.changePassword(currentC.text.trim(), newC.text.trim());
      if (!mounted) return;

      setState(() => loading = false);
      currentC.clear();
      newC.clear();
      confirmC.clear();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password berhasil diubah')));
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);

      String msg = 'Gagal ganti password';

      // coba parse pesan error dari exception (jika backend mengembalikan JSON)
      try {
        final err = e.toString();
        debugPrint('ChangePasswordPage: exception -> $err');

        final jsonStart = err.indexOf('{');
        if (jsonStart != -1) {
          final jsonStr = err.substring(jsonStart);
          final body = jsonDecode(jsonStr);

          if (body is Map && body['message'] != null) {
            msg = body['message'].toString();
          } else if (body is Map && body['errors'] != null) {
            final errors = body['errors'] as Map;
            if (errors.values.isNotEmpty) {
              final first = errors.values.first;
              if (first is List && first.isNotEmpty) {
                msg = first.first.toString();
              } else {
                msg = first.toString();
              }
            }
          } else {
            msg = jsonStr;
          }
        } else {
          // fallback: gunakan string exception
          msg = e.toString();
        }
      } catch (errParsing) {
        debugPrint('ChangePasswordPage: parse error -> $errParsing');
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
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
    required bool obscure,
    required VoidCallback toggle,
    required bool show,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
      ),
      obscureText: obscure,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ganti Kata Sandi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPasswordField(
              controller: currentC,
              label: 'Password saat ini',
              obscure: !_showCurrent,
              toggle: () => setState(() => _showCurrent = !_showCurrent),
              show: _showCurrent,
            ),
            const SizedBox(height: 8),

            _buildPasswordField(
              controller: newC,
              label: 'Password baru',
              obscure: !_showNew,
              toggle: () => setState(() => _showNew = !_showNew),
              show: _showNew,
            ),
            const SizedBox(height: 8),

            _buildPasswordField(
              controller: confirmC,
              label: 'Konfirmasi password baru',
              obscure: !_showConfirm,
              toggle: () => setState(() => _showConfirm = !_showConfirm),
              show: _showConfirm,
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _changePassword,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: loading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Sedang memproses...'),
                          ],
                        )
                      : const Text('Ganti Kata Sandi'),
                ),
              ),
            ),

            if (loading) const SizedBox(height: 12),
            if (loading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
