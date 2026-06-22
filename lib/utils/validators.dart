bool isValidDuration(String s) {
  final v = int.tryParse(s);
  return v != null && v > 0;
}

bool isValidRutubeUrl(String s) {
  final normalized = s.trim();
  final pattern = RegExp(r'^https?:\/\/(www\.)?rutube\.ru\/video\/[A-Za-z0-9]+\/?');
  return pattern.hasMatch(normalized);
}
