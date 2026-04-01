extension StringExtension on String {
  String toSummary([int maxLength = 50]) {
    if (length > maxLength) {
      return '${substring(0, maxLength)}...';
    }
    return this;
  }
}
