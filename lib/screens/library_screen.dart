// screens/library_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_books_app/providers/reading_status_provider.dart';
import 'package:flutter_books_app/services/nyt/nyt_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryBookData {
  final ReadingStatus status; 
  NytBook? book;            

  _LibraryBookData(this.status, this.book);
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool isLoading = false;
  String? error;

  // Локальный список, где для каждого статуса лежит
  // (ReadingStatus, + опциональный NytBook)
  List<_LibraryBookData> _libraryBooks = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLibrary();
    });
  }

  Future<void> _loadLibrary() async {
    setState(() {
      isLoading = true;
      error = null;
    });


    await ref.read(readingStatusProvider.notifier).fetchReadingStatuses();
    final readingStatusState = ref.read(readingStatusProvider);

    if (readingStatusState.error != null) {
      // Ошибка при загрузке статусов
      setState(() {
        error = readingStatusState.error;
        isLoading = false;
      });
      return;
    }

    // 2) Для каждого статуса делаем запрос к NYT
    final statuses = readingStatusState.statuses;
    final tmpLibrary = <_LibraryBookData>[];

    // Запросы можно делать либо последовательно, либо параллельно (Future.wait).
    // Если статусов много, будем параллелить через Future.wait:
    final futures = statuses.map((s) async {
      // Попробуем найти книгу по s.isbn
      try {
        final fetched = await NytService.fetchBookByIsbn(s.isbn);
        tmpLibrary.add(_LibraryBookData(s, fetched));
      } catch (e) {
        // Если ошибка - всё равно добавим запись, но book = null
        tmpLibrary.add(_LibraryBookData(s, null));
      }
    }).toList();

    await Future.wait(futures);

    // 3) Обновляем стейт
    setState(() {
      _libraryBooks = tmpLibrary;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final readingStatusState = ref.watch(readingStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Моя библиотека'),
      ),
      body: Column(
        children: [
          if (isLoading) const LinearProgressIndicator(),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Ошибка: $error', style: const TextStyle(color: Colors.red)),
            ),

          // Покажем если чтение статусов без ошибок, но вдруг 0 книг
          if (!isLoading && _libraryBooks.isEmpty && error == null)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('В вашей библиотеке нет книг.'),
            ),

          Expanded(
            child: ListView.builder(
              itemCount: _libraryBooks.length,
              itemBuilder: (context, index) {
                final item = _libraryBooks[index];
                final status = item.status;
                final book = item.book;

                // Если NYT ничего не вернул - показываем ISBN и статус
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
                  // У нас есть данные из NYT
                  // В history.json чаще всего нет book_image => book.imageUrl = ''
                  // тогда придётся показывать заглушку
                  final imageWidget = book.imageUrl.isNotEmpty
                      ? Image.network(book.imageUrl, width: 50, fit: BoxFit.cover)
                      : const SizedBox(width: 50, child: Icon(Icons.book));

                  return ListTile(
                    leading: imageWidget,
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
}
