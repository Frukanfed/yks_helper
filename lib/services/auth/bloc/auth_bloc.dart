import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:yks_helper/services/auth/auth_provider.dart';
import 'package:yks_helper/services/auth/bloc/auth_events.dart';
import 'package:yks_helper/services/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthProvider provider)
      : super(const AuthStateUninitialized(isLoading: true)) {
    //forget password
    on<AuthEventForgetPassword>(
      (event, emit) async {
        emit(const AuthStateForgetPassword(
          exception: null,
          hasSentEmail: false,
          isLoading: false,
        ));
        final email = event.email;
        //if user just wants to go to forget email screen
        if (email == null) return;
        //if user wants to send forget password email
        emit(const AuthStateForgetPassword(
          exception: null,
          hasSentEmail: false,
          isLoading: true,
        ));

        //try to send password reset email in loading screen
        bool didSendEmail;
        Exception? exception;
        try {
          await provider.sendPasswordReset(toEmail: email);
          didSendEmail = true;
          exception = null;
        } on Exception catch (e) {
          didSendEmail = false;
          exception = e;
        }

        //end loading screen
        emit(AuthStateForgetPassword(
          exception: exception,
          hasSentEmail: didSendEmail,
          isLoading: false,
        ));
      },
    );
    //send email verification
    on<AuthEventSendEmailVerification>(
      (event, emit) async {
        await provider.sendEmailVerification();
        emit(state);
      },
    );
    //register user
    on<AuthEventRegister>((event, emit) async {
      final email = event.email;
      final password = event.password;
      try {
        await provider.createUser(
          email: email,
          password: password,
        );
        await provider.sendEmailVerification();
        emit(const AuthStateNeedsVerification(isLoading: false));
      } on Exception catch (e) {
        emit(AuthStateRegistering(exception: e, isLoading: false));
      }
    });
    //Go to register page
    on<AuthEventShouldRegister>((event, emit) async {
      emit(const AuthStateRegistering(exception: null, isLoading: false));
    });
    //initialize
    on<AuthEventInitialize>(
      (event, emit) async {
        await provider.initialize();
        final user = provider.currentUser;
        if (user == null) {
          emit(
            const AuthStateLoggedOut(
              exception: null,
              isLoading: false,
            ),
          );
        } else if (!user.isEmailVerified) {
          emit(const AuthStateNeedsVerification(isLoading: false));
        } else {
          emit(AuthStateLoggedIn(user: user, isLoading: false));
        }
      },
    );
    //login
    on<AuthEventLogIn>((event, emit) async {
      emit(
        const AuthStateLoggedOut(
          exception: null,
          isLoading: true,
          loadingText: 'Please wait while we log you in',
        ),
      );
      final email = event.email;
      final password = event.password;
      try {
        final user = await provider.logIn(
          email: email,
          password: password,
        );

        if (!user.isEmailVerified) {
          emit(
            const AuthStateLoggedOut(
              exception: null,
              isLoading: false,
            ),
          );
          emit(const AuthStateNeedsVerification(isLoading: false));
        } else {
          emit(
            const AuthStateLoggedOut(
              exception: null,
              isLoading: false,
            ),
          );
          emit(AuthStateLoggedIn(user: user, isLoading: false));
        }
      } on Exception catch (e) {
        emit(
          AuthStateLoggedOut(
            exception: e,
            isLoading: false,
          ),
        );
      }
    });
    //logout
    on<AuthEventLogOut>((event, emit) async {
      try {
        await provider.logOut();
        emit(
          const AuthStateLoggedOut(
            exception: null,
            isLoading: false,
          ),
        );
      } on Exception catch (e) {
        emit(
          AuthStateLoggedOut(
            exception: e,
            isLoading: false,
          ),
        );
      }
    });
  }
}
