import 'dart:convert'; // For jsonEncode
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final Dio dio = Dio();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  bool isSubmitting = false;
  String? errorMessage;

  Future<void> _handleLogin(BuildContext context) async {
    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    try {
      // Use jsonEncode to properly encode the 'json' field
      final response = await dio.post(
        'http://localhost/library_api/php/users.php',
        data: {
          'operation': 'login',
          'json': jsonEncode({
            'email': _emailController.text,
            'password': _passwordController.text,
          }),
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      // Handle the response data and store the session token
      if (response.data['user'] != null) {
        final user = response.data['user']; // Extract user info from response
        final userId = user['user_id'].toString(); // Extract user ID
        final userType = user['role']; // Extract user role

        // Save session data
        await storage.write(
            key: 'session_token',
            value: userId); // Save user_id as session token
        await storage.write(
            key: 'session_user_id', value: userId); // Save user_id separately
        await storage.write(
            key: 'session_user_type', value: userType); // Save user type/role

        // Navigate to the homepage (or the desired page)
        Navigator.pushReplacementNamed(
            context, '/homepage'); // Replace with your route
      } else {
        setState(() {
          errorMessage = response.data['message'] ?? 'Login failed';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 16),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isSubmitting ? null : () => _handleLogin(context),
                child: isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
