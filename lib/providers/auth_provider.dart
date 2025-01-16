import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

// Класс состояния авторизации
class AuthState {
  final bool isLoading;
  final String? token;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.token,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    String? token,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    // При старте приложения пробуем вычитать токен из локального хранилища
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');
    if (savedToken != null) {
      state = state.copyWith(token: savedToken);
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await ApiService.signUp(email: email, password: password);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final token = decoded['status']['token'];
        state = state.copyWith(isLoading: false, token: token);

        // Сохраняем токен в SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Ошибка регистрации: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка: $e',
      );
    }
  }

  Future<void> login(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await ApiService.login(email: email, password: password);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final token = decoded['status']['token'];

        state = state.copyWith(isLoading: false, token: token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Ошибка входа: ${response.statusCode}',
        );
      }
    } catch (e) {
      state =  state.copyWith(isLoading: false, error: 'Ошибка: $e');
    }
  }

  Future<void> logout() async {
    if (state.token == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await ApiService.logout(token: state.token!);

      if (response.statusCode == 200) {
        // Удаляем токен
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');

        state = const AuthState(isLoading: false, token: null);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Ошибка выхода: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Ошибка: $e');
    }
  }
}

// Провайдер, который будет использоваться в приложении
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
