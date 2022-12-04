// import 'dart:async';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' show join;
// import 'package:yks_helper/extensions/list/filter.dart';
// import 'crud_exceptions.dart';

// //database operations
// class HelperService {
//   Database? _db;

//   List<DataBaseQuestions> _questions = [];

//   DataBaseUser? _user;

//   static final HelperService _shared = HelperService._sharedInstance();
//   HelperService._sharedInstance() {
//     _questionsStreamController =
//         StreamController<List<DataBaseQuestions>>.broadcast(
//       onListen: () {
//         _questionsStreamController.sink.add(_questions);
//       },
//     );
//   }
//   factory HelperService() => _shared;

//   late final StreamController<List<DataBaseQuestions>>
//       _questionsStreamController;

//   Stream<List<DataBaseQuestions>> get allNotes =>
//       _questionsStreamController.stream.filter((question));

//   Future<DataBaseUser> getOrCreateUser({
//     required String email,
//     bool setAsCurrentUser = true,
//   }) async {
//     try {
//       final user = await getUser(email: email);
//       if (setAsCurrentUser) {
//         _user = user;
//       }
//       return user;
//     } on CouldNotFindUserException {
//       final createdUser = await createUser(email: email);
//       if (setAsCurrentUser) {
//         _user = createdUser;
//       }
//       return createdUser;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> _cacheQuestions() async {
//     final allQuestions = await getAllQuestions();
//     _questions = allQuestions.toList();
//     _questionsStreamController.add(_questions);
//   }

//   Future<DataBaseQuestions> updateQuestion({
//     required DataBaseQuestions question,
//     required String text,
//   }) async {
//     await _ensureDbIsOpen();
//     final db = _getDataBaseOrThrow();

//     //make sure question exists
//     await getQuestion(id: question.id);

//     //update DB
//     final updatesCount = await db.update(
//         questionsTable,
//         {
//           textColumn: text,
//           isSyncedWithCloudColumn: 0,
//         },
//         where: 'id = ?',
//         whereArgs: [question.id]);

//     if (updatesCount == 0) throw CouldNotUpdateNoteException();
//     final updatedQuestion = await getQuestion(id: question.id);
//     _questions.removeWhere((question) => question.id == updatedQuestion.id);
//     _questions.add(updatedQuestion);
//     _questionsStreamController.add(_questions);
//     return updatedQuestion;
//   }

//   Future<Iterable<DataBaseQuestions>> getAllQuestions() async {
//     await _ensureDbIsOpen();
//     final db = _getDataBaseOrThrow();
//     List<Map<String, Object?>> questions;
//     questions = await db.query(questionsTable);

//     return questions
//         .map((questionsRow) => DataBaseQuestions.fromRow(questionsRow));
//   }

//   Future<DataBaseQuestions> getQuestion({required int id}) async {
//     final db = _getDataBaseOrThrow();
//     final question = await db.query(
//       questionsTable,
//       limit: 1,
//       where: 'id = ?',
//       whereArgs: [id],
//     );

//     if (question.isEmpty) throw CouldNotDeleteQuestionException();
//     final updateQuestion = DataBaseQuestions.fromRow(question.first);
//     _questions.removeWhere((newQuestion) => newQuestion.id == id);
//     _questions.add(updateQuestion);
//     _questionsStreamController.add(_questions);
//     return updateQuestion;
//   }

//   Future<int> deleteAllQuestions() async {
//     await _ensureDbIsOpen();
//     final db = _getDataBaseOrThrow();
//     final numberOfDeletions = await db.delete(questionsTable);
//     _questions = [];
//     _questionsStreamController.add(_questions);
//     return numberOfDeletions;
//   }

//   Future<void> deleteQuestion({required int id}) async {
//     await _ensureDbIsOpen();
//     final db = _getDataBaseOrThrow();
//     final deletedCount = await db.delete(
//       questionsTable,
//       where: 'id = ?',
//       whereArgs: [id],
//     );

//     if (deletedCount == 0) {
//       throw CouldNotDeleteQuestionException();
//     } else {
//       _questions.removeWhere((question) => question.id == id);
//       _questionsStreamController.add(_questions);
//     }
//   }

//   Future<DataBaseQuestions> createQuestion(
//       {required DataBaseUser owner}) async {
//     await _ensureDbIsOpen();
//     final db = _getDataBaseOrThrow();

//     //make sure owner exists in the db
//     final dbUser = await getUser(email: owner.email);
//     if (dbUser != owner) throw CouldNotFindUserException();

//     const text = '';
//     final questionId = await db
//         .insert(questionsTable, {textColumn: text, isSyncedWithCloudColumn: 1});

//     final question = DataBaseQuestions(
//       id: questionId,
//       text: text,
//       isSyncedWithCloud: true,
//     );

