import 'package:flutter/material.dart';
import '../models/auth_manager.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final auth = AuthManager();
    if (_isLogin) {
      auth.login(_emailController.text, _passwordController.text);
    } else {
      auth.signup(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
      );
    }

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            height: size.height,
            width: size.width,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Responsive Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500), // Constraint for TV/Laptop
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
                        ),
                        child: const Icon(Icons.shopping_bag_rounded, size: 60, color: Color(0xFF1565C0)),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'MINI E-STORE',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                      ),
                      const SizedBox(height: 40),
                      
                      // Auth Card
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 10,
                        child: Padding(
                          padding: const EdgeInsets.all(25.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                Text(
                                  _isLogin ? 'Welcome Back' : 'Create Account',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 30),
                                
                                if (!_isLogin) ...[
                                  _buildTextField(
                                    controller: _nameController,
                                    label: 'Full Name',
                                    icon: Icons.person_outline,
                                    validator: (v) => v!.isEmpty ? 'Enter name' : null,
                                  ),
                                  const SizedBox(height: 15),
                                ],
                                
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'Email Address',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) => !v!.contains('@') ? 'Invalid email' : null,
                                ),
                                const SizedBox(height: 15),
                                
                                if (!_isLogin) ...[
                                  _buildTextField(
                                    controller: _phoneController,
                                    label: 'Phone Number',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    validator: (v) => v!.isEmpty ? 'Enter phone' : null,
                                  ),
                                  const SizedBox(height: 15),
                                ],
                                
                                _buildTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
                                ),
                                const SizedBox(height: 30),
                                
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: _submit,
                                    child: Text(_isLogin ? 'LOGIN' : 'SIGN UP'),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
                                TextButton(
                                  onPressed: () => setState(() => _isLogin = !_isLogin),
                                  child: Text(_isLogin ? "Don't have an account? Sign Up" : "Already have an account? Login"),
                                ),
                              ],
                            ),
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      validator: validator,
    );
  }
}
