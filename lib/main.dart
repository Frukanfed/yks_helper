import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yks_helper/constants/routes.dart';
import 'package:yks_helper/services/auth/bloc/auth_bloc.dart';
import 'package:yks_helper/services/auth/bloc/auth_events.dart';
import 'package:yks_helper/services/auth/bloc/auth_state.dart';
import 'package:yks_helper/services/auth/firebase_auth_provider.dart';
import 'package:yks_helper/views/login_view.dart';
import 'package:yks_helper/views/questions/create_update_q_view.dart';
import 'package:yks_helper/views/verify_email_view.dart';
import 'views/register_view.dart';
import 'views/home_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      primarySwatch: Colors.brown,
    ),
    home: BlocProvider<AuthBloc>(
      create: (context) => AuthBloc(FirebaseAuthProvider()),
      child: const HomePage(),
    ),
    routes: {
      loginRoute: (context) => const LoginView(),
      registerRoute: (context) => const RegisterView(),
      homeRoute: (context) => const HomeView(),
      verifyEmailRoute: (context) => const VerifyEmailView(),
      createOrUpdateQuestionRoute: (context) =>
          const CreateUpdateQuestionView(),
    },
  ));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<AuthBloc>().add(const AuthEventInitialize());
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthStateLoggedIn) {
          return const HomeView();
        } else if (state is AuthStateNeedsVerification) {
          return const VerifyEmailView();
        } else if (state is AuthStateLoggedOut) {
          return const LoginView();
        } else {
          return const Scaffold(
            body: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
