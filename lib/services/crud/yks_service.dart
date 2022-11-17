import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'crud_exceptions.dart';

//database operations
class HelperService {
  Database? _db;

  Future<DataBaseQuestions> updateQuestion({
    required DataBaseQuestions question,
    required String text,
  }) async {
    final db = _getDataBaseOrThrow();

    await getQuestion(id: question.id);
    final updatesCount = await db.update(questionsTable, {
      textColumn: text,
      isSyncedWithCloudColumn: 0,
    });

    if (updatesCount == 0) throw CouldNotUpdateNoteException();
    return await getQuestion(id: question.id);
  }

  Future<Iterable<DataBaseQuestions>> getSameTypeQuestions(
      {required String type}) async {
    final db = _getDataBaseOrThrow();
    final questions = await db.query(
      questionsTable,
      where: 'type = ?',
      whereArgs: [type],
    );

    return questions
        .map((questionsRow) => DataBaseQuestions.fromRow(questionsRow));
  }

  Future<DataBaseQuestions> getQuestion({required int id}) async {
    final db = _getDataBaseOrThrow();
    final question = await db.query(
      questionsTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (question.isEmpty) throw CouldNotDeleteQuestionException();
    return DataBaseQuestions.fromRow(question.first);
  }

  Future<int> deleteAllQuestions() async {
    final db = _getDataBaseOrThrow();
    return await db.delete(questionsTable);
  }

  Future<void> deleteQuestion({required int id}) async {
    final db = _getDataBaseOrThrow();
    final deletedCount = await db.delete(
      questionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedCount == 0) throw CouldNotDeleteQuestionException();
  }

  Future<DataBaseQuestions> createQuestion(
      {required DataBaseUser owner}) async {
    final db = _getDataBaseOrThrow();

    //make sure owner exists in the db
    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) throw CouldNotFindUserException();

    const text = '';
    const type = '';
    final questionId = await db.insert(questionsTable,
        {textColumn: text, typeColumn: type, isSyncedWithCloudColumn: 1});

    final question = DataBaseQuestions(
      id: questionId,
      type: type,
      text: text,
      isSyncedWithCloud: true,
    );
    return question;
  }

  Future<DataBaseUser> getUser({required String email}) async {
    final db = _getDataBaseOrThrow();

    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (results.isEmpty) throw CouldNotFindUserException();

    return DataBaseUser.fromRow(results.first);
  }

  Future<DataBaseUser> createUser({required String email}) async {
    final db = _getDataBaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) throw UserAlreadyExistsException();

    final userId =
        await db.insert(userTable, {emailColumn: email.toLowerCase()});

    return DataBaseUser(id: userId, email: email);
  }

  Future<void> deleteUser({required String email}) async {
    final db = _getDataBaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCount != 1) throw CouldNotDeleteUserException();
  }

  Database _getDataBaseOrThrow() {
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

  Future<void> open() async {
    if (_db != null) throw DatabaseAlreadyOpenedException();
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;
      //create the user table
      await db.execute(createUserTable);
      //create the questions table
      await db.execute(createQuestionsTable);
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectoryException();
    }
  }
}

//implementing user table
@immutable
class DataBaseUser {
  final int id;
  final String email;

  const DataBaseUser({
    required this.id,
    required this.email,
  });

  DataBaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() => 'Person, id = $id, email = $email';

  @override
  bool operator ==(covariant DataBaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

//implementing questions table
class DataBaseQuestions {
  final int id;
  final String type;
  final String text;
  final bool isSyncedWithCloud;

  const DataBaseQuestions({
    required this.id,
    required this.type,
    required this.text,
    required this.isSyncedWithCloud,
  });

  DataBaseQuestions.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        type = map[typeColumn] as String,
        text = map[textColumn] as String,
        isSyncedWithCloud =
            (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;

  @override
  String toString() =>
      'Questions, id = $id, type = $type, isSyncedWithCloud = $isSyncedWithCloud, text = $text';

  @override
  bool operator ==(covariant DataBaseQuestions other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

//constants
const dbName = 'helper.db';
const userTable = 'user';
const questionsTable = 'questions';
const idColumn = 'id';
const emailColumn = 'email';
const typeColumn = 'type';
const textColumn = 'text';
const isSyncedWithCloudColumn = 'is_synced_with_cloud';
const createUserTable = ''' CREATE TABLE IF NOT EXISTS "user" (
        "id"	INTEGER NOT NULL,
        "email"	TEXT NOT NULL,
        PRIMARY KEY("id" AUTOINCREMENT)
      ); ''';
const createQuestionsTable = ''' CREATE TABLE IF NOT EXISTS "questions" (
        "id"	INTEGER NOT NULL,
        "branch"	TEXT NOT NULL,
        "is_synced_with_cloud"	INTEGER,
        "text"	TEXT,
        PRIMARY KEY("id" AUTOINCREMENT)
      ); ''';
