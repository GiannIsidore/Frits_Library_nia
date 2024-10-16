import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BorrowedBook {
  final int borrowID;
  final int bookID;
  final String title;
  final String authorName;
  final String name;
  final String borrowDate;
  final String? dueDate;
  final String? returnDate;
  final String statusName;
  final String isbn;
  final String publicationDate;
  final String providerName;

  BorrowedBook({
    required this.borrowID,
    required this.bookID,
    required this.title,
    required this.authorName,
    required this.name,
    required this.borrowDate,
    this.dueDate,
    this.returnDate,
    required this.statusName,
    required this.isbn,
    required this.publicationDate,
    required this.providerName,
  });

  factory BorrowedBook.fromJson(Map<String, dynamic> json) {
    return BorrowedBook(
      borrowID: json['BorrowID'],
      bookID: json['BookID'],
      title: json['Title'],
      authorName: json['AuthorName'],
      name: json['Name'],
      borrowDate: json['BorrowDate'],
      dueDate: json['DueDate'],
      returnDate: json['ReturnDate'],
      statusName: json['StatusName'],
      isbn: json['ISBN'],
      publicationDate: json['PublicationDate'],
      providerName: json['ProviderName'] ?? "Unknown",
    );
  }
}

class BorrowedBooksPage extends StatefulWidget {
  @override
  _BorrowedBooksPageState createState() => _BorrowedBooksPageState();
}

class _BorrowedBooksPageState extends State<BorrowedBooksPage> {
  final Dio dio = Dio();
  final FlutterSecureStorage storage = FlutterSecureStorage();
  bool loading = true;
  String? error;
  List<BorrowedBook> borrowedBooks = [];
  String? userType;
  int? userId;

  @override
  void initState() {
    super.initState();
    fetchSession();
  }

  // Fetch session data (user id and user type)
  Future<void> fetchSession() async {
    try {
      // Read user ID and user type from Flutter Secure Storage
      final storedUserId = await storage.read(key: 'session_user_id');
      final storedUserType = await storage.read(key: 'session_user_type');

      if (storedUserId != null && storedUserType != null) {
        setState(() {
          userId = int.tryParse(storedUserId);
          userType = storedUserType;
        });

        // After fetching session, fetch borrowed books
        fetchBorrowedBooks();
      } else {
        setState(() {
          loading = false;
          error = "No session found.";
        });
      }
    } catch (e) {
      setState(() {
        error = "Error fetching session.";
        loading = false;
      });
    }
  }

  Future<void> fetchBorrowedBooks() async {
    if (userId == null || userType == null) return;

    try {
      setState(() {
        loading = true;
      });

      FormData formData = FormData.fromMap({
        'operation': 'fetchBorrowedBooks',
        if (userType == "Registered User")
          'json': jsonEncode({'user_id': userId}),
      });

      final response = await dio.post(
        'http://localhost/library_api/php/books.php', // Replace with your API URL
        data: formData,
      );

      // Ensure the response data is parsed correctly
      if (response.statusCode == 200) {
        var responseData = response.data;

        // Check if 'success' is true and 'borrowed_books' exists
        if (responseData['success'] == true &&
            responseData['borrowed_books'] != null) {
          List<dynamic> booksJson = responseData['borrowed_books'];
          List<BorrowedBook> fetchedBooks =
              booksJson.map((json) => BorrowedBook.fromJson(json)).toList();
          setState(() {
            borrowedBooks = fetchedBooks;
          });
        } else {
          setState(() {
            error = 'Failed to fetch borrowed books.';
          });
        }
      } else {
        setState(() {
          error = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        error = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> handleReturn(int bookId) async {
    try {
      FormData formData = FormData.fromMap({
        'operation': 'returnBook',
        'json': jsonEncode({
          'user_id': userId,
          'book_id': bookId,
        }),
      });

      final response = await dio.post(
        'http://localhost/library_api/php/books.php', // Replace with your API URL
        data: formData,
      );

      if (response.statusCode == 200 && response.data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Book returned successfully!')));
        // Refresh the list after returning the book
        fetchBorrowedBooks();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to return the book.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('An error occurred.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Your Borrowed Books')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Your Borrowed Books')),
        body: Center(child: Text(error!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Borrowed Books'),
      ),
      body: borrowedBooks.isNotEmpty
          ? ListView.builder(
              itemCount: borrowedBooks.length,
              itemBuilder: (context, index) {
                final book = borrowedBooks[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text('Author: ${book.authorName}'),
                        Text('ISBN: ${book.isbn}'),
                        Text('Borrowed On: ${book.borrowDate}'),
                        Text('Due On: ${book.dueDate}'),
                        Text('Status: ${book.statusName}'),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => handleReturn(book.bookID),
                          child: Text('Return'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : Center(
              child: Text('You don\'t have any borrowed books at the moment.'),
            ),
    );
  }
}
