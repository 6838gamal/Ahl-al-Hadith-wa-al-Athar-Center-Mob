extension StringExtensions on String {
  bool get isValidEmail => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  bool get isValidPhone => RegExp(r'^[0-9]{10,15}$').hasMatch(replaceAll(RegExp(r'[\s\-\+]'), ''));
  bool get isNotNullOrEmpty => isNotEmpty;
  String get capitalizeFirst => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  String get initials {
    final parts = trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return isNotEmpty ? this[0] : '?';
  }
  String truncate(int maxLength) => length > maxLength ? '${substring(0, maxLength)}...' : this;
}

extension NullableStringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  String get orEmpty => this ?? '';
}
