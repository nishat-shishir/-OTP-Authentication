import 'package:flutter/material.dart';
import 'pages/create-form.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove debug banner
      initialRoute: '/create-form',
      routes: {
        '/create-form': (context) => CreateUserPage(),
      },
    );
  }
}
