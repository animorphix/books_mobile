import 'package:flutter/material.dart';
import 'package:flutter_books_app/providers/auth_provider.dart';
import 'package:flutter_books_app/providers/reading_status_provider.dart';
import 'package:flutter_books_app/services/nyt/nyt_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NytBookDetailsScreen extends ConsumerStatefulWidget {
  final NytBook book;

  const NytBookDetailsScreen({Key? key, required this.book}) : super(key: key);

  @override
  ConsumerState<NytBookDetailsScreen> createState() => _NytBookDetailsScreenState();
}

class _NytBookDetailsScreenState extends ConsumerState<NytBookDetailsScreen> {
  // Возможные статусы
  final List<String> _possibleStatuses = ['not read', 'reading', 'read'];

  // Храним текущий статус
  String? _currentStatus;
  // Храним ID статуса в бэке (если существует)
  int? _readingStatusId;

  // Выберем, что использовать для ISBN (isbn13 или isbn10).
  late final String _isbnForStatus;

  @override
  void initState() {
    super.initState();
    // Допустим, в NytBook нет явного поля isbn13,
    // но обычно NYT отдает primary_isbn13 или что-то подобное.
    // Ниже - как пример, если у вас есть другое поле - подставьте его.
    _isbnForStatus = widget.book.primaryIsbn13.isNotEmpty
        ? widget.book.primaryIsbn13
        : widget.book.primaryIsbn10; // fallback

    // Сразу подгружаем статусы, если их ещё нет
    ref.read(readingStatusProvider.notifier).fetchReadingStatuses().then((_) {
      _initStatusFromProvider();
    });
  }

  // Найдём в провайдере, если уже есть статус для _isbnForStatus
  void _initStatusFromProvider() {
    final readingStatusState = ref.read(readingStatusProvider);
    final found = readingStatusState.statuses.firstWhere(
      (s) => s.isbn == _isbnForStatus,
      orElse: () => null as dynamic, // если ничего не нашли
    );
    if (found != null) {
      setState(() {
        _currentStatus = found.status;
        _readingStatusId = found.id;
      });
    }
  }

  // Вызывается при выборе нового статуса из Dropdown
  Future<void> _onStatusChanged(String? newValue) async {
    if (newValue == null) return;
    setState(() {
      _currentStatus = newValue;
    });
    // Если у нас уже есть запись статуса => PATCH
    // Если нет => POST
    if (_readingStatusId != null) {
      // PATCH
      await ref
          .read(readingStatusProvider.notifier)
          .updateStatus(_readingStatusId!, newValue);
    } else {
      // POST
      await ref
          .read(readingStatusProvider.notifier)
          .createStatus(_isbnForStatus, newValue);
    }
    // После обновления на бэке - перезагрузим локально
    await ref.read(readingStatusProvider.notifier).fetchReadingStatuses();
    // Обновим локальные поля (id, статус), если вдруг changed
    _initStatusFromProvider();
  }


  @override
  Widget build(BuildContext context) {
    // Можно отследить, нет ли токена, и если что - спрятать список статусов
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title, overflow: TextOverflow.ellipsis),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.book.imageUrl.isNotEmpty)
              Image.network(
                widget.book.imageUrl,
                height: 300,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 16),
            Text(
              widget.book.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'by ${widget.book.author}',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Издательство: ${widget.book.publisher}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              widget.book.description,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 16),

            // Dropdown со статусами (если пользователь авторизован)
            if (authState.token != null) ...[
              const Text(
                'Мой статус чтения:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              DropdownButton<String>(
                value: _currentStatus,
                hint: const Text('Выберите статус'),
                items: _possibleStatuses.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                // При выборе значения - либо создаём, либо обновляем статус
                onChanged: _onStatusChanged,
              ),
            ],

            // Кнопка Amazon
            if (widget.book.amazonLink.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (){},
                child: const Text('Посмотреть на Amazon'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
