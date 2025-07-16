import 'package:flutter/material.dart';

class DocumentsView extends StatelessWidget {
  const DocumentsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Welcome to Documents',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
} 