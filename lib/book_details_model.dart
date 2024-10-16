import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_frits_lib/class/Books.dart'; // Assuming Book class is defined
import 'dart:convert'; // For jsonEncode

class BookDetailsWidget extends StatelessWidget {
  final Book book;
  final Dio dio = Dio();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  BookDetailsWidget({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFDDCF),
        title: Text(book.title),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Return to the previous screen
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.title,
              style: const TextStyle(
                fontFamily: 'Inter Tight',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF454242),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Author: ${book.authorName}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                color: Color(0xFF454242),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ISBN: ${book.isbn}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                color: Color(0xFF454242),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Genres: ${book.genres is List ? (book.genres as List).join(", ") : book.genres}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                color: Color(0xFF454242),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Available Copies: ${book.availableCopies}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                color: Color(0xFF454242),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Provider: ${book.providerName ?? "Unknown"}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                color: Color(0xFF454242),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _checkSessionAndReserve(context, book.bookID);
              },
              child: const Text('Reserve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF454242),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Check session and reserve book
  Future<void> _checkSessionAndReserve(BuildContext context, int bookId) async {
    String? sessionToken = await storage.read(key: 'session_token');

    if (sessionToken == null) {
      // No session token, prompt login/register
      _showLoginRegisterDialog(context);
    } else {
      // Session exists, proceed with reservation logic
      await _reserveBook(sessionToken, bookId, context);
    }
  }

  Future<void> _reserveBook(
      String userId, int bookId, BuildContext context) async {
    try {
      final _data = {
        'user_id': userId,
        'book_id': bookId,
      };

      // Convert _data to a JSON string
      final formData = FormData.fromMap({
        'operation': 'reserveBook',
        'json': jsonEncode(
            _data), // Use jsonEncode to encode the data as a JSON string
      });

      final response = await dio.post(
        'http://localhost/library_api/php/books.php', // Your API URL
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      // Handle the response
      if (response.statusCode == 200 && response.data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Book reserved successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reserve the book.')),
        );
      }
    } catch (error) {
      print('Error reserving book: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while reserving the book.')),
      );
    }
  }

  // Show login/register dialog if the session token is missing
  void _showLoginRegisterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Required'),
          content: const Text(
              'You need to log in or register to reserve this book.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Login'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(
                    context, '/login'); // Navigate to login page
              },
            ),
            TextButton(
              child: const Text('Register'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(
                    context, '/register'); // Navigate to register page
              },
            ),
          ],
        );
      },
    );
  }
}
