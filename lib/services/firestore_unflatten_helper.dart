// lib/services/firestore_unflatten_helper.dart
import 'package:flutter/foundation.dart';

class FirestoreUnflattenHelper {
  /// Converts a flat Firestore document with dotted keys into a nested map
  /// Example:
  /// Input:  {"byDate.2026-02-01.total": 5, "overall.present": 10}
  /// Output: {"byDate": {"2026-02-01": {"total": 5}}, "overall": {"present": 10}}
  static Map<String, dynamic> unflatten(Map<String, dynamic> flatMap) {
    final Map<String, dynamic> result = {};

    flatMap.forEach((key, value) {
      _setNestedValue(result, key, value);
    });

    return result;
  }

  static void _setNestedValue(Map<String, dynamic> map, String path, dynamic value) {
    final keys = path.split('.');
    Map<String, dynamic> current = map;

    for (int i = 0; i < keys.length - 1; i++) {
      final key = keys[i];
      if (!current.containsKey(key)) {
        current[key] = <String, dynamic>{};
      }
      if (current[key] is! Map<String, dynamic>) {
        // If it's not a map, convert it
        current[key] = <String, dynamic>{};
      }
      current = current[key] as Map<String, dynamic>;
    }

    current[keys.last] = value;
  }

  /// Debug: Print the structure of a map
  static void debugPrintStructure(Map<String, dynamic> map, [String prefix = '']) {
    map.forEach((key, value) {
      if (value is Map) {
        debugPrint('$prefix$key: (Map with ${value.length} keys)');
        debugPrintStructure(value as Map<String, dynamic>, '$prefix  ');
      } else if (value is List) {
        debugPrint('$prefix$key: (List with ${value.length} items)');
      } else {
        debugPrint('$prefix$key: $value');
      }
    });
  }
}