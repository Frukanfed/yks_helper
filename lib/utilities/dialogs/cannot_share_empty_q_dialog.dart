import 'package:flutter/cupertino.dart';
import 'package:yks_helper/utilities/dialogs/generic_dialog.dart';

Future<void> showCannotShareEmptyQuestionsDialog(BuildContext context) {
  return showGenericDialog<void>(
    context: context,
    title: 'Sharing',
    content: 'You can not share an empty note!',
    optionBuilder: () => {
      'OK': null,
    },
  );
}
