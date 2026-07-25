import 'package:flutter/material.dart';
import 'IndiamapPage.dart';

void main() => runApp(const ElectionIntelApp());

class ElectionIntelApp extends StatelessWidget {
  const ElectionIntelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'India Election Intelligence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1E3A8A),
        useMaterial3: true,
      ),
      home: const IndiaMapPage(),
    );
  }
}