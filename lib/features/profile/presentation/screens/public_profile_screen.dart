import 'package:flutter/material.dart';

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Profile'),
      ),
      body: const Center(
        child: Text('Public Profile Screen'),
      ),
    );
  }
}
