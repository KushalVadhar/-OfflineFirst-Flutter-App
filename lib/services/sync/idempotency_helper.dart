import 'package:uuid/uuid.dart';

class IdempotencyHelper {
  static String generateKey() {
    return const Uuid().v4();
  }

  static String formatActionKey(String actionType, String entityId) {
    return '${actionType}_$entityId';
  }
}
