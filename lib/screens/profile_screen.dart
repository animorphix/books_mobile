import 'package:flutter/material.dart';
import 'package:flutter_books_app/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _logout() async {
    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.logout();

    final authState = ref.read(authProvider);
    if (authState.token == null) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_)=> false);
    }
  }

  Future<void> _dialogBuilder(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выйти из аккаунта?'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Отменить'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Выйти'),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text('Скоро появятся еще кнопки'),
            const SizedBox(height: 16),
            IconButton(
              onPressed:() => _dialogBuilder(context),
              icon: const Icon(Icons.logout),
            )
          ],
        ),
      ),
    );
  }
}