//     _questions.add(question);
//     _questionsStreamController.add(_questions);

//     return question;
//   }

//   Future<DataBaseUser> getUser({required String email}) async {
//     await _ensureDbIsOpen();
//     final db = _getDataBaseOrThrow();

//     final results = await db.query(
//       userTable,
//       limit: 1,
//       where: 'email = ?',
//       whereArgs: [email.toLowerCase()],
//     );

//     if (results.isEmpty) throw CouldNotFindUserException();

//     return DataBaseUser.fromRow(results.first);
//   }

//   Future<DataBaseUser> createUser({required String email}) async {
//     await _ensureDbIsOpen();
//     final db = _getDataBaseOrThrow();
//     final results = await db.query(
//       userTable,
//       limit: 1,
//       where: 'email = ?',
//       whereArgs: [email.toLowerCase()],
//     );
//     if (results.isNotEmpty) throw UserAlreadyExistsException();

//     final userId =
//         await db.insert(userTable, {emailColumn: email.toLowerCase()});

//     return DataBaseUser(id: userId, email: email);
//   }

//   Future<void> deleteUser({required String email}) async {
//     final db = _getDataBaseOrThrow();
//     final deletedCount = await db.delete(
//       userTable,
//       where: 'email = ?',
//       whereArgs: [email.toLowerCase()],
//     );
//     if (deletedCount != 1) throw CouldNotDeleteUserException();
//   }

//   Database _getDataBaseOrThrow() {
//     final db = _db;
//     if (db == null) {
//       throw DataBaseIsNotOpenException();
//     } else {
//       return db;
//     }
//   }

//   Future<void> close() async {
//     final db = _db;
//     if (db == null) {
//       throw DataBaseIsNotOpenException();
//     } else {
//       await db.close();
//       _db = null;
//     }
//   }

//   Future<void> _ensureDbIsOpen() async {
//     try {
//       await open();
//     } on DatabaseAlreadyOpenedException {
//       //empty
//     }
//   }

//   Future<void> open() async {
//     if (_db != null) throw DatabaseAlreadyOpenedException();
//     try {
//       final docsPath = await getApplicationDocumentsDirectory();
//       final dbPath = join(docsPath.path, dbName);
//       final db = await openDatabase(dbPath);
//       _db = db;
//       //create the user table
//       await db.execute(createUserTable);
//       //create the questions table
//       await db.execute(createQuestionsTable);
//       await _cacheQuestions();
//     } on MissingPlatformDirectoryException {
//       throw UnableToGetDocumentsDirectoryException();
//     }
//   }
// }

// //implementing user table
// @immutable
// class DataBaseUser {
//   final int id;
//   final String email;

//   const DataBaseUser({
//     required this.id,
//     required this.email,
//   });

//   DataBaseUser.fromRow(Map<String, Object?> map)
//       : id = map[idColumn] as int,
//         email = map[emailColumn] as String;

//   @override
//   String toString() => 'Person, id = $id, email = $email';

//   @override
//   bool operator ==(covariant DataBaseUser other) => id == other.id;

//   @override
//   int get hashCode => id.hashCode;
// }

// //implementing questions table
// class DataBaseQuestions {
//   final int id;
//   final String text;
//   final bool isSyncedWithCloud;

//   const DataBaseQuestions({
//     required this.id,
//     required this.text,
//     required this.isSyncedWithCloud,
//   });

//   DataBaseQuestions.fromRow(Map<String, Object?> map)
//       : id = map[idColumn] as int,
//         text = map[textColumn] as String,
//         isSyncedWithCloud =
//             (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;

//   @override
//   String toString() =>
//       'Questions, id = $id, isSyncedWithCloud = $isSyncedWithCloud, text = $text';

//   @override
//   bool operator ==(covariant DataBaseQuestions other) => id == other.id;

//   @override
//   int get hashCode => id.hashCode;
// }

// //constants
// const dbName = 'helper_data.db';
// const userTable = 'user';
// const questionsTable = 'questions';
// const idColumn = 'id';
// const emailColumn = 'email';
// const textColumn = 'text';
// const isSyncedWithCloudColumn = 'is_synced_with_cloud';
// const createUserTable = ''' CREATE TABLE IF NOT EXISTS "user" (
//         "id"	INTEGER NOT NULL,
//         "email"	TEXT NOT NULL,
//         PRIMARY KEY("id" AUTOINCREMENT)
//       ); ''';
// const createQuestionsTable = ''' CREATE TABLE IF NOT EXISTS "questions" (
//         "id"	INTEGER NOT NULL,
//         "is_synced_with_cloud"	INTEGER,
//         "text"	TEXT,
//         PRIMARY KEY("id" AUTOINCREMENT)
//       ); ''';
