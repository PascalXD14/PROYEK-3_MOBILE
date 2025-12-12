import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedGender;
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih jenis kelamin terlebih dahulu")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final rawEmail = _emailController.text.trim();
      final sanitizedEmail = rawEmail.replaceAll(',', '.').replaceAll(' ', '');

      String genderForBackend = 'other';
      if (_selectedGender != null) {
        final s = _selectedGender!.toLowerCase();
        if (s.contains('laki')) {
          genderForBackend = 'male';
        } else if (s.contains('perempuan') || s.contains('perempuan')) {
          genderForBackend = 'female';
        } else {
          genderForBackend = 'other';
        }
      }

      final response = await authService.customerRegister(
        name: _nameController.text.trim(),
        alamat: _alamatController.text.trim(),
        phone: _phoneController.text.trim(),
        gender: genderForBackend,
        email: sanitizedEmail,
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      debugPrint("REGISTER RESPONSE: $response");

      if (!mounted) return;

      // Jika backend mengirim object user di response (data/user), sinkronkan cache
      try {
        Map<String, dynamic>? userMap;
        if (response['data'] != null && response['data'] is Map) {
          userMap = response['data'] as Map<String, dynamic>;
        } else if (response['user'] != null && response['user'] is Map) {
          userMap = response['user'] as Map<String, dynamic>;
        }

        if (userMap != null) {
          // coba set cache agar EditProfile bisa prefill
          await AuthService().setCachedUserInfo(userMap);
        } else {
          // fallback: simpan minimal address ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('address', _alamatController.text.trim());
          await prefs.setString('name', _nameController.text.trim());
          await prefs.setString('username', _usernameController.text.trim());
        }
      } catch (e) {
        debugPrint('Gagal set cache setelah registrasi: $e');
      }

      // normalisasi cara memeriksa sukses (beberapa backend berbeda)
      final bool success =
          (response['status'] == 'success') ||
          (response['success'] == true) ||
          (response['message'] != null &&
              (response['message'] as String).toLowerCase().contains(
                'success',
              ));

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendaftaran berhasil! Silakan login.')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        // cermati bila backend mengirim detail error (validation)
        String msg = response['message']?.toString() ?? 'Gagal daftar';

        // coba ambil errors.* jika ada
        try {
          if (response['errors'] != null && response['errors'] is Map) {
            final errors = response['errors'] as Map;
            if (errors['email'] != null &&
                errors['email'] is List &&
                errors['email'].isNotEmpty) {
              msg = errors['email'][0].toString();
            } else if (errors.values.isNotEmpty) {
              // ambil pesan error pertama
              final first = errors.values.first;
              if (first is List && first.isNotEmpty) {
                msg = first.first.toString();
              } else {
                msg = first.toString();
              }
            }
          }
        } catch (_) {}

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      // jika authService melempar exception dengan body JSON (mis. 422), coba parse
      String msg = 'Terjadi kesalahan: $e';
      try {
        final errStr = e.toString();
        // coba parse JSON di dalam exception string
        final start = errStr.indexOf('{');
        if (start != -1) {
          final jsonPart = errStr.substring(start);
          final parsed = jsonDecode(jsonPart);
          if (parsed is Map && parsed['errors'] != null) {
            final errors = parsed['errors'] as Map;
            if (errors['email'] != null &&
                errors['email'] is List &&
                errors['email'].isNotEmpty) {
              msg = errors['email'][0].toString();
            } else if (errors.values.isNotEmpty) {
              final first = errors.values.first;
              if (first is List && first.isNotEmpty)
                msg = first.first.toString();
            }
          } else if (parsed is Map && parsed['message'] != null) {
            msg = parsed['message'].toString();
          }
        }
      } catch (_) {
        // ignore parse error
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: (value) =>
            value == null || value.isEmpty ? '$label tidak boleh kosong' : null,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Email tidak boleh kosong';
          final email = v.trim().replaceAll(',', '.').replaceAll(' ', '');
          final re = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
          if (!re.hasMatch(email)) return 'Email tidak valid';
          return null;
        },
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: "Email",
          labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedGender,
        hint: const Text("Pilih Jenis Kelamin"),
        items: const [
          DropdownMenuItem(value: "Laki-laki", child: Text("Laki-laki")),
          DropdownMenuItem(value: "Perempuan", child: Text("Perempuan")),
        ],
        onChanged: (value) {
          setState(() => _selectedGender = value);
        },
        validator: (value) =>
            value == null ? "Jenis kelamin tidak boleh kosong" : null,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/images/OmbakLogin.png",
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Arif",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                "Motor",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 350),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Daftar",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildTextField("Nama", _nameController),
                              _buildTextField("Alamat", _alamatController),
                              _buildTextField("No. HP", _phoneController),
                              _buildGenderDropdown(),
                              _buildEmailField(), // <-- pakai field yang sudah divalidasi & disanitasi
                              _buildTextField("Username", _usernameController),
                              _buildTextField(
                                "Password",
                                _passwordController,
                                obscure: true,
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : _register,
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          "Daftar",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Center(
                                child: Text(
                                  "Arif Motor",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
