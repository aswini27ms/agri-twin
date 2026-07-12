import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main_navigation.dart';
import '../providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  void _handleGetStarted() async {
    setState(() { _isLoading = true; });
    final notifier = ref.read(userProfileProvider.notifier);
    await notifier.updateProfile(
      userName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Santhosh Kumar',
      farmName: 'Demo Farm 1',
      location: 'Local',
    );
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() { _isLoading = false; });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF008000),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF008000).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                  ]
                ),
                child: const Icon(Icons.eco_outlined, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                "Create Local Profile",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              const Text(
                "Access your offline farm intelligence",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 32),
              
              // Tabs
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F0E9), // Light green tint
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isLogin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: _isLogin ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                          ),
                          alignment: Alignment.center,
                          child: Text("Login", style: TextStyle(color: _isLogin ? Colors.black : Colors.black54, fontWeight: _isLogin ? FontWeight.w600 : FontWeight.w400)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !_isLogin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: !_isLogin ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                          ),
                          alignment: Alignment.center,
                          child: Text("Sign Up", style: TextStyle(color: !_isLogin ? Colors.black : Colors.black54, fontWeight: !_isLogin ? FontWeight.w600 : FontWeight.w400)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Inputs
              _buildInputRow(icon: Icons.person_outline, hint: "Farmer Name", controller: _nameController),
              const SizedBox(height: 16),
              _buildInputRow(icon: Icons.phone_outlined, hint: "Phone Number / ID", controller: _phoneController),
              const SizedBox(height: 16),
              _buildInputRow(icon: Icons.lock_outline, hint: "Security PIN (4 digits)", controller: _pinController, obscureText: true),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008000),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Get Started", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
              
              const SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text("OR SIGN IN WITH", style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.fingerprint, color: Color(0xFF008000)),
                  label: const Text("Fingerprint Scan", style: TextStyle(color: Color(0xFF008000), fontSize: 16, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF008000)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow({required IconData icon, required String hint, required TextEditingController controller, bool obscureText = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45),
          prefixIcon: Icon(icon, color: Colors.black54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
