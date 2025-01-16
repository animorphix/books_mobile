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
  final List<String> _possibleStatuses = ['not read', 'reading', 'read'];

  String? _currentStatus;
  int? _readingStatusId;

  late final String _isbnForStatus;

  bool _isLoadingStatus = false;

  @override
  void initState() {
    super.initState();

    _isbnForStatus = widget.book.primaryIsbn13.isNotEmpty
        ? widget.book.primaryIsbn13
        : widget.book.primaryIsbn10;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatus();
    });
  }

  Future<void> _loadStatus() async {
  setState(() => _isLoadingStatus = true);

  try {

    await ref.read(readingStatusProvider.notifier).fetchReadingStatuses();

    final statuses = ref.read(readingStatusProvider).statuses;

    final found = statuses.firstWhere(
      (s) => s.isbn == _isbnForStatus,
      orElse: () => null as dynamic,
    );

    _readingStatusId = found.id;
    _currentStatus = found.status;
    } catch (e) {
    debugPrint('Ошибка при загрузке статуса: $e');
  } finally {
    setState(() => _isLoadingStatus = false);
  }
}


  Future<void> _onStatusChanged(String? newValue) async {
    if (newValue == null) return;

    setState(() => _currentStatus = newValue);

    if (_readingStatusId != null) {
      await ref.read(readingStatusProvider.notifier).updateStatus(_readingStatusId!, newValue);
    } else {
      await ref.read(readingStatusProvider.notifier).createStatus(_isbnForStatus, newValue);
    }
    await _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Обложка
            if (widget.book.imageUrl.isNotEmpty)
              Image.network(
                widget.book.imageUrl,
                height: 300,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 16),
            // Название
            Text(
              widget.book.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            // Автор
            const SizedBox(height: 8),
            Text(
              'by ${widget.book.author}',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            // Издатель
            const SizedBox(height: 8),
            Text(
              'Издательство: ${widget.book.publisher}',
              style: const TextStyle(fontSize: 14),
            ),
            // Описание
            const SizedBox(height: 16),
            Text(
              widget.book.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (authState.token != null) ...[
              const Text(
                'Мой статус чтения:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (_isLoadingStatus)
                const CircularProgressIndicator()
              else
                DropdownButton<String>(
                  value: _currentStatus,
                  hint: const Text('Выберите статус'),
                  items: _possibleStatuses.map((st) {
                    return DropdownMenuItem<String>(
                      value: st,
                      child: Text(st),
                    );
                  }).toList(),
                  onChanged: (newVal) => _onStatusChanged(newVal),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
