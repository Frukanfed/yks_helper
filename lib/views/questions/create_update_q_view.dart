import 'package:flutter/material.dart';
import 'package:yks_helper/services/auth/auth_service.dart';
import 'package:yks_helper/services/crud/yks_service.dart';
import 'package:yks_helper/utilities/generics/get_arguments.dart';

class CreateUpdateQuestionView extends StatefulWidget {
  const CreateUpdateQuestionView({super.key});

  @override
  State<CreateUpdateQuestionView> createState() =>
      _CreateUpdateQuestionViewState();
}

class _CreateUpdateQuestionViewState extends State<CreateUpdateQuestionView> {
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

  Future<DataBaseQuestions> createOrGetQuestion(BuildContext context) async {
    //get question if passed down to update
    final widgetQuestion = context.getArgument<DataBaseQuestions>();
    if (widgetQuestion != null) {
      _question = widgetQuestion;
      _textEditingController.text = widgetQuestion.text;
      return widgetQuestion;
    }

    final existingQuestion = _question;
    // if there is already a question, return it
    if (existingQuestion != null) {
      return existingQuestion;
    }
    // if not, make a new one
    final currentUser = AuthService.firebase().currentUser!;
    final email = currentUser.email!;
    final owner = await _helperService.getUser(email: email);
    final newQuestion = await _helperService.createQuestion(owner: owner);
    _question = newQuestion;
    return newQuestion;
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
        future: createOrGetQuestion(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
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