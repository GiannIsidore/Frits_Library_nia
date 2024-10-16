class Book {
  final int bookID;
  final String title;
  final String authorName;
  final dynamic genres; // Can be String or List<String>
  final String isbn;
  final String? providerName;
  final String publicationDate;
  final int totalCopies; // Optional field
  final String availableCopies;

  Book({
    required this.bookID,
    required this.title,
    required this.authorName,
    required this.genres,
    required this.isbn,
    this.providerName,
    required this.publicationDate,
    required this.totalCopies,
    required this.availableCopies,
  });

  // Factory method to create a Book object from a JSON map
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      bookID: json['BookID'],
      title: json['Title'],
      authorName: json['AuthorName'],
      genres: json['Genres'],
      isbn: json['ISBN'],
      providerName: json['ProviderName'],
      publicationDate: json['PublicationDate'],
      totalCopies: json['TotalCopies'],
      availableCopies: json['AvailableCopies'],
    );
  }

  get imageUrl => null;

  // Method to convert Book object back to JSON map
  Map<String, dynamic> toJson() {
    return {
      'BookID': bookID,
      'Title': title,
      'AuthorName': authorName,
      'Genres': genres,
      'ISBN': isbn,
      'ProviderName': providerName,
      'PublicationDate': publicationDate,
      'TotalCopies': totalCopies,
      'AvailableCopies': availableCopies,
    };
  }
}
