import 'package:flutter/material.dart';
import 'package:yks_helper/constants/routes.dart';
import 'package:yks_helper/services/auth/auth_service.dart';
import 'package:yks_helper/services/crud/yks_service.dart';
import 'package:yks_helper/views/questions/questions_list_view.dart';
import '../enums/menu_action.dart';
import '../utilities//dialogs/logout_dialog.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HelperService _helperService;
  String get userEmail => AuthService.firebase().currentUser!.email!;

  @override
  void initState() {
    _helperService = HelperService();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Soruların'),
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
                      await AuthService.firebase().logOut();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        loginRoute,
                        (_) => false,
                      );
                    }
                    break;
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem<MenuAction>(
                      value: MenuAction.logout, child: Text('Log Out'))
                ];
              },
            )
          ],
        ),
        body: FutureBuilder(
          future: _helperService.getOrCreateUser(email: userEmail),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                return StreamBuilder(
                  stream: _helperService.allNotes,
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                      case ConnectionState.active:
                        if (snapshot.hasData) {
                          final allQuestions =
                              snapshot.data as List<DataBaseQuestions>;
                          return QuestionsListView(
                            questions: allQuestions,
                            onDeleteQuestion: (question) async {
                              await _helperService.deleteQuestion(
                                  id: question.id);
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
                );
              default:
                return const CircularProgressIndicator();
            }
          },
        ));
  }
}
