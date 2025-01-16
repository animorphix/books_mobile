import 'package:flutter/material.dart';
import 'package:flutter_books_app/providers/auth_provider.dart';
import 'package:flutter_books_app/services/nyt/nyt_book_details_screen.dart';
import 'package:flutter_books_app/services/nyt/nyt_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool isLoading = false;
  String? error;
  List<NytBook> books = [];

  @override
  void initState() {
    super.initState();
    _fetchNytBooks(); // При старте грузим NYT
  }

  Future<void> _fetchNytBooks() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      // Запрашиваем бестселлеры от NYTimes
      final result = await NytService.fetchBestSellerBooks(
        listName: 'hardcover-fiction',
      );
      setState(() {
        books = result;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.logout();

    final authState = ref.read(authProvider);
    if (authState.token == null) {
      // Если логаут успешен — уходим на экран логина
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Домашняя страница'),
        actions: [
          if (!authState.isLoading)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _logout,
            ),
        ],
      ),
      body: Column(
        children: [
          if (isLoading) const LinearProgressIndicator(),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Ошибка: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return ListTile(
                  leading: book.imageUrl.isNotEmpty
                      ? Image.network(
                          book.imageUrl,
                          width: 50,
                          fit: BoxFit.cover,
                        )
                      : const SizedBox(width: 50),
                  title: Text(book.title),
                  subtitle: Text(book.author),
                  onTap: () {
                    // При нажатии - переход на детальную страницу
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
      // Два FAB: переход в библиотеку + (условно) переход на отдельный экран NYT
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'library',
            onPressed: () {
              Navigator.pushNamed(context, '/library');
            },
            child: const Icon(Icons.library_books),
          ),
          // const SizedBox(height: 16),
          // FloatingActionButton(
          //   heroTag: 'nyt',
          //   onPressed: () {
          //     Navigator.pushNamed(context, '/nyt_books');
          //   },
          //   child: const Icon(Icons.book),
          // ),
        ],
      ),
    );
  }
}
