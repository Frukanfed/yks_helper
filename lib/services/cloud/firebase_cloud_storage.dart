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
          .then((value) => value.docs.map((doc) {
                return CloudQuestion(
                  documentId: doc.id,
                  ownerUserId: doc.data()[ownerUserIdFieldName] as String,
                  text: doc.data()[textFieldName] as String,
                );
              }));
    } catch (e) {
      throw CouldNotGetAllQuestionException();
    }
  }

  void createNewQuestion({required String ownerUserId}) async {
    await questions.add({
      ownerUserIdFieldName: ownerUserId,
      textFieldName: '',
    });
  }

  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstance();
  FirebaseCloudStorage._sharedInstance();
  factory FirebaseCloudStorage() => _shared;
}
