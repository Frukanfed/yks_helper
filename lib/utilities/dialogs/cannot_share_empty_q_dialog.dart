import 'package:flutter/cupertino.dart';
import 'package:yks_helper/extensions/buildcontext/loc.dart';
import 'package:yks_helper/utilities/dialogs/generic_dialog.dart';

Future<void> showCannotShareEmptyQuestionsDialog(BuildContext context) {
  return showGenericDialog<void>(
    context: context,
    title: context.loc.sharing,
    content: context.loc.cannot_share_empty_note_prompt,
    optionBuilder: () => {
      context.loc.ok: null,
    },
  );
}
