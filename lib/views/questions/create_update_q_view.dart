import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yks_helper/extensions/buildcontext/loc.dart';
import 'package:yks_helper/services/auth/auth_service.dart';
import 'package:yks_helper/utilities/generics/get_arguments.dart';
import 'package:yks_helper/services/cloud/cloud_question.dart';
import 'package:yks_helper/services/cloud/firebase_cloud_storage.dart';

import '../../utilities/dialogs/cannot_share_empty_q_dialog.dart';

class CreateUpdateQuestionView extends StatefulWidget {
  const CreateUpdateQuestionView({super.key});

  @override
  State<CreateUpdateQuestionView> createState() =>
      _CreateUpdateQuestionViewState();
}

class _CreateUpdateQuestionViewState extends State<CreateUpdateQuestionView> {
  CloudQuestion? _question;
  late final FirebaseCloudStorage _helperService;
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    _helperService = FirebaseCloudStorage();
    _textEditingController = TextEditingController();
    super.initState();
  }

  void _textControllerListener() async {
    final question = _question;
    if (question == null) {
      return;
    }

    final text = _textEditingController.text;
    await _helperService.updateQuestions(
      documentId: question.documentId,
      text: text,
    );
  }

  void _setupTextControllerListener() {
    _textEditingController.removeListener(_textControllerListener);
    _textEditingController.addListener(_textControllerListener);
  }

  Future<CloudQuestion> createOrGetQuestion(BuildContext context) async {
    //get question if passed down to update
    final widgetQuestion = context.getArgument<CloudQuestion>();
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
    final userId = currentUser.id;
    final newQuestion =
        await _helperService.createNewQuestion(ownerUserId: userId);
    _question = newQuestion;
    return newQuestion;
  }

  void _deleteQuestionIfTextIsEmpty() {
    final question = _question;
    if (_textEditingController.text.isEmpty && question != null) {
      _helperService.deleteQuestion(documentId: question.documentId);
    }
  }

  void _saveNoteIfTextNotEmpty() async {
    final question = _question;
    final text = _textEditingController.text;
    if (question != null && text.isNotEmpty) {
      await _helperService.updateQuestions(
        documentId: question.documentId,
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
        title: Text(context.loc.note),
        actions: [
          IconButton(
            onPressed: () async {
              final text = _textEditingController.text;
              if (_question == null || text.isEmpty) {
                await showCannotShareEmptyQuestionsDialog(context);
              } else {
                Share.share(text);
              }
            },
            icon: const Icon(Icons.share),
          ),
        ],
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
                decoration: InputDecoration(
                  hintText: context.loc.start_typing_your_note,
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
