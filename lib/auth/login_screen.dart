import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  int selectedRole = 0;
  bool _isLoading = false;
  static const List<String> _roles = ['Sinh viên', 'Giảng viên', 'Quản trị'];

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findUser(
    String identifier,
  ) async {
    final users = FirebaseFirestore.instance.collection('users');

    final byDocId = await users.doc(identifier).get();
    if (byDocId.exists) return byDocId;

    final byUsername = await users
        .where('username', isEqualTo: identifier)
        .limit(1)
        .get();
    if (byUsername.docs.isNotEmpty) return byUsername.docs.first;

    final byEmail = await users
        .where('email', isEqualTo: identifier)
        .limit(1)
        .get();
    if (byEmail.docs.isNotEmpty) return byEmail.docs.first;

    return null;
  }

  Future<void> _loginUser() async {
    final identifier = _emailController.text.trim();
    final password = _passwordController.text;
    final selectedRoleName = _roles[selectedRole];
    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền email và mật khẩu')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userDoc = await _findUser(identifier);
      if (userDoc == null || !userDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tài khoản không tồn tại')),
          );
        }
      } else {
        final data = userDoc.data();
        if (data != null && data['password'] == password) {
          final userRole = (data['role'] as String?) ?? 'Sinh viên';
          if (userRole != selectedRoleName) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Tài khoản thuộc vai trò "$userRole", không phải "$selectedRoleName"',
                  ),
                ),
              );
            }
            return;
          }

          if (mounted) {
            final routeEmail = (data['email'] as String?) ?? identifier;
            if (userRole == 'Sinh viên') {
              Navigator.of(context).pushReplacementNamed(
                '/dashboard',
                arguments: {'email': routeEmail, 'role': userRole},
              );
            } else {
              Navigator.of(context).pushReplacementNamed(
                '/manager-dashboard',
                arguments: {'email': routeEmail, 'role': userRole},
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Sai mật khẩu')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi đăng nhập: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'HỆ THỐNG QUẢN LÝ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () {},
          child: const Icon(Icons.arrow_back, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Đăng nhập',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hệ thống quản lý sinh viên đại học',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                const Text(
                  'CHỌN VAI TRÒ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade200,
                  ),
                  child: Row(
                    children: [
                      _roleButton('Sinh viên', 0),
                      _roleButton('Giảng viên', 1),
                      _roleButton('Quản trị', 2),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'TÊN ĐĂNG NHẬP / EMAIL',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                _buildInput(
                  controller: _emailController,
                  hintText: 'example@university.edu.vn',
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
                const Text(
                  'MẬT KHẨU',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                _buildInput(
                  controller: _passwordController,
                  hintText: '********',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Đăng nhập   →',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed('/register'),
                  child: const Text(
                    'Chưa có tài khoản? Đăng ký',
                    style: TextStyle(color: Colors.black87, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Colors.grey),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    _FooterIcon(label: 'BẢO MẬT', icon: Icons.shield_outlined),
                    _FooterIcon(
                      label: 'TIẾNG VIỆT',
                      icon: Icons.language_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '© 2026 SYNDRAYAKA CORP.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleButton(String label, int index) {
    final selected = selectedRole == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedRole = index),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 12,
        ),
      ),
    );
  }
}

class _FooterIcon extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FooterIcon({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
