class CloudStorageException implements Exception {
  const CloudStorageException();
}

class CouldNotCreateQuestionException implements CloudStorageException {}

class CouldNotGetAllQuestionException implements CloudStorageException {}

class CouldNotUpdateQuestionException implements CloudStorageException {}

class CouldNotDeleteQuestionException implements CloudStorageException {}
