// providers/comment_provider.dart
import 'dart:convert';
import 'package:flutter_books_app/providers/auth_provider.dart';
import 'package:flutter_books_app/services/book_comment_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentsState {
  final bool isLoading;
  final List<CommentModel> userComments;
  final String? error;
  final List<CommentModel>? bookComments;

  CommentsState({
    this.isLoading = false,
    this.userComments = const [],
    this.error,
    this.bookComments,
  });

  CommentsState copyWith({
    bool? isLoading,
    List<CommentModel>? userComments,
    String? error,
    List<CommentModel>? bookComments,
  }) {
    return CommentsState(
      isLoading: isLoading ?? this.isLoading,
      userComments: userComments ?? this.userComments,
      bookComments: bookComments ?? this.bookComments,
      error: error,
    );
  }
}

class CommentNotifier extends StateNotifier<CommentsState> {
  CommentNotifier(this.ref) : super(CommentsState());

  final Ref ref;

  // Загрузить все комментарии текущего юзера
  Future<void> fetchComments() async {
    final token = ref.read(authProvider).token;
    if (token == null) {
      state = state.copyWith(error: 'Нет токена (не авторизован)');
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await CommentService.getUserComments(token: token);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List;
        final list = decoded.map((e) => CommentModel.fromJson(e)).toList();
        state = state.copyWith(isLoading: false, userComments: list);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Ошибка при загрузке комментариев: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  // Создать комментарий
  Future<void> createComment(String isbn, String content) async {
    final token = ref.read(authProvider).token;
    if (token == null) {
      state = state.copyWith(error: 'Нет токена (не авторизован)');
      return;
    }
    try {
      final response = await CommentService.createComment(
        token: token,
        isbn: isbn,
        content: content,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // После успешного создания - снова грузим список
        await fetchBookComments(isbn);
      } else {
        state = state.copyWith(
          error: 'Ошибка при создании комментария: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(error: '$e');
    }
  }

  // Получить комментарии к одной книге
  Future<void> fetchBookComments(String isbn) async {
    final token = ref.read(authProvider).token;
    if (token == null) {
      state = state.copyWith(error: 'Нет токена (не авторизован)');
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await CommentService.getBookComments(
        token: token,
        isbn: isbn,
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List;
        final list = decoded.map((e) => CommentModel.fromJson(e)).toList();
        state = state.copyWith(isLoading: false, bookComments: list);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Ошибка при загрузке комментариев: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  // Обновить комментарий
  Future<void> updateComment(int commentId, String newContent) async {
    final token = ref.read(authProvider).token;
    if (token == null) {
      state = state.copyWith(error: 'Нет токена (не авторизован)');
      return;
    }
    try {
      final response = await CommentService.updateComment(
        token: token,
        commentId: commentId,
        newContent: newContent,
      );
      if (response.statusCode == 200) {
        await fetchComments();
      } else {
        state = state.copyWith(
          error: 'Ошибка при обновлении комментария: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(error: '$e');
    }
  }

  // Удалить комментарий
  Future<void> deleteComment(int commentId) async {
    final token = ref.read(authProvider).token;
    if (token == null) {
      state = state.copyWith(error: 'Нет токена (не авторизован)');
      return;
    }
    try {
      final response = await CommentService.deleteComment(
        token: token,
        commentId: commentId,
      );
      if (response.statusCode == 204) {
        await fetchComments();
      } else {
        state = state.copyWith(
          error: 'Ошибка при удалении комментария: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(error: '$e');
    }
  }
}

final commentProvider = StateNotifierProvider<CommentNotifier, CommentsState>(
  (ref) => CommentNotifier(ref),
);
