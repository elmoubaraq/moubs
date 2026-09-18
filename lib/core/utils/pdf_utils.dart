/// Pure helpers shared by PDF services (no plugin dependencies).
library;

/// Parses a 1-indexed range ("3" or "2-5") into 0-based page indices,
/// clamping the end to [pageCount]. Returns null if malformed or the
/// start is out of range.
List<int>? parsePageRange(String range, int pageCount) {
  final parts = range.split('-').map((s) => int.tryParse(s.trim())).toList();
  if (parts.isEmpty || parts.length > 2 || parts.contains(null)) return null;
  final start = parts.first!;
  final end = parts.length == 2 ? parts[1]! : start;
  if (start < 1 || start > pageCount || end < start) return null;
  final clampedEnd = end > pageCount ? pageCount : end;
  return [for (var p = start; p <= clampedEnd; p++) p - 1];
}

/// Strips a trailing ".pdf" and characters invalid in file names.
String sanitizeFileName(String name) {
  final cleaned = name
      .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '')
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
      .trim();
  return cleaned.isEmpty ? 'document' : cleaned;
}
