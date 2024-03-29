import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'cloud_storage_constants.dart';

@immutable
class CloudQuestion {
  final String documentId;
  final String ownerUserId;
  final String text;

  const CloudQuestion({
    required this.documentId,
    required this.ownerUserId,
    required this.text,
  });

  CloudQuestion.fromSnapshot(
      QueryDocumentSnapshot<Map<String, dynamic>> snapshot)
      : documentId = snapshot.id,
        ownerUserId = snapshot.data()[ownerUserIdFieldName],
        text = snapshot.data()[textFieldName] as String;
}
