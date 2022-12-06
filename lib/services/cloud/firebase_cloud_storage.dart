import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yks_helper/services/cloud/cloud_question.dart';
import 'package:yks_helper/services/cloud/cloud_storage_constants.dart';
import 'package:yks_helper/services/cloud/cloud_storage_exceptions.dart';

class FirebaseCloudStorage {
  final questions = FirebaseFirestore.instance.collection('questions');

  Future<void> updateQuestions({
    required String documentId,
    required String text,
  }) async {
    try {
      await questions.doc(documentId).update({textFieldName: text});
    } catch (e) {
      throw CouldNotUpdateQuestionException();
    }
  }

  Future<void> deleteQuestion({required String documentId}) async {
    try {
      await questions.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeleteQuestionException();
    }
  }

  Stream<Iterable<CloudQuestion>> allQuestions({required String ownerUserId}) =>
      questions.snapshots().map((event) => event.docs
          .map((doc) => CloudQuestion.fromSnapshot(doc))
          .where((question) => question.ownerUserId == ownerUserId));

  Future<Iterable<CloudQuestion>> getQuestions(
      {required String ownerUserId}) async {
    try {
      return await questions
          .where(
            ownerUserIdFieldName,
            isEqualTo: ownerUserId,
          )
          .get()
          .then((value) =>
              value.docs.map((doc) => CloudQuestion.fromSnapshot(doc)));
    } catch (e) {
      throw CouldNotGetAllQuestionException();
    }
  }

  Future<CloudQuestion> createNewQuestion({required String ownerUserId}) async {
    final document = await questions.add({
      ownerUserIdFieldName: ownerUserId,
      textFieldName: '',
    });

    final fetchetNote = await document.get();
    return CloudQuestion(
      documentId: fetchetNote.id,
      ownerUserId: ownerUserId,
      text: '',
    );
  }

  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstance();
  FirebaseCloudStorage._sharedInstance();
  factory FirebaseCloudStorage() => _shared;
}
