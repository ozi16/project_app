import 'package:flutter/material.dart';

class LaporanBug extends StatefulWidget {
  const LaporanBug({super.key});

  @override
  State<LaporanBug> createState() => _LaporanBugState();
}

class _LaporanBugState extends State<LaporanBug> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lapor Bug Page'),
      ),
      body: const Center(
        child: Text('This is the Lapor Bug Page'),
      ),
    );
  }
}