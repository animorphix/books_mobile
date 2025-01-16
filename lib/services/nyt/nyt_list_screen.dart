import 'package:flutter/material.dart';
import 'package:flutter_books_app/services/nyt/nyt_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'nyt_book_details_screen.dart';

class NytBooksListScreen extends ConsumerStatefulWidget {
  const NytBooksListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NytBooksListScreen> createState() => _NytBooksListScreenState();
}

class _NytBooksListScreenState extends ConsumerState<NytBooksListScreen> {
  bool isLoading = false;
  String? error;
  List<NytBook> books = [];

  @override
  void initState() {
    super.initState();
    _loadNytBooks();
  }

  Future<void> _loadNytBooks() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final result = await NytService.fetchBestSellerBooks();
      setState(() {
        books = result;
      });
    } catch (e) {
      setState(() {
        error = '$e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NYT Best Sellers'),
      ),
      body: Column(
        children: [
          if (isLoading) const LinearProgressIndicator(),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Ошибка: $error', style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                final b = books[index];
                return ListTile(
                  leading: b.imageUrl.isNotEmpty
                      ? Image.network(
                          b.imageUrl,
                          width: 50,
                          fit: BoxFit.cover,
                        )
                      : const SizedBox(width: 50),
                  title: Text(b.title),
                  subtitle: Text(b.author),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NytBookDetailsScreen(book: b),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
