import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_frits_lib/borrow_page_model.dart';
import 'package:flutter_frits_lib/class/Books.dart';
import 'package:flutter_frits_lib/reserve_page_model.dart' as reservePageModel;
import 'book_details_model.dart';
import 'reserve_page_model.dart'
    as reservePage; // Import the reserve page with a prefix

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late TextEditingController _textController;
  late FocusNode _textFieldFocusNode;

  Dio dio = Dio();
  List<Book> books = [];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _textFieldFocusNode = FocusNode();

    fetchBooks(); // Fetch books on init
  }

  Future<void> fetchBooks() async {
    try {
      final response = await dio.post(
        'http://localhost/library_api/php/books.php',
        data: {'operation': 'fetchBooks'},
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      // Check if the response data is a List and map it to Book objects
      List<dynamic> responseData = response.data;
      List<Book> fetchedBooks = responseData
          .map((bookJson) => Book.fromJson(bookJson as Map<String, dynamic>))
          .toList();

      setState(() {
        books = fetchedBooks;
      });
    } catch (error) {
      print('Error fetching books: $error');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            print('FloatingActionButton pressed ...');
          },
          backgroundColor: const Color(0xFF454242),
          elevation: 8,
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        endDrawer: Drawer(
          elevation: 16,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.bookmark),
                title: Text('Reserved Books'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => reservePageModel
                          .ReservedBooks(), // Navigate to reserve page
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.menu_book_sharp),
                title: Text('Borrowed Books'),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BorrowedBooksPage()));
                },
              ),
            ],
          ),
        ),
        body: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              pinned: false,
              floating: true,
              snap: false,
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              automaticallyImplyLeading: false,
              title: Text(
                'Frit\'s Library',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontFamily: 'Inter Tight',
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://picsum.photos/id/115/600',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              centerTitle: false,
              elevation: 2,
            )
          ],
          body: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    height: 200, // Example for a carousel
                    color: Colors.grey.shade300,
                    child:
                        const Center(child: Text("Book Carousel Placeholder")),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Container(
                            width: 200,
                            child: TextFormField(
                              controller: _textController,
                              focusNode: _textFieldFocusNode,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Search for a book',
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade400,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.blue.shade400,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFEFDDCF),
                              ),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(2),
                        child: IconButton(
                          icon: const Icon(Icons.search),
                          color: Colors.blue.shade400,
                          onPressed: () {
                            print('Search button pressed ...');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookDetailsWidget(
                                  book: book, // Passing the Book object
                                ),
                              ),
                            );
                          },
                          child: Card(
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            color: Theme.of(context).colorScheme.tertiary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(book.title),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
