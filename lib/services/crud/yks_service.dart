import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:yks_helper/extensions/list/filter.dart';

import 'crud_exceptions.dart';

class HelperService {
  Database? _db;

  List<DataBaseQuestions> _questions = [];

  DatabaseUser? _user;

  static final HelperService _shared = HelperService._sharedInstance();
  HelperService._sharedInstance() {
    _questionsStreamController =
        StreamController<List<DataBaseQuestions>>.broadcast(
      onListen: () {
        _questionsStreamController.sink.add(_questions);
      },
    );
  }
  factory HelperService() => _shared;

  late final StreamController<List<DataBaseQuestions>>
      _questionsStreamController;

  Stream<List<DataBaseQuestions>> get allQuestions =>
      _questionsStreamController.stream.filter((question) {
        final currentUser = _user;
        if (currentUser != null) {
          return question.userId == currentUser.id;
        } else {
          throw UserShouldBeSetBeforeReadingAllQuestionsException();
        }
      });

  Future<DatabaseUser> getOrCreateUser({
    required String email,
    bool setAsCurrentUser = true,
  }) async {
    try {
      final user = await getUser(email: email);
      if (setAsCurrentUser) {
        _user = user;
      }
      return user;
    } on CouldNotFindUserException {
      final createdUser = await createUser(email: email);
      if (setAsCurrentUser) {
        _user = createdUser;
      }
      return createdUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _cacheQuestions() async {
    final allQuestions = await getAllQuestions();
    _questions = allQuestions.toList();
    _questionsStreamController.add(_questions);
  }

  Future<DataBaseQuestions> updateQuestion({
    required DataBaseQuestions question,
    required String text,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // make sure question exists
    await getQuestion(id: question.id);

    // update DB
    final updatesCount = await db.update(
      questionsTable,
      {
        textColumn: text,
        isSyncedWithCloudColumn: 0,
      },
      where: 'id = ?',
      whereArgs: [question.id],
    );

    if (updatesCount == 0) {
      throw CouldNotUpdateQuestionException();
    } else {
      final updatedQuestion = await getQuestion(id: question.id);
      _questions.removeWhere((question) => question.id == updatedQuestion.id);
      _questions.add(updatedQuestion);
      _questionsStreamController.add(_questions);
      return updatedQuestion;
    }
  }

  Future<Iterable<DataBaseQuestions>> getAllQuestions() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final questions = await db.query(questionsTable);

    return questions
        .map((questionRow) => DataBaseQuestions.fromRow(questionRow));
  }

  Future<DataBaseQuestions> getQuestion({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final questions = await db.query(
      questionsTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (questions.isEmpty) {
      throw CouldNotFindQuestionException();
    } else {
      final question = DataBaseQuestions.fromRow(questions.first);
      _questions.removeWhere((question) => question.id == id);
      _questions.add(question);
      _questionsStreamController.add(_questions);
      return question;
    }
  }

  Future<int> deleteAllQuestions() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(questionsTable);
    _questions = [];
    _questionsStreamController.add(_questions);
    return numberOfDeletions;
  }

  Future<void> deleteQuestion({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      questionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw CouldNotDeleteQuestionException();
    } else {
      _questions.removeWhere((question) => question.id == id);
      _questionsStreamController.add(_questions);
    }
  }

  Future<DataBaseQuestions> createQuestion(
      {required DatabaseUser owner}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // make sure owner exists in the database with the correct id
    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) {
      throw CouldNotFindUserException();
    }

    const text = '';
    // create the question
    final questionId = await db.insert(questionsTable, {
      userIdColumn: owner.id,
      textColumn: text,
      isSyncedWithCloudColumn: 1,
    });

    final question = DataBaseQuestions(
      id: questionId,
      userId: owner.id,
      text: text,
      isSyncedWithCloud: true,
    );

    _questions.add(question);
    _questionsStreamController.add(_questions);

    return question;
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (results.isEmpty) {
      throw CouldNotFindUserException();
    } else {
      return DatabaseUser.fromRow(results.first);
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) {
      throw UserAlreadyExistsException();
    }

    final userId = await db.insert(userTable, {
      emailColumn: email.toLowerCase(),
    });

    return DatabaseUser(
      id: userId,
      email: email,
    );
  }

  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteQuestionException();
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DataBaseIsNotOpenException();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DataBaseIsNotOpenException();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenedException {
      // empty
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenedException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;
      // create the user table
      await db.execute(createUserTable);
      // create question table
      await db.execute(createQuestionsTable);
      await _cacheQuestions();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectoryException();
    }
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;
  const DatabaseUser({
    required this.id,
    required this.email,
  });

  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() => 'Person, ID = $id, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DataBaseQuestions {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;

  DataBaseQuestions({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithCloud,
  });

  DataBaseQuestions.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        text = map[textColumn] as String,
        isSyncedWithCloud =
            (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;

  @override
  String toString() =>
      'Question, ID = $id, userId = $userId, isSyncedWithCloud = $isSyncedWithCloud, text = $text';

  @override
  bool operator ==(covariant DataBaseQuestions other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

//constants
const dbName = 'helper_data.db';
const questionsTable = 'questions';
const userTable = 'user';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColumn = 'text';
const isSyncedWithCloudColumn = 'is_synced_with_cloud';
const createUserTable = '''CREATE TABLE IF NOT EXISTS "user" (
        "id"	INTEGER NOT NULL,
        "email"	TEXT NOT NULL UNIQUE,
        PRIMARY KEY("id" AUTOINCREMENT)
      );''';
const createQuestionsTable = '''CREATE TABLE IF NOT EXISTS "questions" (
        "id"	INTEGER NOT NULL,
        "user_id"	INTEGER NOT NULL,
        "text"	TEXT,
        "is_synced_with_cloud"	INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY("user_id") REFERENCES "user"("id"),
        PRIMARY KEY("id" AUTOINCREMENT)
      );''';
