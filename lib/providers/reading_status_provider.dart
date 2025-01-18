import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class ReadingStatus {
  final int id;
  final int userId;
  final String isbn;
  final String status;

  ReadingStatus({
    required this.id,
    required this.userId,
    required this.isbn,
    required this.status,
  });

  factory ReadingStatus.fromJson(Map<String, dynamic> json) {
    return ReadingStatus(
      id: json['id'],
      userId: json['user_id'],
      isbn: json['isbn'],
      status: json['status'],
    );
  }
}

// Состояние провайдера
class ReadingStatusState {
  final bool isLoading;
  final List<ReadingStatus> statuses;
  final String? error;

  ReadingStatusState({
    this.isLoading = false,
    this.statuses = const [],
    this.error,
  });

  ReadingStatusState copyWith({
    bool? isLoading,
    List<ReadingStatus>? statuses,
    String? error,
  }) {
    return ReadingStatusState(
      isLoading: isLoading ?? this.isLoading,
      statuses: statuses ?? this.statuses,
      error: error,
    );
  }
}

class ReadingStatusNotifier extends StateNotifier<ReadingStatusState> {
  ReadingStatusNotifier(this.ref) : super(ReadingStatusState());

  final Ref ref;

  // Получить все статусы для текущего пользователя
  Future<void> fetchReadingStatuses() async {
    final token = ref.read(authProvider).token;
    if (token == null) {
      state = state.copyWith(error: 'Пользователь не авторизован.');
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await ApiService.getReadingStatuses(token: token);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List list = decoded;
        final statuses = list
            .map((json) => ReadingStatus.fromJson(json))
            .toList()
            .cast<ReadingStatus>();
        state = state.copyWith(isLoading: false, statuses: statuses);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Ошибка получения статусов: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Ошибка: $e');
    }
  }

  // Создать статус
  Future<void> createStatus(String isbn, String statusStr) async {
    final token = ref.read(authProvider).token;
    if (token == null) {
      state = state.copyWith(error: 'Пользователь не авторизован.');
      return;
    }

    try {
      final response = await ApiService.createReadingStatus(
        token: token,
        isbn: isbn,
        status: statusStr,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchReadingStatuses();
      } else {
        state = state.copyWith(
          error: 'Ошибка создания статуса: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Ошибка: $e');
    }
  }

  // Обновить статус
  Future<void> updateStatus(int statusId, String newStatus) async {
    final token = ref.read(authProvider).token;
    if (token == null) {
      state = state.copyWith(error: 'Пользователь не авторизован.');
      return;
    }

    try {
      final response = await ApiService.updateReadingStatus(
        token: token,
        statusId: statusId,
        newStatus: newStatus,
      );
      if (response.statusCode == 200) {
        await fetchReadingStatuses();
      } else {
        state = state.copyWith(
          error: 'Ошибка обновления статуса: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Ошибка: $e');
    }
  }

  // Удалить статус
  Future<void> deleteStatus(int statusId) async {
    final token = ref.read(authProvider).token;
    if (token == null) {
      state = state.copyWith(error: 'Пользователь не авторизован.');
      return;
    }

    try {
      final response = await ApiService.deleteReadingStatus(
        token: token,
        statusId: statusId,
      );
      if (response.statusCode == 204) {
        await fetchReadingStatuses();
      } else {
        state = state.copyWith(
          error: 'Ошибка удаления статуса: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Ошибка: $e');
    }
  }
}

final readingStatusProvider =
    StateNotifierProvider<ReadingStatusNotifier, ReadingStatusState>(
        (ref) => ReadingStatusNotifier(ref));
