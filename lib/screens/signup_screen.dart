import "package:flutter/material.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "package:flutter_notes/screens/home_screen.dart";
import "package:flutter_notes/screens/signin_screen.dart";

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();
        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );

        if (mounted) {
          if (response.user?.identities?.isEmpty ?? true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Sign Up successful! Please check your email for confirmation.",
                ),
              ),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Sign Up Successful!")),
            );

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Sign Up Failed: ${e.message}")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("An unexpected error occurred: $e")),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains("@")) {
                    return "Please enter a valid email";
                  }
                  return null;
                },
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 6) {
                    return "Password must be at least 6 characters";
                  }
                  return null;
                },
                keyboardType: TextInputType.visiblePassword,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please confirm your password";
                  }
                  if (value != _passwordController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
                keyboardType: TextInputType.visiblePassword,
              ),
              const SizedBox(height: 24.0),
              FilledButton(
                onPressed: _isLoading ? null : _signUp,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                        : const Text("Sign Up"),
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed:
                    () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const SignInScreen(),
                      ),
                    ),
                child: const Text("Already have an account? Sign In"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
