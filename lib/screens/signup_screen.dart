import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _onSignup() async {
    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.signUp(
      _emailController.text,
      _passwordController.text,
    );

    final authState = ref.read(authProvider);
    if (authState.token != null && authState.error == null) {
      // Успешно, переходим на домашнюю страницу
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Обработка ошибки, если нужно
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error ?? 'Ошибка регистрации'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (authState.isLoading) const LinearProgressIndicator(),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Пароль'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: authState.isLoading ? null : _onSignup,
              child: const Text('Зарегистрироваться'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Уже есть аккаунт? Войти'),
            )
          ],
        ),
      ),
    );
  }
}

