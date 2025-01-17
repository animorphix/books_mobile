import 'package:flutter/material.dart';
import 'package:flutter_books_app/services/nyt/nyt_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nytBooksProvider.notifier).loadBooks();
    });
  }

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _onLogin() async {
    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.login(
      _emailController.text,
      _passwordController.text,
    );

    final authState = ref.read(authProvider);
    if (authState.token != null && authState.error == null) {
      // Успешно, переходим на домашнюю
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error ?? 'а'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (authState.isLoading) const LinearProgressIndicator(),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                
                filled: true,
                hintStyle: TextStyle(color: Colors.grey[800]),
                hintText: "Логин",
                fillColor: const Color.fromARGB(255, 253, 238, 255),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                hintStyle: TextStyle(color: Colors.grey[800]),
                hintText: "Пароль",
                fillColor: const Color.fromARGB(255, 253, 238, 255),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: authState.isLoading ? null : _onLogin,
              child: const Text('Войти'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/signup');
              },
              child: const Text('Нет аккаунта? Зарегистрироваться'),
            )
          ],
        ),
      ),
    );
  }
}
