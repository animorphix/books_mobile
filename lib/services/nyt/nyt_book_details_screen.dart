import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
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
  final List<String> _possibleStatuses = ['хочу прочитать', 'читаю', 'прочитал'];
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
      ref.refresh(commentProvider.notifier).fetchBookComments(_isbnForStatus);
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
    } catch (e) {
      _currentStatus = null;
      log(e.toString());
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
    final myComments = commentsState.bookComments;

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
              Row(
                children: [
                  const Text(
                    'Статус:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  _isLoadingStatus
                      ? const CircularProgressIndicator()
                      : Container(
                          height: 40,
                          padding: EdgeInsets.all(5.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: Colors.grey,
                              style: BorderStyle.solid,
                              width: 0.80,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton2(
                              dropdownStyleData: DropdownStyleData(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              value: _currentStatus,
                              hint: const Text('Выберите статус'),
                              items: _possibleStatuses.map((st) {
                                return DropdownMenuItem(
                                    value: st, child: Text(st));
                              }).toList(),
                              onChanged: _onStatusChanged,
                            ),
                          ),
                        ),
                ],
              ),
            ],

            const SizedBox(height: 24),
            if (commentsState.isLoading) const LinearProgressIndicator(),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Комментарии:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, ),
              ),
            ),
            const SizedBox(height: 16),

            if (myComments?.isEmpty ?? true) Text('Пусто...', style: TextStyle(color: Colors.grey.shade400),),
            for (final c in myComments ?? [])


                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        
                        leading: const CircleAvatar(),
                        iconColor: Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        tileColor: Colors.grey.shade100,
                        title: Text(c.isFromCurrentUser ? 'Я' : c.user_email.toString()),
                        subtitle: Text(c.content),
                        // Если хотим дать возможность редактировать — придётся делать кнопки
                        // trailing: IconButton(... update/delete ...),
                      ),
                    ),
                  
            // Форма отправки нового комментария
            if (authState.token != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 16),
                  Flexible(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Оставьте комментарий...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      //maxLines: null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                    child: IconButton(
                      onPressed: _sendComment,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}
