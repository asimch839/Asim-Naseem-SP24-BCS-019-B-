import 'dart:ui';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscure = true;
  bool rememberMe = false;
  bool isLoading = false;

  void login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      // Simple Authentication simulation
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      setState(() => isLoading = false);

      Navigator.pushReplacementNamed(context, '/subjects');
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
                    color: Colors.white.withAlpha(38), // 0.15 * 255
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withAlpha(77), // 0.3 * 255
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/logo.jpg",
                          height: 100,
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Login to continue",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 30),

                        /// Email
                        TextFormField(
                          controller: emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withAlpha(51), // 0.2 * 255
                            hintText: "Email",
                            hintStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.email, color: Colors.white),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
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
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withAlpha(51), // 0.2 * 255
                            hintText: "Password",
                            hintStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.lock, color: Colors.white),
                            suffixIcon: IconButton(
                              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off, color: Colors.white),
                              onPressed: () => setState(() => obscure = !obscure),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) return "Password must be 6+ characters";
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        /// Remember Me
                        Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              activeColor: Colors.white,
                              checkColor: Colors.black,
                              onChanged: (value) => setState(() => rememberMe = value!),
                            ),
                            const Text("Remember Me", style: TextStyle(color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 25),

                        /// Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.black)
                                : const Text("Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account?", style: TextStyle(color: Colors.white)),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/signup'),
                              child: const Text("Sign Up", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
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
}