import 'package:flutter/material.dart';

class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('TODO: Session $id')),
    );
  }
}
