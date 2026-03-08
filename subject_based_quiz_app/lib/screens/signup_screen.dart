import 'dart:ui';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool obscure = true;
  bool isLoading = false;

  void signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      // Simple Authentication simulation
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );

      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4e73df), Color(0xFF1cc88a)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withAlpha(77),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Sign up to get started",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 30),

                        /// Full Name
                        TextFormField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration("Full Name", Icons.person),
                          validator: (value) => value!.isEmpty ? "Enter your name" : null,
                        ),
                        const SizedBox(height: 20),

                        /// Email
                        TextFormField(
                          controller: emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration("Email", Icons.email),
                          validator: (value) {
                            if (value == null || value.isEmpty) return "Enter email";
                            if (!value.contains("@")) return "Invalid email";
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        /// Password
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscure,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration("Password", Icons.lock, isPassword: true),
                          validator: (value) => value!.length < 6 ? "Password must be 6+ characters" : null,
                        ),
                        const SizedBox(height: 20),

                        /// Confirm Password
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: obscure,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration("Confirm Password", Icons.lock_clock, isPassword: true),
                          validator: (value) {
                            if (value != passwordController.text) return "Passwords do not match";
                            return null;
                          },
                        ),
                        const SizedBox(height: 25),

                        /// Signup Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : signup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.black)
                                : const Text("Sign Up", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Already have an account? Login", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon, {bool isPassword = false}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withAlpha(51),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off, color: Colors.white),
              onPressed: () => setState(() => obscure = !obscure),
            )
          : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    );
  }
}