import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yks_helper/services/auth/bloc/auth_bloc.dart';
import 'package:yks_helper/services/auth/bloc/auth_events.dart';
import 'package:yks_helper/services/auth/bloc/auth_state.dart';
import 'package:yks_helper/utilities/dialogs/error_dialog.dart';
import 'package:yks_helper/utilities/dialogs/password_reset_email_sent_dialog.dart';

class ForgetPasswordView extends StatefulWidget {
  const ForgetPasswordView({super.key});

  @override
  State<ForgetPasswordView> createState() => _ForgetPasswordViewState();
}

class _ForgetPasswordViewState extends State<ForgetPasswordView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthStateForgetPassword) {
          if (state.hasSentEmail) {
            _controller.clear();
            await showPasswordResetEmailSentDialog(context);
          }
          if (state.exception != null) {
            if (!mounted) return;
            await showErrorDialog(context, 'We could not process your request');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Password Reset'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                  'If you forget your password, simply enter your email and we will send you a reser mail.'),
              TextField(
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofocus: true,
                controller: _controller,
                decoration: const InputDecoration(hintText: 'Email'),
              ),
              TextButton(
                onPressed: () {
                  final email = _controller.text;
                  context.read<AuthBloc>().add(AuthEventForgetPassword(email));
                },
                child: const Text('Send email'),
              ),
              TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthEventLogOut());
                },
                child: const Text('Back to login view'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
