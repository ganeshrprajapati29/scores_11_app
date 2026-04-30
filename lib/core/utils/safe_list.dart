/// Safe list access extension to prevent "String is not subtype of int" errors
extension SafeListAccess<T> on List<T> {
  /// Safe access with string index (converts to int safely)
  T? safeGet(String? indexStr) {
    if (indexStr == null) return null;
    final index = int.tryParse(indexStr);
    if (index == null || index < 0 || index >= length) return null;
    return this[index];
  }
  
  /// Safe access with dynamic index (handles both int/string)
  T? safeAt(dynamic index) {
    if (index is String) return safeGet(index);
    if (index is int && index >= 0 && index < length) return this[index];
    return null;
  }
  
  /// Safe element at index or default value
  T safeElementAt(int index, T defaultValue) {
    if (index >= 0 && index < length) return this[index];
    return defaultValue;
  }
}

