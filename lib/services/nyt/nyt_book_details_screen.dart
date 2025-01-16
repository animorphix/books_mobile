import 'package:flutter/material.dart';
import 'package:flutter_books_app/providers/auth_provider.dart';
import 'package:flutter_books_app/providers/book_comments_provider.dart';
import 'package:flutter_books_app/providers/reading_status_provider.dart';
import 'package:flutter_books_app/services/nyt/nyt_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NytBookDetailsScreen extends ConsumerStatefulWidget {
  final NytBook book;

  const NytBookDetailsScreen({Key? key, required this.book}) : super(key: key);

  @override
  ConsumerState<NytBookDetailsScreen> createState() =>
      _NytBookDetailsScreenState();
}

class _NytBookDetailsScreenState extends ConsumerState<NytBookDetailsScreen> {
  final List<String> _possibleStatuses = ['not read', 'reading', 'read'];
  String? _currentStatus;
  int? _readingStatusId;
  final _commentController = TextEditingController();
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
      ref.read(commentProvider.notifier).fetchComments();
    });
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoadingStatus = true);

    try {
      await ref.read(readingStatusProvider.notifier).fetchReadingStatuses();
      final st = ref.read(readingStatusProvider);
      final found = st.statuses.firstWhere(
        (s) => s.isbn == _isbnForStatus,
        orElse: () => null as dynamic,
      );
      _readingStatusId = found.id;
      _currentStatus = found.status;
    } finally {
      setState(() => _isLoadingStatus = false);
    }
  }

  Future<void> _onStatusChanged(String? newValue) async {
    if (newValue == null) return;
    setState(() => _currentStatus = newValue);

    if (_readingStatusId != null) {
      await ref
          .read(readingStatusProvider.notifier)
          .updateStatus(_readingStatusId!, newValue);
    } else {
      await ref
          .read(readingStatusProvider.notifier)
          .createStatus(_isbnForStatus, newValue);
    }
    await _loadStatus();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    await ref
        .read(commentProvider.notifier)
        .createComment(_isbnForStatus, text);
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    final commentsState = ref.watch(commentProvider);
    final myComments =
        commentsState.comments.where((c) => c.isbn == _isbnForStatus).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
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
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                    return DropdownMenuItem(value: st, child: Text(st));
                  }).toList(),
                  onChanged: _onStatusChanged,
                ),
            ],

            const SizedBox(height: 24),
            if (commentsState.isLoading) const LinearProgressIndicator(),
            const Text(
              'Комментарии:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (myComments.isEmpty) const Text('Нет комментариев'),
            for (final c in myComments)
              ListTile(
                title: Text(c.userId.toString()),
                subtitle: Text(c.content),
                // Если хотим дать возможность редактировать — придётся делать кнопки
                // trailing: IconButton(... update/delete ...),
              ),

            // Форма отправки нового комментария
            if (authState.token != null) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Оставьте комментарий...',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _sendComment,
                child: const Text('Отправить'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
