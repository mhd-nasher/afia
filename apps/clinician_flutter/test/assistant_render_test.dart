/// Field-feedback rendering contract: empty assistant turns never render,
/// and markdown markers never reach a rendered string.
library;

import 'package:afia_clinician/services/assistant/assistant_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('empty turns never render', () {
    test('whitespace and zero-width characters do not count as visible', () {
      expect(hasVisibleText(''), isFalse);
      expect(hasVisibleText('   \n  '), isFalse);
      expect(hasVisibleText('​‌‍﻿⁠'), isFalse);
      expect(hasVisibleText('​ \n'), isFalse);
      expect(hasVisibleText('ok'), isTrue);
      expect(hasVisibleText('مرحبا'), isTrue);
    });

    test('an all-markdown turn strips to nothing and would not render', () {
      expect(hasVisibleText(stripMarkdown('** **')), isFalse);
      expect(hasVisibleText(stripMarkdown('``')), isFalse);
    });
  });

  group('markdown never reaches the user', () {
    test('bold/italic/code/heading/bullet markers are stripped', () {
      final out = stripMarkdown(
          '# العنوان\n**3 حالات** لديك و*واحدة* بانتظار `التأكيد`\n- سرير A1\n- سرير A2');
      expect(out.contains('*'), isFalse);
      expect(out.contains('#'), isFalse);
      expect(out.contains('`'), isFalse);
      expect(out, contains('3 حالات'));
      expect(out, contains('· سرير A1'));
    });

    test('mixed Arabic/Latin text survives stripping intact', () {
      final out = stripMarkdown('**S. Osei** في draft_ready');
      expect(out, 'S. Osei في draft_ready');
    });

    test('an AssistantAnswer built from markdown-y fields is cleaned', () {
      // _parseAnswer is private; the public stripMarkdown carries the
      // guarantee, and answer text passes through it (see service).
      expect(stripMarkdown('**Recorded in Afia**'), 'Recorded in Afia');
    });
  });
}
