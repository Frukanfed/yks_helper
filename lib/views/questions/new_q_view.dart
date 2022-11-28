import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:yks_helper/services/auth/auth_service.dart';
import 'package:yks_helper/services/crud/yks_service.dart';

class NewQuestionView extends StatefulWidget {
  const NewQuestionView({super.key});

  @override
  State<NewQuestionView> createState() => _NewQuestionViewState();
}

class _NewQuestionViewState extends State<NewQuestionView> {
  DataBaseQuestions? _question;
  late final HelperService _helperService;
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    _helperService = HelperService();
    _textEditingController = TextEditingController();
    super.initState();
  }

  void _textControllerListener() async {
    final question = _question;
    if (question == null) {
      return;
    }

    final text = _textEditingController.text;
    await _helperService.updateQuestion(
      question: question,
      text: text,
    );
  }

  void _setupTextControllerListener() {
    _textEditingController.removeListener(_textControllerListener);
    _textEditingController.addListener(_textControllerListener);
  }

  Future<DataBaseQuestions> createQuestion() async {
    final existingQuestion = _question;
    // if there is already a question, return it
    if (existingQuestion != null) {
      return existingQuestion;
    }
    // if not, make a new one
    final currentUser = AuthService.firebase().currentUser!;
    final email = currentUser.email!;
    final owner = await _helperService.getUser(email: email);
    return await _helperService.createQuestion(owner: owner);
  }

  void _deleteQuestionIfTextIsEmpty() {
    final question = _question;
    if (_textEditingController.text.isEmpty && question != null) {
      _helperService.deleteQuestion(id: question.id);
    }
  }

  void _saveNoteIfTextNotEmpty() async {
    final question = _question;
    final text = _textEditingController.text;
    if (question != null && text.isNotEmpty) {
      await _helperService.updateQuestion(
        question: question,
        text: text,
      );
    }
  }

  @override
  void dispose() {
    _deleteQuestionIfTextIsEmpty();
    _saveNoteIfTextNotEmpty();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Soru'),
      ),
      body: FutureBuilder(
        future: createQuestion(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              // ignore: unnecessary_cast
              _question = snapshot.data as DataBaseQuestions?;
              _setupTextControllerListener();
              return TextField(
                controller: _textEditingController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Soruyu buraya yazabilirsiniz.',
                ),
              );
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
