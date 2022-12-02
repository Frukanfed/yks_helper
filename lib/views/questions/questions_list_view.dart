import 'package:flutter/material.dart';
import 'package:yks_helper/services/crud/yks_service.dart';
import '../../utilities/dialogs/delete_dialog.dart';

typedef QuestionCallback = void Function(DataBaseQuestions question);

class QuestionsListView extends StatelessWidget {
  final List<DataBaseQuestions> questions;
  final QuestionCallback onDeleteQuestion;
  final QuestionCallback onTap;

  const QuestionsListView({
    super.key,
    required this.questions,
    required this.onDeleteQuestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return ListTile(
          onTap: () {
            onTap(question);
          },
          title: Text(
            question.text,
            maxLines: 1,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            onPressed: () async {
              final shouldDelete = await showDeleteDialog(context);
              if (shouldDelete) onDeleteQuestion(question);
            },
            icon: const Icon(Icons.delete),
          ),
        );
      },
    );
  }
}
