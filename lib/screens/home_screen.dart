import 'package:flutter/material.dart';
import 'package:flutter_books_app/providers/auth_provider.dart';
import 'package:flutter_books_app/services/nyt/nyt_book_details_screen.dart';
import 'package:flutter_books_app/services/nyt/nyt_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final nytState = ref.watch(nytBooksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Рекомендации'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_4_rounded),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            color: Colors.grey.shade700,
          ),
        ],
      ),
      body: Column(
        children: [
          if (nytState.isLoading) const LinearProgressIndicator(),
          if (nytState.error != null)
            Text(
              'Ошибка: ${nytState.error}',
              style: const TextStyle(color: Colors.red),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: nytState.books.length,
              itemBuilder: (context, index) {
                final book = nytState.books[index];
                return ListTile(
                  leading: book.imageUrl.isNotEmpty
                      ? Image.network(book.imageUrl,
                          width: 50, fit: BoxFit.cover)
                      : const SizedBox(width: 50),
                  title: Text(book.title),
                  subtitle: Text(book.author),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NytBookDetailsScreen(book: book),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'library',
            onPressed: () {
              Navigator.pushNamed(context, '/library');
            },
            child: Icon(
              Icons.library_books,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
