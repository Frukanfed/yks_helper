import 'package:flutter/cupertino.dart';
import 'package:yks_helper/utilities/dialogs/generic_dialog.dart';

Future<bool> showLogoutDialog(BuildContext context) {
  return showGenericDialog<bool>(
    context: context,
    title: 'Logout',
    content: 'Are you sure you want to logout?',
    optionBuilder: () => {
      'Cancel': false,
      'Log Out': true,
    },
  ).then(
    (value) => value ?? false,
  );
}
