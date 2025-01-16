import 'package:flutter/material.dart';
import 'package:flutter_books_app/providers/reading_status_provider.dart';
import 'package:flutter_books_app/services/nyt/nyt_provider.dart';
import 'package:flutter_books_app/services/nyt/nyt_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(readingStatusProvider.notifier).fetchReadingStatuses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final readingStatusState = ref.watch(readingStatusProvider);
    final nytBooksState = ref.watch(nytBooksProvider);
    final statuses = readingStatusState.statuses;

    // Будем отображать книги по статусам
    return Scaffold(
      appBar: AppBar(
        title: const Text('Моя библиотека'),
      ),
      body: Column(
        children: [
          if (readingStatusState.isLoading || nytBooksState.isLoading)
            const LinearProgressIndicator(),
          if (readingStatusState.error != null)
            Text(
              readingStatusState.error!,
              style: const TextStyle(color: Colors.red),
            ),
          if (nytBooksState.error != null)
            Text(
              nytBooksState.error!,
              style: const TextStyle(color: Colors.red),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: statuses.length,
              itemBuilder: (context, index) {
                final status = statuses[index];
                final NytBook? book =
                    _findBookByIsbn(nytBooksState.books, status.isbn);

                if (book == null) {
                  return ListTile(
                    title: Text('ISBN: ${status.isbn} (неизвестная книга)'),
                    subtitle: Text('Статус: ${status.status}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        ref
                            .read(readingStatusProvider.notifier)
                            .deleteStatus(status.id);
                      },
                    ),
                  );
                } else {
                  return ListTile(
                    leading: book.imageUrl.isNotEmpty
                        ? Image.network(
                            book.imageUrl,
                            width: 50,
                            fit: BoxFit.cover,
                          )
                        : const SizedBox(width: 50),
                    title: Text(book.title),
                    subtitle: Text('${book.author}\nСтатус: ${status.status}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        ref
                            .read(readingStatusProvider.notifier)
                            .deleteStatus(status.id);
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  NytBook? _findBookByIsbn(List<NytBook> books, String isbn) {
    for (final b in books) {
      if (b.primaryIsbn13 == isbn || b.primaryIsbn10 == isbn) {
        return b;
      }
    }
    return null;
  }
}
