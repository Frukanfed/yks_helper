import 'package:flutter/cupertino.dart';
import 'package:yks_helper/utilities/dialogs/generic_dialog.dart';

Future<bool> showDeleteDialog(BuildContext context) {
  return showGenericDialog<bool>(
    context: context,
    title: 'Delete',
    content: 'Are you sure you want to delete this question?',
    optionBuilder: () => {
      'Cancel': false,
      'Delete': true,
    },
  ).then((value) => value ?? false);
}
