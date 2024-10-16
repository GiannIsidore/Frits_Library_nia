import 'dart:convert'; // To handle jsonEncode
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Book {
  final int reservationID;
  final int bookID;
  final String title;
  final String authorName;
  final String reservationDate;
  final String expirationDate;
  final String statusName;
  final String isbn;
  final String publicationDate;
  final String providerName;

  Book({
    required this.reservationID,
    required this.bookID,
    required this.title,
    required this.authorName,
    required this.reservationDate,
    required this.expirationDate,
    required this.statusName,
    required this.isbn,
    required this.publicationDate,
    required this.providerName,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      reservationID: json['ReservationID'],
      bookID: json['BookID'],
      title: json['Title'],
      authorName: json['AuthorName'],
      reservationDate: json['ReservationDate'],
      expirationDate: json['ExpirationDate'],
      statusName: json['StatusName'],
      isbn: json['ISBN'],
      publicationDate: json['PublicationDate'],
      providerName: json['ProviderName'] ?? "Unknown",
    );
  }
}

class ReservedBooks extends StatefulWidget {
  @override
  _ReservedBooksState createState() => _ReservedBooksState();
}

class _ReservedBooksState extends State<ReservedBooks> {
  final Dio dio = Dio();
  final FlutterSecureStorage storage = FlutterSecureStorage();
  bool loading = true;
  String? error;
  List<Book> reservedBooks = [];
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

        // After fetching session, fetch reserved books
        fetchReservedBooks();
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

  Future<void> fetchReservedBooks() async {
    if (userId == null || userType == null) return;

    try {
      setState(() {
        loading = true;
      });

      FormData formData = FormData.fromMap({
        'operation': 'fetchReservedBooks',
        if (userType == "Registered User")
          'json': jsonEncode({'user_id': userId}),
      });

      final response = await dio.post(
        'http://localhost/library_api/php/books.php', // Replace with your API URL
        data: formData,
      );

      if (response.statusCode == 200 && response.data['success']) {
        List<dynamic> booksJson = response.data['reserved_books'];
        List<Book> fetchedBooks =
            booksJson.map((json) => Book.fromJson(json)).toList();
        setState(() {
          reservedBooks = fetchedBooks;
        });
      } else {
        setState(() {
          error = 'Failed to fetch reserved books.';
        });
      }
    } catch (e) {
      setState(() {
        error = 'An error occurred.';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> handleBorrow(int bookId, int reservationID) async {
    try {
      FormData formData = FormData.fromMap({
        'operation': 'borrowBook',
        'json': jsonEncode({
          'user_id': userId,
          'reservation_id': reservationID,
        }),
      });

      final response = await dio.post(
        'http://localhost/library_api/php/books.php', // Replace with your API URL
        data: formData,
      );

      if (response.statusCode == 200 && response.data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Book borrowed successfully!')));
        // Optionally refresh the list of reserved books after borrowing
        fetchReservedBooks();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to borrow the book.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('An error occurred.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text(error!));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Reserved Books'),
      ),
      body: reservedBooks.isNotEmpty
          ? ListView.builder(
              itemCount: reservedBooks.length,
              itemBuilder: (context, index) {
                final book = reservedBooks[index];
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
                        Text('Reserved Date: ${book.reservationDate}'),
                        Text('Expiration Date: ${book.expirationDate}'),
                        Text('Status: ${book.statusName}'),
                        SizedBox(height: 8),
                        if (book.statusName == 'Available')
                          ElevatedButton(
                            onPressed: () =>
                                handleBorrow(book.bookID, book.reservationID),
                            child: Text('Borrow'),
                          )
                        else
                          ElevatedButton(
                            onPressed: null,
                            child: Text('Pending'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            )
          : Center(
              child: Text('You don\'t have any reserved books at the moment.'),
            ),
    );
  }
}
