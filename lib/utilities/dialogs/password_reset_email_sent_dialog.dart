import 'package:flutter/cupertino.dart';
import 'package:yks_helper/utilities/dialogs/generic_dialog.dart';

Future<void> showPasswordResetEmailSentDialog(BuildContext context) {
  return showGenericDialog(
    context: context,
    title: 'Email Sent',
    content: 'We have now send you a password reset email.',
    optionBuilder: () => {
      'OK': null,
    },
  );
}
