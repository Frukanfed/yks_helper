import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show ReadContext;
import 'package:yks_helper/constants/routes.dart';
import 'package:yks_helper/extensions/buildcontext/loc.dart';
import 'package:yks_helper/services/auth/auth_service.dart';
import 'package:yks_helper/services/auth/bloc/auth_bloc.dart';
import 'package:yks_helper/services/auth/bloc/auth_events.dart';
import 'package:yks_helper/services/cloud/cloud_question.dart';
import 'package:yks_helper/services/cloud/firebase_cloud_storage.dart';
import 'package:yks_helper/views/questions/questions_list_view.dart';
import '../enums/menu_action.dart';
import '../utilities//dialogs/logout_dialog.dart';

extension Count<T extends Iterable> on Stream<T> {
  Stream<int> get getLength => map((event) => event.length);
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final FirebaseCloudStorage _helperService;
  String get userId => AuthService.firebase().currentUser!.id;

  @override
  void initState() {
    _helperService = FirebaseCloudStorage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: StreamBuilder<Object>(
              stream:
                  _helperService.allQuestions(ownerUserId: userId).getLength,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final noteCount = snapshot.data ?? 0;
                  return Text(context.loc.notes_title(noteCount as int));
                } else {
                  return const Text('');
                }
              }),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed(createOrUpdateQuestionRoute);
              },
              icon: const Icon(Icons.add),
            ),
            PopupMenuButton<MenuAction>(
              onSelected: (value) async {
                switch (value) {
                  case MenuAction.logout:
                    final shouldLogOut = await showLogoutDialog(context);
                    if (shouldLogOut) {
                      if (!mounted) return;
                      context.read<AuthBloc>().add(const AuthEventLogOut());
                    }
                    break;
                }
              },
              itemBuilder: (context) {
                return [
                  PopupMenuItem<MenuAction>(
                      value: MenuAction.logout,
                      child: Text(context.loc.logout_button))
                ];
              },
            )
          ],
        ),
        body: StreamBuilder(
          stream: _helperService.allQuestions(ownerUserId: userId),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
              case ConnectionState.active:
                if (snapshot.hasData) {
                  final allQuestions = snapshot.data as Iterable<CloudQuestion>;
                  return QuestionsListView(
                    questions: allQuestions,
                    onDeleteQuestion: (question) async {
                      await _helperService.deleteQuestion(
                          documentId: question.documentId);
                    },
                    onTap: (question) {
                      Navigator.of(context).pushNamed(
                        createOrUpdateQuestionRoute,
                        arguments: question,
                      );
                    },
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              default:
                return const CircularProgressIndicator();
            }
          },
        ));
  }
}
