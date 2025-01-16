// providers/nyt_books_provider.dart
import 'package:flutter_books_app/services/nyt/nyt_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NytBooksState {
  final bool isLoading;
  final List<NytBook> books;
  final String? error;

  NytBooksState({
    this.isLoading = false,
    this.books = const [],
    this.error,
  });

  NytBooksState copyWith({
    bool? isLoading,
    List<NytBook>? books,
    String? error,
  }) {
    return NytBooksState(
      isLoading: isLoading ?? this.isLoading,
      books: books ?? this.books,
      error: error,
    );
  }
}

class NytBooksNotifier extends StateNotifier<NytBooksState> {
  NytBooksNotifier() : super(NytBooksState());

  /// Загрузка книг из NYT
  Future<void> loadBooks({String listName = 'hardcover-fiction'}) async {
    try {
      // Ставим флаг isLoading, убираем ошибку
      state = state.copyWith(isLoading: true, error: null);
      
      // Делаем запрос к NYT
      final fetched = await NytService.fetchBestSellerBooks(listName: listName);
      
      // Записываем в state
      state = state.copyWith(
        isLoading: false,
        books: fetched,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

// Провайдер, который будем использовать везде
final nytBooksProvider = 
  StateNotifierProvider<NytBooksNotifier, NytBooksState>((ref) {
  return NytBooksNotifier();
});
