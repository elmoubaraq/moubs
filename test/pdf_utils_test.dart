import 'package:evergreen/core/utils/pdf_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePageRange', () {
    test('single page is converted to 0-based', () {
      expect(parsePageRange('3', 10), [2]);
    });

    test('range is inclusive', () {
      expect(parsePageRange('2-4', 10), [1, 2, 3]);
    });

    test('tolerates whitespace', () {
      expect(parsePageRange(' 1 - 2 ', 10), [0, 1]);
    });

    test('end past the last page is clamped', () {
      expect(parsePageRange('4-99', 5), [3, 4]);
    });

    test('start past the last page is rejected', () {
      expect(parsePageRange('6-8', 5), isNull);
    });

    test('malformed input is rejected', () {
      expect(parsePageRange('', 5), isNull);
      expect(parsePageRange('a-b', 5), isNull);
      expect(parsePageRange('1-2-3', 5), isNull);
      expect(parsePageRange('0', 5), isNull);
      expect(parsePageRange('4-2', 5), isNull);
    });
  });

  group('sanitizeFileName', () {
    test('strips a trailing .pdf case-insensitively', () {
      expect(sanitizeFileName('report.PDF'), 'report');
    });

    test('replaces path separators and reserved characters', () {
      expect(sanitizeFileName(r'a/b\c:d*e?f"g<h>i|j'), 'a_b_c_d_e_f_g_h_i_j');
    });

    test('falls back when nothing is left', () {
      expect(sanitizeFileName('  '), 'document');
      expect(sanitizeFileName('.pdf'), 'document');
    });

    test('keeps ordinary names intact', () {
      expect(sanitizeFileName('Invoice 2026 (final)'), 'Invoice 2026 (final)');
    });
  });
}
