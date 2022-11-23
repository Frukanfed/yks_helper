import 'package:flutter/material.dart';

class NewQuestionView extends StatefulWidget {
  const NewQuestionView({super.key});

  @override
  State<NewQuestionView> createState() => _NewQuestionViewState();
}

class _NewQuestionViewState extends State<NewQuestionView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Soru'),
      ),
      body: const Text('Soruyu buraya yazın.'),
    );
  }
}
