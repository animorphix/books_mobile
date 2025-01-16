import 'package:flutter/material.dart';
import 'package:flutter_books_app/screens/home_screen.dart';
import 'package:flutter_books_app/screens/library_screen.dart';
import 'package:flutter_books_app/screens/login_screen.dart';
import 'package:flutter_books_app/screens/signup_screen.dart';
import 'package:flutter_books_app/services/nyt/nyt_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Books App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/library': (context) => const LibraryScreen(),
        '/nyt_books': (context) => const NytBooksListScreen(),
      },
    );
  }
}
