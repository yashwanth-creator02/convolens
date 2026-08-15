import 'package:flutter/material.dart';

import 'main_shell.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConvoLens',
      debugShowCheckedModeBanner: false,
      home: const MainShell(),
    );
  }
}
