import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized().scheduleFrameCallback((_) {
    print('Hello, Flutter!');
    windowManager.ensureInitialized().then((_) {
      Timer(const Duration(milliseconds: 500), () => windowManager.close());
    });
  });

  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('flutter-snap')),
      body: const Center(child: Text('Hello, Flutter!')),
    ),
  ));
}
